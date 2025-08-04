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
import 'package:queueing/node.dart';
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
  Timer? update;
  int stationChanges = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    update?.cancel();
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

  bool swap = false;

  int stationChanges = 0;

  ValueNotifier<Ticket?> servingStream = ValueNotifier(null);
  ValueNotifier<List<Ticket>> ticketStream = ValueNotifier([]);

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


  int callAgainCounter = 0;

  updateTicketStream([int? i, dynamic data]) {
    List<Ticket> retrievedTickets = getTicket('filtered', data);
    ticketStream.value = [];
    ticketStream.value = retrievedTickets;
    if (i == 1) {
      swap = !swap;
    }
    return retrievedTickets;
  }

  @override
  void initState() {
    super.initState();

    if (ringTimer != null) {
      ringTimer!.cancel();
      ringTimer = null;
    }

    getInactiveTime();
    initPing();

    NodeSocketService().stream.listen((message) async {

      final json = jsonDecode(message);
      final type = json['type'];
      final dynamic data = json['data'];

      print(type);

      if (type == 'batchStatus') {
        final status = json['status'];
        if (status == 'denied') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Action denied. Ticket already taken.")));
        }
      }

      if (type == 'getTicket') {
        updateTicketStream(null, data);
        updateServingTicketStream(data);
        resetRinger();
      }

      if (type == 'updateTicket') {
        NodeSocketService().sendMessage('getTicket', {});
      }

      if (type == 'createTicket') {
        NodeSocketService().sendMessage('getTicket', {});
      }
    });

    NodeSocketService().sendMessage('getTicket', {});
  }


  @override
  void dispose() {
    pingTimer.cancel();
    update?.cancel();
    if (ringTimer != null) {
      ringTimer!.cancel();
      ringTimer = null;
    }
    super.dispose();
  }

  initPing() {
    pingTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      NodeSocketService().sendMessage("stationPing", {
        "id": widget.station.id,
        "sessionPing": DateTime.now().toString(),
        "inSession": 1,
        "userInSession": widget.user.username
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print("myID: ${widget.station.id}");

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
                                  Builder(
                                    builder: (context) {
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
                                    }
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
                                            onTap: () {
                                              callAgainCounter = 0;

                                              final timestamp = DateTime.now().toString();
                                                try {
                                                  showDialog(context: context, builder: (_) => AlertDialog(
                                                    title: Text("Call Next?"),
                                                    content: Container(
                                                      height: 30,
                                                      width: 250,
                                                      child: Column(
                                                        children: [
                                                          Text("Your next pending will be called.", style: TextStyle()),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(child: Text("Confirm", style: TextStyle(fontWeight: FontWeight.w700)), onPressed: () {
                                                        if (servingStream.value != null) {
                                                          try {
                                                            List<Map<String, dynamic>> dataBatch = [];

                                                            dataBatch.add({
                                                              'type': 'updateTicket',
                                                              'data': {
                                                                'id': servingStream.value!.id,
                                                                'status': 'Done',
                                                                'timeDone': timestamp,
                                                                'log': "${servingStream.value!.log}, $timestamp: Ticket Session Finished",
                                                                "userAssigned": widget.user.username,
                                                                "stationName": widget.station.stationName,
                                                                "stationNumber": widget.station.stationNumber,
                                                                "timeTaken": servingStream.value!.timeTaken,
                                                                "serviceType": servingStream.value!.serviceType,
                                                                "blinker": 1,
                                                                "callCheck": 1
                                                              }
                                                            });


                                                            if (ticketStream.value.isNotEmpty) {
                                                              if (ticketStream.value[0]
                                                                  .serviceType! ==
                                                                  callBy ||
                                                                  callBy ==
                                                                      'Time Order') {

                                                                dataBatch.add({
                                                                  'type': 'updateTicket',
                                                                  'data': {
                                                                    "id": ticketStream.value[0].id!,
                                                                    'status': 'Serving',
                                                                    'timeDone': "",
                                                                    'log': "${ticketStream.value[0].log!}, $timestamp: serving on ${widget.station.stationName!}${widget.station.stationNumber!} by ${widget.user.username!}",
                                                                    "userAssigned": widget.user.username!,
                                                                    "stationName": widget.station.stationName!,
                                                                    "stationNumber": widget.station.stationNumber!,
                                                                    "timeTaken": timestamp,
                                                                    "serviceType": ticketStream.value[0].serviceType!,
                                                                    "blinker": 0,
                                                                    "callCheck": 0
                                                                  }
                                                                });

                                                                dataBatch.add({
                                                                  'type': 'updateStation',
                                                                  'data': {
                                                                    'id': widget.station.id!,
                                                                    'ticketServing': ticketStream.value[0].codeAndNumber!,
                                                                    'ticketServingId': ticketStream.value[0].id!
                                                                  }
                                                                });

                                                                dataBatch.add({
                                                                  'type': 'updateDisplay',
                                                                  'data': {}
                                                                });

                                                                NodeSocketService().sendBatch(dataBatch);

                                                                print(dataBatch);

                                                                swap = !swap;
                                                              }
                                                            } else {

                                                              dataBatch.add({
                                                                'type': 'updateStation',
                                                                'data': {
                                                                  'id': widget.station.id!,
                                                                  'ticketServing': "",
                                                                  'ticketServingId': null,
                                                                }
                                                              });

                                                              dataBatch.add({
                                                                'type': 'updateDisplay',
                                                                'data': {}
                                                              });

                                                              NodeSocketService().sendBatch(dataBatch);

                                                              resetRinger();
                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                  content:
                                                                  Text("Ticket complete.")));
                                                            }

                                                          } catch(e) {
                                                            print(e);
                                                          }
                                                        }
                                                        else {

                                                          List<Map<String, dynamic>> dataBatch = [];

                                                          if (ticketStream.value.isNotEmpty) {
                                                            if (ticketStream.value[0]
                                                                .serviceType! ==
                                                                callBy ||
                                                                callBy ==
                                                                    'Time Order') {


                                                              dataBatch.add({
                                                                'type': 'updateTicket',
                                                                'data': {
                                                                  "id": ticketStream.value[0].id!,
                                                                  'status': 'Serving',
                                                                  'timeDone': "",
                                                                  'log': "${ticketStream.value[0].log!}, $timestamp: serving on ${widget.station.stationName!}${widget.station.stationNumber!} by ${widget.user.username!}",
                                                                  "userAssigned": widget.user.username!,
                                                                  "stationName": widget.station.stationName!,
                                                                  "stationNumber": widget.station.stationNumber!,
                                                                  "timeTaken": timestamp,
                                                                  "serviceType": ticketStream.value[0].serviceType!,
                                                                  "blinker": 0,
                                                                  "callCheck": 0
                                                                }
                                                              });

                                                              dataBatch.add({
                                                                'type': 'updateStation',
                                                                'data': {
                                                                  'id': widget.station.id!,
                                                                  'ticketServing': ticketStream.value[0].codeAndNumber!,
                                                                  'ticketServingId': ticketStream.value[0].id!
                                                                }
                                                              });

                                                              dataBatch.add({
                                                                'type': 'updateDisplay',
                                                                'data': {}
                                                              });

                                                              NodeSocketService().sendBatch(dataBatch);
                                                              swap = !swap;

                                                            }
                                                          }  else {

                                                            ScaffoldMessenger.of(
                                                                context)
                                                                .showSnackBar(SnackBar(
                                                                content: Text(
                                                                    "No pending tickets to serve at the moment.")));
                                                          }
                                                        }
                                                        Navigator.pop(context);
                                                      })
                                                    ],
                                                  ));

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
                                            onTap: () {
                                              final timestamp =
                                                  DateTime.now().toString();

                                              if (servingStream.value != null) {
                                                showDialog(
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
                                                                                          onTap: () {
                                                                                            callAgainCounter = 0;

                                                                                            try {
                                                                                              List<Map<String, dynamic>> dataBatch = [];
                                                                                              final timestamp = DateTime.now().toString();

                                                                                              dataBatch.add({
                                                                                                'type': 'updateTicket',
                                                                                                'data': {
                                                                                                  "id": servingStream.value!.id,
                                                                                                  'log': "${servingStream.value!.log!}, $timestamp: ticket transferred to ${service.serviceType!}",
                                                                                                  'status': "Pending",
                                                                                                  'userAssigned': "",
                                                                                                  'stationName': "",
                                                                                                  'stationNumber': "",
                                                                                                  'timeTaken': servingStream.value!.timeTaken!,
                                                                                                  'timeDone' : "",
                                                                                                  'serviceType': service.serviceType!,
                                                                                                  'callCheck': 0,
                                                                                                  'blinker': 0
                                                                                                }
                                                                                              });


                                                                                              if (ticketStream.value.isNotEmpty) {
                                                                                                if (ticketStream.value[0]
                                                                                                    .serviceType! ==
                                                                                                    callBy ||
                                                                                                    callBy ==
                                                                                                        'Time Order') {

                                                                                                  dataBatch.add({
                                                                                                    'type': 'updateTicket',
                                                                                                    'data': {
                                                                                                      "id": ticketStream.value[0].id!,
                                                                                                      "userAssigned": widget.user.username!,
                                                                                                      "status": "Serving",
                                                                                                      "stationName": widget.station.stationName!,
                                                                                                      "stationNumber": widget.station.stationNumber!,
                                                                                                      "log":"${ticketStream.value[0].log}, $timestamp: serving on ${widget.station.stationName!}${widget.station.stationNumber!} by ${widget.user.username!}",
                                                                                                      "timeTaken": timestamp,
                                                                                                      "timeDone" : "",
                                                                                                      "serviceType": ticketStream.value[0].serviceType!,
                                                                                                      'callCheck': 0,
                                                                                                      'blinker': 0
                                                                                                    }
                                                                                                  });

                                                                                                  dataBatch.add({
                                                                                                    'type': 'updateStation',
                                                                                                    'data': {
                                                                                                      'id': widget.station.id!,
                                                                                                      'ticketServing': ticketStream.value[0].codeAndNumber!,
                                                                                                      'ticketServingId': ticketStream.value[0].id!
                                                                                                    }
                                                                                                  });

                                                                                                  dataBatch.add({
                                                                                                    'type': 'updateDisplay',
                                                                                                    'data': {}
                                                                                                  });

                                                                                                  NodeSocketService().sendBatch(dataBatch);
                                                                                                  swap = !swap;

                                                                                                  Navigator.pop(context, 1);

                                                                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket Transferred to '${service.serviceType!}'")));

                                                                                                  resetRinger();


                                                                                                }
                                                                                              } else {
                                                                                                dataBatch.add({
                                                                                                  'type': 'updateStation',
                                                                                                  'data': {
                                                                                                    'id': widget.station.id!,
                                                                                                    'ticketServing': "",
                                                                                                    'ticketServingId': null
                                                                                                  }
                                                                                                });

                                                                                                dataBatch.add({
                                                                                                  'type': 'updateDisplay',
                                                                                                  'data': {}
                                                                                                });

                                                                                                NodeSocketService().sendBatch(dataBatch);

                                                                                                Navigator.pop(context, 1);
                                                                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket Transferred to '${service.serviceType!}'")));

                                                                                                resetRinger();
                                                                                              }

                                                                                            } catch(e) {
                                                                                              print(e);
                                                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
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
                                              onTap: () {
                                                final timestamp =
                                                    DateTime.now().toString();

                                                try {
                                                  List<Map<String, dynamic>> dataBatch = [];

                                                  if (servingStream.value != null) {
                                                    if (callAgainCounter < 3) {
                                                      callAgainCounter += 1;

                                                      dataBatch.add({
                                                        'type': 'updateTicket',
                                                        'data': {
                                                          "id": servingStream.value!.id,
                                                          "userAssigned": widget.user.username!,
                                                          "status": "Serving",
                                                          "stationName": widget.station.stationName!,
                                                          "stationNumber": widget.station.stationNumber!,
                                                          "timeTaken": timestamp,
                                                          "timeDone" : "",
                                                          "serviceType": servingStream.value!.serviceType!,
                                                          'callCheck': 0,
                                                          'blinker': 0,
                                                          'log': "${servingStream.value!.log!}, ${DateTime.now()}: ticket called again"
                                                        }
                                                      });

                                                      dataBatch.add({
                                                        'type': 'updateStation',
                                                        'data': {
                                                          'id': widget.station.id!,
                                                          'ticketServing': servingStream.value!.codeAndNumber!,
                                                          'ticketServingId': servingStream.value!.id!
                                                        }
                                                      });

                                                      dataBatch.add({
                                                        'type': 'updateDisplay',
                                                        'data': {}
                                                      });

                                                      NodeSocketService().sendBatch(dataBatch);

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
                                                                          () {

                                                                        dataBatch.add({
                                                                          'type': 'updateTicket',
                                                                          'data': {
                                                                            "id": servingStream.value!.id!,
                                                                            "status": 'Released',
                                                                            'log': "${servingStream.value!.log!}, ${DateTime.now()}: Ticket Released",
                                                                            "userAssigned": widget.user.username!,
                                                                            "stationName": "",
                                                                            "stationNumber": "",
                                                                            "timeTaken": timestamp,
                                                                            "timeDone" : "",
                                                                            "serviceType": servingStream.value!.serviceType!,
                                                                            'callCheck': servingStream.value!.callCheck!,
                                                                            'blinker': servingStream.value!.blinker!,
                                                                          }
                                                                        });

                                                                        dataBatch.add({
                                                                          'type': 'updateStation',
                                                                          'data': {
                                                                            'id': widget.station.id!,
                                                                            'ticketServing': "",
                                                                            'ticketServingId': null
                                                                          }
                                                                        });

                                                                        dataBatch.add({
                                                                          'type': 'updateDisplay',
                                                                          'data': {}
                                                                        });

                                                                        NodeSocketService().sendBatch(dataBatch);


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

                                                } catch(e) {
                                                  print(e);
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
                                                NodeSocketService().sendMessage('getTicket', {});
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
                                        NodeSocketService().sendMessage('getTicket', {});
                                        swap = !swap;
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
                                                                              NodeSocketService().sendMessage('getTicket', {});
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
                                                        : ValueListenableBuilder(
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
        .toList();

    if (control.isNotEmpty) {
      inactiveLength = int.parse(control[0]['other'].toString());
      inactiveOn = int.parse(control[0]['value'].toString());
    }

    return;
  }

  List<Ticket> getTicket([String? filtered, List<dynamic>? tickets]) {
    final dateNow = DateTime.now();

    try {
      final List<dynamic> response = tickets!;

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


  updateServingTicketStream(dynamic data) {
    List<Ticket> servings = getServingTicket(data);
    if (servings.isEmpty) {
      servingStream.value = null;
      return servings;
    } else {
      servingStream.value = null;
      servingStream.value = servings[0];
      return servings;
    }
  }

  getServingTicket(List<dynamic> data) {
    try {
      final List<dynamic> response = data;
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
                  Navigator.pop(context);
                  resetRinger();
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


    if (inactiveOn == 1 && inactiveLength != 0) {
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


