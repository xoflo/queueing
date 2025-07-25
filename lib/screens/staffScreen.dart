import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';
import 'package:queueing/models/media.dart';
import 'package:queueing/models/services/service.dart';
import 'package:queueing/models/station.dart';
import 'package:queueing/models/ticket.dart';
import 'package:web_socket_channel/io.dart';
import '../models/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key, required this.user});

  final User user;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  late Timer update;
  int stationChanges = 0;

  @override
  void initState() {
    initUpdate();
    super.initState();
  }

  initUpdate() {
    update = Timer.periodic(Duration(seconds: 2), (value) async {
      final List<dynamic> result = await getStationSQL();
      List<dynamic> pingSorted =
          result.where((e) => e['sessionPing'] != "").toList();

      User user = await thisUser();

      final DateTime newTime = DateTime.now();
      await user.update({'loggedIn': DateTime.now().toString()});

      if (pingSorted.length != stationChanges) {
        stationChanges = pingSorted.length;
        setState(() {});
      }

      for (int i = 0; i < pingSorted.length; i++) {
        final station = Station.fromJson(pingSorted[i]);
        final pingDate = DateTime.parse(station.sessionPing!);

        if (newTime.difference(pingDate).inSeconds > 3) {
          await station
              .update({'inSession': 0, 'userInSession': "", 'sessionPing': ""});

          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    update.cancel();
    super.dispose();
  }

  List<String> servicesSet = [];
  final dialogKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body:
            MediaQuery.of(context).size.width < 350 ||
                    MediaQuery.of(context).size.height < 550
                ? Container(
                    child: Center(
                        child: Text(
                      "Expand Screen Size to Display",
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center,
                    )),
                  )
                : Stack(
                    children: [
                      imageBackground(context),
                      logoBackground(context, 350),
                      FutureBuilder(
                        future: thisUser(),
                        builder: (BuildContext context,
                            AsyncSnapshot<User> snapshot) {
                          return snapshot.connectionState ==
                                  ConnectionState.done
                              ? Builder(builder: (context) {
                                  return Container(
                                    padding: EdgeInsets.all(20),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Column(
                                        children: [
                                          Align(
                                              alignment: Alignment.centerLeft,
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      icon: Icon(
                                                          Icons.chevron_left)),
                                                  Text(
                                                      "Welcome, ${widget.user.username}",
                                                      style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                  Spacer(),
                                                  /*

                                    IconButton(onPressed: () {
                                      showDialog(context: context, builder: (_) => StatefulBuilder(
                                        key: dialogKey,
                                        builder: (BuildContext context, setStateDialog) {
                                          return AlertDialog(
                                            title: Text("Select Services (3 Max)"),
                                            content: Container(
                                              height: 400,
                                              width: 400,
                                              child: FutureBuilder(
                                                future: thisUser(),
                                                builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
                                                  return StatefulBuilder(
                                                    builder: (BuildContext context, void Function(void Function()) setStateList) {
                                                      return snapshot.connectionState == ConnectionState.done ? ListView.builder(
                                                          itemCount: snapshot.data!.serviceType!.length,
                                                          itemBuilder: (context, i) {
                                                            return CheckboxListTile(
                                                                title: Text(snapshot.data!.serviceType![i]),
                                                                value: servicesSet.contains(snapshot.data!.serviceType![i].toString()), onChanged: (value) {
                                                              if (value == true) {
                                                                if (servicesSet.length == 3) {
                                                                  servicesSet.removeAt(0);
                                                                }
                                                                servicesSet.add(snapshot.data!.serviceType![i].toString());
                                                                setStateList((){});
                                                              } else {
                                                                servicesSet.remove(snapshot.data!.serviceType![i].toString());
                                                                setStateList((){});
                                                              }

                                                              print(servicesSet);
                                                            });
                                                          }) : Center(
                                                        child: Container(
                                                          height: 50,
                                                          width: 50,
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () {

                                                try {
                                                  snapshot.data!.update({
                                                    "servicesSet": servicesSet.toString()
                                                  });

                                                  Navigator.pop(context);
                                                  setState((){});

                                                } catch(e) {
                                                  print(e);
                                                }

                                              }, child: Text("Confirm"))
                                            ],
                                          );
                                        },
                                      )
                                      );
                                    }, icon: Icon(Icons.settings))
                                     */
                                                ],
                                              )),
                                          Divider(),
                                          SizedBox(height: 10),
                                          FutureBuilder(
                                            future: getStationSQL(),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<List<dynamic>>
                                                    snapshot) {
                                              return snapshot.connectionState ==
                                                      ConnectionState.done
                                                  ? Container(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height -
                                                              120,
                                                      child: GridView.builder(
                                                          gridDelegate:
                                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                                  childAspectRatio:
                                                                      3 / 1.2,
                                                                  crossAxisCount: MediaQuery.of(context)
                                                                              .size
                                                                              .width <
                                                                          800
                                                                      ? MediaQuery.of(context).size.width <
                                                                              700
                                                                          ? 2
                                                                          : 3
                                                                      : 5),
                                                          itemCount: snapshot
                                                              .data!.length,
                                                          itemBuilder:
                                                              (context, i) {
                                                            final Station
                                                                station =
                                                                Station.fromJson(
                                                                    snapshot
                                                                        .data![i]);
                                                            return InkWell(
                                                              child: Card(
                                                                  child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                      "${station.stationName}${station.stationNumber == 0 ? "" : " ${station.stationNumber}"}",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              20,
                                                                          fontWeight:
                                                                              FontWeight.w700)),
                                                                  station.inSession ==
                                                                          0
                                                                      ? Text(
                                                                          "Available",
                                                                          style: TextStyle(
                                                                              color: Colors
                                                                                  .green))
                                                                      : Text(
                                                                          "${station.userInSession}",
                                                                          style:
                                                                              TextStyle(color: Colors.redAccent))
                                                                ],
                                                              )),
                                                              onTap: () async {
                                                                final timestamp =
                                                                    DateTime.now()
                                                                        .toString();

                                                                if (station
                                                                        .inSession ==
                                                                    1) {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(SnackBar(
                                                                          content:
                                                                              Text("Station is currently in session.")));
                                                                } else {
                                                                  await station
                                                                      .update({
                                                                    "inSession":
                                                                        1,
                                                                    "userInSession":
                                                                        widget
                                                                            .user
                                                                            .username,
                                                                    "sessionPing":
                                                                        timestamp
                                                                  });

                                                                  final User
                                                                      user =
                                                                      await thisUser();

                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (_) => StaffSession(
                                                                              user: user,
                                                                              station: station)));
                                                                }
                                                              },
                                                            );
                                                          }),
                                                    )
                                                  : Container(
                                                      height: 300,
                                                      child: Center(
                                                        child: Container(
                                                          height: 50,
                                                          width: 50,
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      ),
                                                    );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                })
                              : Center(
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                        },
                      ),
                    ],
                  ),
      ),
    );
  }

  thisUser() async {
    try {
      final List<User> users = await getUserSQL();
      final thisUser =
          users.where((e) => e.username == widget.user.username).toList()[0];

      return thisUser;
    } catch (e) {
      print(e);
    }
  }

  getUserSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);
      List<User> users = [];

      for (int i = 0; i < response.length; i++) {
        users.add(User.fromJson(response[i]));
      }

      return users;
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  getStationSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_station.php');
      final result = await http.get(uri);
      final response = jsonDecode(result.body);

      return response;
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }
}

class StaffSession extends StatefulWidget {
  const StaffSession({super.key, required this.user, required this.station});

  final Station station;
  final User user;

  @override
  State<StaffSession> createState() => _StaffSessionState();
}

class _StaffSessionState extends State<StaffSession> {
  late Timer pingTimer;
  Timer? ringTimer;
  Timer? update;

  int ticketLength = 0;

  String callBy = "Time Order";
  bool alternate = false;

  AudioPlayer player = AudioPlayer();
  bool dialogOn = false;

  int? inactiveLength;
  int? inactiveOn;

  ValueNotifier<List<Ticket>> ticketStream = ValueNotifier([]);
  ValueNotifier<Ticket?> servingStream = ValueNotifier(null);


  bool swap = false;

  late WebSocketChannel channel;
  Timer? reconnectTimer;
  bool isConnected = false;

  int stationChanges = 0;

  getUserSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);
      List<User> users = [];

      for (int i = 0; i < response.length; i++) {
        users.add(User.fromJson(response[i]));
      }

      return users;
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  thisUser() async {
    try {
      final List<User> users = await getUserSQL();
      final thisUser =
      users.where((e) => e.username == widget.user.username).toList()[0];

      return thisUser;
    } catch (e) {
      print(e);
    }
  }

  initUpdate() {
    update = Timer.periodic(Duration(seconds: 2), (value) async {
      final List<dynamic> result = await getStationSQL();
      List<dynamic> pingSorted =
      result.where((e) => e['sessionPing'] != "").toList();

      User user = await thisUser();

      final DateTime newTime = DateTime.now();
      await user.update({'loggedIn': DateTime.now().toString()});

      if (pingSorted.length != stationChanges) {
        stationChanges = pingSorted.length;
      }

      for (int i = 0; i < pingSorted.length; i++) {
        final station = Station.fromJson(pingSorted[i]);
        final pingDate = DateTime.parse(station.sessionPing!);

        if (newTime.difference(pingDate).inSeconds > 3) {
          await station
              .update({'inSession': 0, 'userInSession': "", 'sessionPing': "", 'ticketServing' : ""});
        }
      }

    });

    update?.cancel();
  }

  updateTicketStream([int? i]) async {
    List<Ticket> getTickets = await getTicketSQL('filtered');
    if (i == 1) {
      swap = !swap;
    }
    ticketStream.value = getTickets;
    ticketLength = getTickets.length;
    return getTickets;
  }

  @override
  void initState() {
    super.initState();

    if (ringTimer != null) {
      ringTimer!.cancel();
      ringTimer = null;
    }

    listenNode();
    initPing();
    initUpdate();
  }



  listenNode() {
    final url = 'ws://${site.toString().split(":")[0]}:3000';
    if (kIsWeb) {
      channel = WebSocketChannel.connect(Uri.parse(url));
    } else {
      channel = IOWebSocketChannel.connect(url);
    }

    channel.stream.listen((message) async {
      isConnected = true;
      if (message.toString().trim() == 'sink') {
        print('Received sink. Updating...');
        await updateTicketStream(1);
        await updateServingTicketStream();
      } else {
        print('Ignored message: $message');
      }
    },
      onDone: () {
        isConnected = false;
        print("❌ Disconnected");
        tryReconnect();
      },
      onError: (err) {
        isConnected = false;
        print("⚠️ Error: $err");
        tryReconnect();
      },
      cancelOnError: true,
    );

    channel.sink.add('sink');

  }

  void tryReconnect() {
    if (reconnectTimer?.isActive ?? false) return;
    reconnectTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (!isConnected) {
        print("🔁 Reconnecting...");
        listenNode();
      } else {
        print("✅ Reconnected");
        reconnectTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reconnected to server.")));
      }
    });
  }


  @override
  void dispose() {
    pingTimer.cancel();
    if (ringTimer != null) {
      ringTimer!.cancel();
      ringTimer = null;
    }
    super.dispose();
  }

  initPing() {
    pingTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      widget.station.update({
        "sessionPing": DateTime.now().toString(),
        "inSession": 1,
        "userInSession": widget.user.username,
      });

      final timeControl = await getInactiveTime();
      inactiveLength = int.parse(timeControl['other']);
      inactiveOn = int.parse(timeControl['value']);


      /*

      final retrievedTickets = await getTicketSQL('filtered');

      if (ticketLength != retrievedTickets.length) {
        await updateTicketStream();
        await updateServingTicketStream();
      }
       */

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          MediaQuery.of(context).size.width < 350 ||
                  MediaQuery.of(context).size.height < 550
              ? Container(
                  child: Center(
                      child: Text("Expand Screen Size to Display",
                          style: TextStyle(fontSize: 30),
                          textAlign: TextAlign.center)),
                )
              : Listener(
                  onPointerMove: (value) {
                    resetRinger();
                  },
                  onPointerDown: (value) {
                    resetRinger();
                  },
                  child: Stack(
                    children: [
                      imageBackground(context),
                      StatefulBuilder(
                        builder: (BuildContext context, setStateSession) {
                          return Container(
                            padding: EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                children: [
                                  Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                          onPressed: () {
                                            if (ringTimer != null) {
                                              ringTimer!.cancel();
                                              ringTimer = null;
                                            }
                                            Navigator.pop(context);
                                          },
                                          icon: Icon(Icons.chevron_left))),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text("User In-Session: ",
                                          style: TextStyle(fontSize: 20)),
                                      Text("${widget.user.username}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20))
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text("Station: ",
                                          style: TextStyle(fontSize: 20)),
                                      Text(
                                          "${widget.station.stationName}${widget.station.stationNumber == 0 ? "" : " ${widget.station.stationNumber}"}",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20))
                                    ],
                                  ),
                                  SizedBox(height: 30),
                                  FutureBuilder(
                                    future: updateServingTicketStream(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<List<Ticket>>
                                            snapshotServing) {
                                      return snapshotServing
                                                  .connectionState ==
                                              ConnectionState.done
                                          ? Builder(
                                          builder: (context) {
                                            resetRinger();
                                            return ValueListenableBuilder<Ticket?>(
                                              valueListenable: servingStream,
                                              builder: (BuildContext context, Ticket? value, Widget? child) {
                                                return servingStream.value != null ? Card(
                                                  clipBehavior:
                                                  Clip.antiAlias,
                                                  child: Padding(
                                                    padding:
                                                    const EdgeInsets
                                                        .all(15.0),
                                                    child: Container(
                                                      height: 130,
                                                      width: 250,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                        children: [
                                                          Text(
                                                              overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                              "${servingStream.value!.serviceType}",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                  15,
                                                                  fontWeight: FontWeight
                                                                      .w700),
                                                              textAlign:
                                                              TextAlign
                                                                  .center),
                                                          Text(
                                                              servingStream.value!
                                                                  .codeAndNumber!,
                                                              style: TextStyle(
                                                                  fontSize:
                                                                  45)),
                                                          Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                            spacing: 5,
                                                            children: [
                                                              Text(
                                                                  "Priority:",
                                                                  style:
                                                                  TextStyle(fontSize: 15)),
                                                              Text(
                                                                  servingStream.value!
                                                                      .priorityType!,
                                                                  style:
                                                                  TextStyle(fontSize: 15)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ) : Card(
                                                  child: Builder(
                                                      builder: (context) {
                                                        resetRinger();
                                                        return Container(
                                                          height: 130,
                                                          width: 220,
                                                          child: Padding(
                                                            padding:
                                                            const EdgeInsets
                                                                .all(
                                                                20.0),
                                                            child: Align(
                                                              alignment:
                                                              Alignment
                                                                  .center,
                                                              child: Text(
                                                                  "No ticket being served at the moment.",
                                                                  textAlign:
                                                                  TextAlign
                                                                      .center,
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .grey,
                                                                      fontSize:
                                                                      15)),
                                                            ),
                                                          ),
                                                        );
                                                      }),
                                                );
                                              },
                                            );
                                          })
                                          : Container(
                                              height: 300,
                                              child: Center(
                                                child: Container(
                                                  height: 50,
                                                  width: 50,
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                            );
                                    },
                                  ),
                                  SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        child: Card(
                                          child: InkWell(
                                            splashColor:
                                                Theme.of(context).splashColor,
                                            highlightColor: Theme.of(context)
                                                .highlightColor,
                                            child: Container(
                                              height: 120,
                                              width: 95,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.double_arrow),
                                                  SizedBox(width: 5),
                                                  Text("Call Next",
                                                      textAlign:
                                                          TextAlign.center),
                                                ],
                                              ),
                                            ),
                                            onTap: () async {
                                              final timestamp = DateTime.now().toString();
                                                try {
                                                  if (servingStream.value != null) {
                                                    try {
                                                      await servingStream.value!.update({
                                                        "status": "Done",
                                                        "timeDone": timestamp,
                                                        "log": "${servingStream.value!.log}, $timestamp: Ticket Session Finished"});

                                                      channel.sink.add("sink");

                                                      if (ticketStream.value.isNotEmpty) {
                                                        if (ticketStream.value[0]
                                                            .serviceType! ==
                                                            callBy ||
                                                            callBy ==
                                                                'Time Order') {
                                                          await ticketStream.value[0].update({
                                                            "userAssigned": widget.user.username,
                                                            "status": "Serving",
                                                            "stationName": widget.station.stationName,
                                                            "stationNumber": widget.station.stationNumber,
                                                            "log":"${ticketStream.value[0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                                            "timeTaken": timestamp
                                                          });

                                                          await widget.station.update({'ticketServing': ticketStream.value[0].codeAndNumber!});

                                                          channel.sink.add("sink");

                                                        }
                                                      } else {

                                                        await widget.station.update({'ticketServing': ""});
                                                        channel.sink.add("sink");
                                                        resetRinger();
                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                            content:
                                                            Text("Ticket complete.")));
                                                      }

                                                    } catch(e) {
                                                      print(e);
                                                    }
                                                  } else {
                                                    if (ticketStream.value.isNotEmpty) {
                                                      if (ticketStream.value[0]
                                                          .serviceType! ==
                                                          callBy ||
                                                          callBy ==
                                                              'Time Order') {
                                                        await ticketStream.value[0].update({
                                                          "userAssigned": widget.user.username,
                                                          "status": "Serving",
                                                          "stationName": widget.station.stationName,
                                                          "stationNumber": widget.station.stationNumber,
                                                          "log":"${ticketStream.value[0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                                          "timeTaken": timestamp
                                                        });

                                                        await widget.station.update({'ticketServing': ticketStream.value[0].codeAndNumber!});

                                                        channel.sink.add("sink");

                                                      }
                                                    }  else {

                                                      ScaffoldMessenger.of(
                                                          context)
                                                          .showSnackBar(SnackBar(
                                                          content: Text(
                                                              "No pending tickets to serve at the moment.")));
                                                  }
                                              }

                                                } catch(e) {
                                                  print(e);
                                                  print("Call Next no Dialog");
                                                }


                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      ClipRRect(
                                        child: Card(
                                          child: InkWell(
                                            child: Container(
                                              height: 120,
                                              width: 95,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.move_down_sharp),
                                                  SizedBox(height: 5),
                                                  Text("Transfer"),
                                                ],
                                              ),
                                            ),
                                            onTap: () async {
                                              final timestamp =
                                                  DateTime.now().toString();

                                              if (servingStream.value != null) {
                                                await showDialog(
                                                    context: context,
                                                    builder:
                                                        (_) => AlertDialog(
                                                              title: Text(
                                                                  "Select Station to Transfer"),
                                                              content:
                                                                  Container(
                                                                height: 400,
                                                                width: 400,
                                                                child:
                                                                    FutureBuilder(
                                                                        future:
                                                                            getServiceSQL(),
                                                                        builder:
                                                                            (context, AsyncSnapshot<List<dynamic>> snapshot) {
                                                                          return snapshot.connectionState == ConnectionState.done
                                                                              ? snapshot.data!.isNotEmpty
                                                                                  ? ListView.builder(
                                                                                      itemCount: snapshot.data!.length,
                                                                                      itemBuilder: (context, i) {
                                                                                        final service = Service.fromJson(snapshot.data![i]);

                                                                                        return ListTile(
                                                                                          title: Text(service.serviceType!),
                                                                                          onTap: () async {
                                                                                            final timestamp = DateTime.now().toString();
                                                                                            await servingStream.value!.update({
                                                                                              'log': "${servingStream.value!.log}, $timestamp: ticket transferred to ${service.serviceType}",
                                                                                              'status': "Pending",
                                                                                              'userAssigned': "",
                                                                                              'stationName': "",
                                                                                              'stationNumber': "",
                                                                                              'timeDone' : "",
                                                                                              'serviceType': "${service.serviceType}",
                                                                                              'callCheck': 0,
                                                                                              'blinker': 0
                                                                                            });

                                                                                            await widget.station.update({
                                                                                              'ticketServing': ""
                                                                                            });


                                                                                            if (ticketStream.value.isNotEmpty) {
                                                                                              if (ticketStream.value[0]
                                                                                                  .serviceType! ==
                                                                                                  callBy ||
                                                                                                  callBy ==
                                                                                                      'Time Order') {
                                                                                                await ticketStream.value[0].update({
                                                                                                  "userAssigned": widget.user.username,
                                                                                                  "status": "Serving",
                                                                                                  "stationName": widget.station.stationName,
                                                                                                  "stationNumber": widget.station.stationNumber,
                                                                                                  "log":"${ticketStream.value[0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                                                                                  "timeTaken": timestamp
                                                                                                });

                                                                                                await widget.station.update({'ticketServing': ticketStream.value[0].codeAndNumber!});


                                                                                                channel.sink.add("sink");

                                                                                                Navigator.pop(context, 1);
                                                                                                resetRinger();
                                                                                              }
                                                                                            } else {

                                                                                              channel.sink.add("sink");
                                                                                              Navigator.pop(context, 1);
                                                                                              resetRinger();
                                                                                            }
                                                                                          },
                                                                                        );
                                                                                      })
                                                                                  : Center(
                                                                                      child: Text("No Stations", style: TextStyle(color: Colors.grey)),
                                                                                    )
                                                                              : Container(
                                                                                  height: 300,
                                                                                  child: Center(
                                                                                    child: Container(
                                                                                      height: 50,
                                                                                      width: 50,
                                                                                      child: CircularProgressIndicator(),
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                        }),
                                                              )
                                                            ));


                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            "No ticket being served at the moment.")));
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Builder(builder: (context) {
                                        int callAgainCounter = 0;

                                        return ClipRRect(
                                          child: Card(
                                            child: InkWell(
                                              child: Container(
                                                height: 120,
                                                width: 95,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  children: [
                                                    Icon(Icons.volume_up),
                                                    SizedBox(width: 5),
                                                    Text("Call Again"),
                                                  ],
                                                ),
                                              ),
                                              onTap: () async {
                                                final timestamp =
                                                    DateTime.now().toString();

                                                if (servingStream.value != null) {
                                                  if (callAgainCounter < 3) {
                                                    callAgainCounter += 1;
                                                    await servingStream.value!.update({
                                                      'blinker': 0,
                                                      "callCheck": 0,
                                                      'log':
                                                          "${servingStream.value!.log!}, ${DateTime.now()}: ticket called again"
                                                    });
                                                  } else {
                                                    showDialog(
                                                        context: context,
                                                        builder:
                                                            (_) =>
                                                                AlertDialog(
                                                                  title: Text(
                                                                      "Release Ticket?"),
                                                                  content:
                                                                      Container(
                                                                    child: Text(
                                                                        "Ticket has been called a few times."),
                                                                    height:
                                                                        40,
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                        child: Text(
                                                                            "Release"),
                                                                        onPressed:
                                                                            () async {
                                                                          await servingStream.value!.update({
                                                                            "status": 'Released',
                                                                            'log': "${servingStream.value!.log!}, ${DateTime.now()}: Ticket Released",
                                                                            'userAssigned': "",
                                                                            'stationName': "",
                                                                            'stationNumber': "",
                                                                          });

                                                                          await widget.station.update({
                                                                            'ticketServing': ""
                                                                          });

                                                                          await updateServingTicketStream();
                                                                          servingStream.value = null;

                                                                          Navigator.pop(context);
                                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket Released")));
                                                                          resetRinger();
                                                                        })
                                                                  ],
                                                                ));
                                                  }
                                                } else {
                                                  ScaffoldMessenger.of(
                                                          context)
                                                      .showSnackBar(SnackBar(
                                                          content: Text(
                                                              "No ticket being served at the moment.")));
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      StatefulBuilder(
                                        builder: (context, setStateCheck) {
                                          return Checkbox(
                                              value: alternate,
                                              onChanged: (value) async {
                                                alternate = !alternate;
                                                await updateTicketStream();
                                                setStateCheck((){});
                                              });
                                        },
                                      ),
                                      SizedBox(width: 5),
                                      Text("Alternate Priority & Regular",
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14)),

                                      SizedBox(width: 5),
                                      IconButton(onPressed: () async {
                                        await updateTicketStream(1);
                                      }, icon: Icon(Icons.change_circle_outlined))
                                    ],
                                  ),
                                  ValueListenableBuilder<List<Ticket>>(
                                    valueListenable: ticketStream,
                                    builder: (BuildContext context, List<Ticket> value, Widget? child) {

                                      return StatefulBuilder(
                                        builder: (BuildContext context,
                                            void Function(void Function())
                                                setStateTickets) {
                                          return Column(
                                            children: [
                                              Builder(builder: (context) {
                                                List<String> callByList = [];
                                                if (widget.user.serviceType!
                                                    .isNotEmpty) {
                                                  callByList = stringToList(
                                                      widget.user.serviceType!
                                                          .toString());
                                                }

                                                callByList.insert(
                                                    0, "Time Order");

                                                return Container(
                                                  height: 40,
                                                  width: 300,
                                                  child: TextButton(
                                                      child: Text(
                                                          "Sort By: $callBy",
                                                          textAlign: TextAlign
                                                              .center,
                                                          style: TextStyle(
                                                              fontSize: 15)),
                                                      onPressed: () {
                                                        showDialog(
                                                            context: context,
                                                            builder: (_) =>
                                                                AlertDialog(
                                                                  title: Text(
                                                                      "Sort Ticket Calls"),
                                                                  content:
                                                                      Container(
                                                                    height:
                                                                        300,
                                                                    width:
                                                                        300,
                                                                    child: ListView.builder(
                                                                        itemCount: callByList.length,
                                                                        itemBuilder: (context, i) {
                                                                          return ListTile(
                                                                            title: Text(callByList[i]),
                                                                            onTap: () {
                                                                              callBy = callByList[i];
                                                                              updateTicketStream();
                                                                              Navigator.pop(context);
                                                                            },
                                                                          );
                                                                        }),
                                                                  ),
                                                                ));
                                                      }),
                                                );
                                              }),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text("Upcoming Tickets:",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .w700)),
                                                  Container(
                                                    height: 240,
                                                    child: ticketStream.value.isEmpty
                                                        ? Text(
                                                            "No pending tickets\nat the moment.",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .grey),
                                                            textAlign:
                                                                TextAlign
                                                                    .center)
                                                        : FutureBuilder(
                                                          future: updateTicketStream(),
                                                          builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshot) {
                                                            return ValueListenableBuilder(
                                                              valueListenable: ticketStream,
                                                              builder: (BuildContext context, List<Ticket> value, Widget? child) {
                                                                return ListView.builder(
                                                                    scrollDirection: Axis.vertical,
                                                                    itemCount: ticketStream.value.length,
                                                                    itemBuilder: (context, i) {
                                                                      return ListTile(
                                                                        dense: true,
                                                                        title: Text("${i + 1}. ${ticketStream.value[i].codeAndNumber}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                                                        subtitle: Text(ticketStream.value[i].priorityType == "Regular" ? "" : ticketStream.value[i].priorityType!.length > 20 ? "(${smartAbbreviate(ticketStream.value[i].priorityType!)})" : ticketStream.value[i].priorityType!, style: TextStyle(fontWeight: FontWeight.bold)),
                                                                        trailing: ticketStream.value[i].priorityType == "Regular" ? null : Icon(Icons.star, color: Colors.blueGrey),
                                                                      );
                                                                    });
                                                              },
                                                            );
                                                          },
                                                        ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
    );
  }

  String smartAbbreviate(String input) {
    if (input != null) {
      input = input.trim();
      if (input.isEmpty) return '';
      if (RegExp(r'^[A-Z]+$').hasMatch(input) && input.length <= 5) return input;
      var words = input.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.length > 1) {
        var letters = words.map((w) => w[0].toUpperCase()).join();
        return letters.length > 5 ? letters.substring(0, 5) : letters;
      } else {
        String word = words[0];
        if (word.length <= 5) return word.toUpperCase();
        String result = word[0].toUpperCase();
        for (var c in word.substring(1).split('')) {
          if (!'aeiouAEIOU'.contains(c)) {
            result += c.toUpperCase();
            if (result.length >= 4) break;
          }
        }
        return result;
      }
    } else {
      return "";
    }

  }

  getInactiveTime() async {
    final uri = Uri.parse('http://$site/queueing_api/api_controls.php');
    final result = await http.get(uri);
    final List<dynamic> response = jsonDecode(result.body);

    final control = response
        .where((e) => e['controlName'] == 'Staff Inactive Beep')
        .toList()[0];


    return control ?? 0;
  }

  Future<List<Ticket>> getTicketSQL([String? filtered]) async {
    final dateNow = DateTime.now();

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php?today=true');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);

      print(result.body);

      List<dynamic> sorted = [];

      for (int i = 0; i < widget.user.serviceType!.length; i++) {
        sorted.addAll(response
            .where((e) =>
                e['serviceType'].toString() ==
                    widget.user.serviceType![i].toString() &&
                e['status'] == "Pending")
            .toList());
      }

      List<Ticket> newTickets = [];

      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets = newTickets
          .where((e) =>
              e.timeCreatedAsDate!.isAfter(toDateTime(dateNow)) &&
              e.timeCreatedAsDate!.isBefore(toDateTime(dateNow.add(Duration(days: 1)))))
          .toList();


      if (callBy == "Time Order") {
        newTickets.sort((a, b) => DateTime.parse(a.timeCreated!)
            .compareTo(DateTime.parse(b.timeCreated!)));
      } else {
        newTickets.sort((a, b) {
          if ((a.serviceType! == callBy) && (b.serviceType! != callBy)) {
            return -1;
          }
          if ((a.serviceType! != callBy) && (b.serviceType! == callBy)) {
            return 1;
          }
          return 0;
        });
      }


      newTickets.sort((a, b) => b.priority!
          .compareTo(a.priority!));


      if (alternate == true) {
        newTickets = alternateTickets(newTickets);
      }


      return newTickets;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }


  List<Ticket> alternateTickets(List<Ticket> tickets) {
    List<Ticket> priorities = tickets.where((e) => e.priority! == 1).toList();
    List<Ticket> regulars = tickets.where((e) => e.priority! == 0).toList();

    final totalLength = priorities.length + regulars.length;
    List<Ticket> alternatedList = [];

    for (int i = 0; i < totalLength; i++) {
      if (swap == false) {
        if (priorities.isNotEmpty) {
          alternatedList.add(priorities.first);
          priorities.remove(priorities.first);
        }
        if (regulars.isNotEmpty) {
          alternatedList.add(regulars.first);
          regulars.remove(regulars.first);
        }
      } else {
        if (regulars.isNotEmpty) {
          alternatedList.add(regulars.first);
          regulars.remove(regulars.first);
        }
        if (priorities.isNotEmpty) {
          alternatedList.add(priorities.first);
          priorities.remove(priorities.first);
        }
      }
    }

    return alternatedList;
  }


  updateServingTicketStream() async {
    List<Ticket> servings = await getServingTicketSQL();
    if (servings.isEmpty) {
      servingStream.value = null;
      return servings;
    } else {
      servingStream.value = servings[0];
      return servings;
    }
  }

  getServingTicketSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);
      List<dynamic> sorted = [];

      final dateNow = DateTime.now();

      for (int i = 0; i < widget.user.serviceType!.length; i++) {
        sorted.addAll(response
            .where((e) =>
                e['serviceType'] == widget.user.serviceType![i] &&
                e['status'] == "Serving" &&
                e['userAssigned'] == widget.user.username)
            .toList());
      }

      List<Ticket> newTickets = [];
      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets = newTickets.where((e) => toDateTime(e.timeCreatedAsDate!) == toDateTime(dateNow)).toList();
      newTickets.sort((a, b) => DateTime.parse(b.timeTaken!).compareTo(DateTime.parse(a.timeTaken!)));

      return newTickets;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  getServiceSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_service.php');
      final result = await http.get(uri);
      final response = jsonDecode(result.body);
      response.sort((a, b) => int.parse(a['id'].toString())
          .compareTo(int.parse(b['id'].toString())));

      return response;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  Future<List<dynamic>> getStationSQL([String? stationNameNumber]) async {
    print("call $stationNameNumber");

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_station.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);

      List<dynamic> toReturn = [];

      if (stationNameNumber != null) {
        response
            .where((e) =>
                "${e['stationName']}${e['stationNumber']}".trim() ==
                stationNameNumber)
            .toList();
        toReturn = response;
      } else {
        toReturn = response;
      }

      return toReturn;
    } catch (e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  inactiveDialog() {
    dialogOn = true;
    _play();
    final ringerSound = Timer.periodic(Duration(seconds: 5), (callback) {
      _play();
    });

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => AlertDialog(
              content: GestureDetector(
                onTap: () {
                  ringerSound.cancel();
                  _stop();
                  resetRinger();
                  Navigator.pop(context);
                },
                child: Container(
                  height: 150,
                  width: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("INACTIVITY DETECTED",
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                      Text("Press to Dismiss",
                          style: TextStyle(fontSize: 15),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ));
  }

  resetRinger() {
    if (ringTimer != null) {
      dialogOn = false;
      ringTimer!.cancel();
      ringTimer = null;
      initRinger();
    } else {
      initRinger();
    }
  }

  initRinger() {
    if (ringTimer != null) {
      ringTimer!.cancel();
      ringTimer = null;
    }

    if (inactiveLength != null && inactiveOn == 1) {
      if (servingStream.value == null && ticketStream.value.isNotEmpty) {
        if (ringTimer == null) {
          ringTimer =
              Timer.periodic(Duration(seconds: inactiveLength ?? 120), (value) {
            if (dialogOn == false) {
              inactiveDialog();
            }
          });
        }
      } else {
        if (ringTimer != null) {
          ringTimer!.cancel();
          ringTimer = null;
        }
        print("serving or no pending");
      }
    }
  }

  _play() {
    player.play(AssetSource('ringer.mp3'));
  }

  _stop() {
    player.stop();
  }
}


/*

                                              if (servingStream.value != null) {
                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (_) => AlertDialog(
                                                              title: Text(
                                                                  "Confirm Done?"),
                                                              content: Container(
                                                                  child: Text(
                                                                      "'Done' to complete and 'Call Next' to serve next ticket."),
                                                                  height: 40),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed: () async {
                                                                      try {
                                                                        await servingStream.value!.update({
                                                                          "status": "Done",
                                                                          "timeDone": timestamp,
                                                                          "log": "${servingStream.value!.log}, $timestamp: Ticket Session Finished"});

                                                                        await widget.station.update({'ticketServing': ""});




                                                                        Navigator.pop(
                                                                            context);
                                                                        resetRinger();



                                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                            content:
                                                                            Text("Ticket complete.")));
                                                                      } catch(e) {
                                                                        print(e);
                                                                        print("Done in Dialog");
                                                                      }
                                                                    },
                                                                    child: Text(
                                                                        "Done")),
                                                                TextButton(
                                                                    onPressed:
                                                                        () async {

                                                                      try {

                                                                        final timestamp =
                                                                        DateTime.now().toString();

                                                                        await servingStream.value!.update({
                                                                          "status": "Done",
                                                                          "timeDone": timestamp,
                                                                          "log": "${servingStream.value!.log}, $timestamp: Ticket Session Finished"
                                                                        });

                                                                        if (ticketStream.value.isNotEmpty) {
                                                                          if (ticketStream.value[0].serviceType! == callBy || callBy == 'Time Order') {
                                                                            await ticketStream.value[0].update({
                                                                              "userAssigned": widget.user.username,
                                                                              "status": "Serving",
                                                                              "stationName": widget.station.stationName,
                                                                              "stationNumber": widget.station.stationNumber,
                                                                              "log": "${ticketStream.value[0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                                                              "timeTaken": timestamp,
                                                                            });


                                                                            await widget.station.update({'ticketServing': "${ticketStream.value[0].codeAndNumber}"});
                                                                            await updateServingTicketStream();
                                                                            await updateTicketStream(1);

                                                                            Navigator.pop(context);
                                                                          }
                                                                        } else {
                                                                          await widget
                                                                              .station
                                                                              .update({
                                                                            'ticketServing':
                                                                            ""
                                                                          });

                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(SnackBar(content: Text("No pending tickets to serve at the moment.")));
                                                                        }
                                                                      } catch(e) {
                                                                        print(e);
                                                                        print('Call Next in Dialog');
                                                                      }

                                                                    },
                                                                    child: Text(
                                                                        "Call Next"))
                                                              ],
                                                            ));
                                              } else {}
                                               */

