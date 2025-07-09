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
import '../models/user.dart';

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
      List<dynamic> pingSorted = result.where((e) => e['sessionPing'] != "").toList();

      final DateTime newTime = DateTime.now();
      await widget.user.update({
        'loggedIn': DateTime.now().toString()
      });

      if (pingSorted.length != stationChanges) {
        stationChanges = pingSorted.length;
        setState(() {});
      }

      for (int i = 0; i < pingSorted.length; i++) {
        final station = Station.fromJson(pingSorted[i]);
        final pingDate = DateTime.parse(station.sessionPing!);

        if (newTime.difference(pingDate).inSeconds > 2.5) {
          station.update({
            'inSession': 0,
            'userInSession': "",
            'sessionPing': ""
          });

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: MediaQuery.of(context).size.width < 350 || MediaQuery.of(context).size.height < 550 ? Container(
          child: Center(child: Text("Expand Screen Size to Display", style: TextStyle(fontSize: 30), textAlign: TextAlign.center,)),
        ) : Stack(
          children: [
            imageBackground(context),
            logoBackground(context, 350),
            Container(
              padding: EdgeInsets.all(20),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            IconButton(onPressed: () {
                              Navigator.pop(context);
                            }, icon: Icon(Icons.chevron_left)),
                            Text("Welcome, ${widget.user.username}",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w700)),
                            Spacer(),
                            IconButton(onPressed: () {
                              List<String> serviceSetToNull = [];

                              if (widget.user.serviceType!.length > 3) {
                                serviceSetToNull = [widget.user.serviceType![0].toString(), widget.user.serviceType![1].toString(), widget.user.serviceType![2].toString()];
                              } else {
                               serviceSetToNull = stringToList(widget.user.serviceType!.toString());
                              }

                              List<String> servicesSet = widget.user.servicesSet != null ? stringToList(widget.user.servicesSet.toString()) : serviceSetToNull;

                              showDialog(context: context, builder: (_) => AlertDialog(
                                title: Text("Select Services (3 Max)"),
                                content: Container(
                                  height: 400,
                                  width: 400,
                                  child: StatefulBuilder(
                                    builder: (BuildContext context, void Function(void Function()) setStateList) {
                                      return ListView.builder(
                                          itemCount: widget.user.serviceType!.length,
                                          itemBuilder: (context, i) {
                                            return CheckboxListTile(
                                                title: Text(widget.user.serviceType![i]),
                                                value: servicesSet.contains(widget.user.serviceType![i].toString()), onChanged: (value) {
                                              if (value == true) {
                                                if (servicesSet.length == 3) {
                                                  servicesSet.removeAt(0);
                                                }
                                                servicesSet.add(widget.user.serviceType![i].toString());
                                                setStateList((){});
                                              } else {
                                                servicesSet.remove(widget.user.serviceType![i].toString());
                                                setStateList((){});
                                              }
                                            });
                                          });
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () async {
                                    await widget.user.update({
                                      "servicesSet": servicesSet.toString()
                                    });

                                    await widget.user.updateAssignedServices(widget.user.id!);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The selected services will queue to your selected station.")));
                                  }, child: Text("Confirm"))
                                ],
                              ));
                            }, icon: Icon(Icons.settings))
                          ],
                        )),
                    Divider(),
                    SizedBox(height: 10),
                    FutureBuilder(
                      future: getStationSQL(),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                        return snapshot.connectionState == ConnectionState.done
                            ? Container(
                          height: MediaQuery.of(context).size.height - 120,
                          child: GridView.builder(
                              gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                childAspectRatio: 3 / 1.2,
                                  crossAxisCount: MediaQuery.of(context).size.width < 800 ? MediaQuery.of(context).size.width < 700 ? 2 : 3 : 5),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, i) {
                                final station =
                                Station.fromJson(snapshot.data![i]);
                                return InkWell(
                                  child: Card(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("${station.stationName}${station.stationNumber == 0 ? "" : " ${station.stationNumber}"}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                          station.inSession == 0
                                              ? Text("Available",
                                              style:
                                              TextStyle(color: Colors.green))
                                              : Text("${station.userInSession}",
                                              style: TextStyle(
                                                  color: Colors.redAccent))
                                        ],
                                      )),
                                  onTap: () async {
                                    final timestamp = DateTime.now().toString();

                                    if (station.inSession == 1) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  "Station is currently in session.")));
                                    } else {
                                      station.update({
                                        "inSession": 1,
                                        "userInSession": widget.user.username,
                                        "sessionPing": timestamp
                                      });

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => StaffSession(
                                                  user: widget.user,
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
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Ticket? serving;
  List<Ticket> tickets = [];
  int ticketLength = 0;
  int loadDone = 0;

  int callByUpdate = 1;
  final callByUI = ValueNotifier(1);
  String callBy = "Time Order";

  AudioPlayer player = AudioPlayer();
  bool dialogOn = false;

  @override
  void initState() {
    if (ringTimer != null) {
      ringTimer!.cancel();
    }
    initPing();
  }

  @override
  void dispose() {
    pingTimer.cancel();
    if (ringTimer != null) {
      ringTimer!.cancel();
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

      List<Ticket> retrievedTickets = await getTicketSQL();

      if (callByUpdate == 0) {
        tickets = retrievedTickets;
        callByUpdate = 1;
        callByUI.value = 0;
        print("111 $tickets");
      }

      if (ticketLength != retrievedTickets.length) {
        loadDone = 1;
        tickets = retrievedTickets;
        ticketLength = retrievedTickets.length;
        initRinger();
        setState(() {});

      } else {
        if (loadDone == 0) {
          initRinger();
          loadDone = 1;
          setState(() {});
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: MediaQuery.of(context).size.width < 350 || MediaQuery.of(context).size.height < 550 ? Container(
          child: Center(child: Text("Expand Screen Size to Display", style: TextStyle(fontSize: 30), textAlign: TextAlign.center)),
        ) : Listener(
          onPointerDown: (value) {
            resetRinger();
          },
          child: Stack(
            children: [
              imageBackground(context),
            logoBackground(context, 350),
              Container(
                padding: EdgeInsets.all(20),
                child: loadDone != 0 ?  SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.chevron_left))
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("User In-Session: ", style: TextStyle(fontSize: 20)),
                          Text("${widget.user.username}", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Station: ", style: TextStyle(fontSize: 20)),
                          Text("${widget.station.stationName}${widget.station.stationNumber == 0 ? "" : " ${widget.station.stationNumber}"}", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))
                        ],
                      ),
                      SizedBox(height: 30),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return FutureBuilder(
                            future: getServingTicketSQL(),
                            builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshotServing) {
                              return snapshotServing.connectionState == ConnectionState.done ? snapshotServing.data!.isNotEmpty ? Builder(
                                  builder: (context) {
                                    serving = snapshotServing.data!.last;
                                    return Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: Padding(
                                        padding: const EdgeInsets.all(30.0),
                                        child: Container(
                                          height: 150,
                                          width: 200,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text("${serving!.serviceType}",
                                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                                              Text(
                                                  serving!.codeAndNumber!,
                                                  style: TextStyle(fontSize: 30)),
                                              SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                spacing: 5,
                                                children: [
                                                  Text("Priority:",
                                                      style: TextStyle(fontSize: 15)),
                                                  Text(
                                                      serving!.priorityType!,
                                                      style: TextStyle(fontSize: 15)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ) ;
                                  }
                              ): Card(
                                child: Builder(
                                  builder: (context) {
                                    serving = null;
                                    return Container(
                                      height: 150,
                                      width: 200,
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text("No ticket to serve at the moment.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)),
                                      ),
                                    );
                                  }
                                ),
                              ) : Container(
                                height: 300,
                                child: Center(
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            child: Card(
                              child: InkWell(
                                splashColor: Theme.of(context).splashColor,
                                highlightColor: Theme.of(context).highlightColor,
                                child: Container(
                                  height: 100,
                                  width: kIsWeb == true ? 200 : 95,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.double_arrow),
                                      SizedBox(width: 5),
                                      Text("Call Next", textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  if (serving != null) {
                                    showDialog(context: context, builder: (_) => AlertDialog(
                                      title: Text("Confirm Done?"),
                                      content: Container(
                                          child: Text("'Done' to complete and 'Call Next' to serve next ticket."),
                                          height: 40),
                                      actions: [
                              
                                        TextButton(onPressed: () {
                                          final timestamp = DateTime.now().toString();
                              
                                          serving!.update({
                                            "status": "Done",
                                            "timeDone": timestamp,
                                            "log": "${serving!.log}, $timestamp: Ticket Session Finished"
                                          });
                              
                                          setState(() {});
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket complete.")));
                              
                                        }, child: Text("Done")),
                                        TextButton(onPressed: () {
                                          final timestamp = DateTime.now().toString();
                              
                                          serving!.update({
                                            "status": "Done",
                                            "timeDone": timestamp,
                                            "log": "${serving!.log}, $timestamp: Ticket Session Finished"
                                          });
                              
                              
                                          if (tickets.isNotEmpty) {
                                            if (tickets[0].serviceType! == callBy || callBy == 'Time Order') {
                                              tickets[0].update({
                                                "userAssigned": widget.user.username,
                                                "status": "Serving",
                                                "stationName": widget.station.stationName,
                                                "stationNumber": widget.station.stationNumber,
                                                "log":
                                                "${tickets[0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                                "timeTaken": timestamp
                                              });
                              
                              
                                              setState(() {});
                                              Navigator.pop(context);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No '$callBy' Tickets at the moment.")));
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No pending tickets to serve at the moment.")));
                                          }
                              
                                        }, child: Text("Call Next"))
                                      ],
                                    ));
                                  }
                                  else {
                                    if (tickets.isNotEmpty) {
                                      if (tickets[0].serviceType! == callBy || callBy == 'Time Order') {
                                        final timestamp = DateTime.now().toString();
                                        tickets[0].update({
                                          "userAssigned": widget.user.username,
                                          "status": "Serving",
                                          "stationName": widget.station.stationName,
                                          "stationNumber": widget.station.stationNumber,
                                          "log":
                                          "${tickets[0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                          "timeTaken": timestamp
                                        });
                              
                                        callByUI.value = 0;
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No '$callBy' Tickets at the moment.")));
                                      }
                              
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No pending tickets to serve at the moment.")));
                                    }
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
                                  height: 100,
                                  width: kIsWeb == true ? 200 : 95,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.move_down_sharp),
                                      SizedBox(height: 5),
                                      Text("Transfer"),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  if (serving != null) {
                                    showDialog(context: context, builder: (_) => AlertDialog(
                                      title: Text("Select Station to Transfer"),
                                      content: Container(
                                        height: 400,
                                        width: 400,
                                        child: FutureBuilder(
                                            future: getServiceSQL(),
                                            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                                              return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? ListView.builder(
                                                  itemCount: snapshot.data!.length,
                                                  itemBuilder: (context, i) {
                                                    final service = Service.fromJson(snapshot.data![i]);

                                                    return ListTile(
                                                      title: Text(service.serviceType!),
                                                      onTap: () {
                                                        final timestamp = DateTime.now().toString();

                                                        serving!.update({
                                                          'log': "${serving!.log}, $timestamp: ticket transferred to ${service.serviceType}",
                                                          'status': "Pending",
                                                          'userAssigned': "",
                                                          'stationName': "",
                                                          'stationNumber': "",
                                                          'serviceType': "${service.serviceType}",
                                                          'callCheck': 0,
                                                          'blinker': 0
                                                        });

                                                        Navigator.pop(context);
                                                        setState(() {});
                                                        callByUI.value = 0;
                                                      },
                                                    );
                                                  }) : Center(
                                                child: Text("No Stations", style: TextStyle(color: Colors.grey)),
                                              ) : Container(
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
                                      ),
                                    ));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No ticket being served\nat the moment.")));
                                  }
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Builder(
                              builder: (context) {
                                int callAgainCounter = 0;

                                return ClipRRect(
                                  child: Card(
                                    child: InkWell(
                                      child: Container(
                                        height: 100,
                                        width: kIsWeb == true ? 200 : 95,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.volume_up),
                                            SizedBox(width: 5),
                                            Text("Call Again"),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        if (serving != null) {

                                          if (callAgainCounter < 3) {
                                            callAgainCounter += 1;
                                            serving!.update({
                                              'blinker': 0,
                                              "callCheck": 0,
                                              'log': "${serving!.log!}, ${DateTime.now()}: ticket called again"
                                            });
                                          } else {
                                            showDialog(context: context, builder: (_) => AlertDialog(
                                              title: Text("Dismiss Ticket?"),
                                              content: Container(
                                                child: Text("Ticket has been called a few times."),
                                                height: 40,
                                              ),
                                              actions: [
                                                TextButton(
                                                    child: Text("Dismiss"),
                                                    onPressed: () {
                                                      serving!.update({
                                                        "status": 'Dismissed',
                                                        'log': "${serving!.log!}, ${DateTime.now()}: Ticket Dismissed"
                                                      });

                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket Dismissed")));
                                                      setState(() {});
                                                    })
                                              ],
                                            ));
                                          }

                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No ticket being served at the moment.")));
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }
                          ),
                          SizedBox(height: 30),
                        ],
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: callByUI,
                        builder: (BuildContext context, int value, Widget? child) {
                          callByUI.value = 1;

                          return StatefulBuilder(
                            builder: (BuildContext context, void Function(void Function()) setStateTickets) {
                              return Column(
                                children: [
                                  Builder(
                                      builder: (context) {
                                        List<String> callByList = [];
                                        if (widget.user.servicesSet!.isNotEmpty) {
                                          stringToList(widget.user.servicesSet!.toString());
                                        }

                                        callByList.insert(0, "Time Order");

                                        return Container(
                                          height: 40,
                                          width: 300,
                                          child: TextButton(
                                              child: Text("Sort By: $callBy", textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
                                              onPressed: () {
                                                showDialog(context: context, builder: (_) => AlertDialog(
                                                  content: Container(
                                                    height: 300,
                                                    width: 300,
                                                    child: ListView.builder(
                                                        itemCount: callByList.length,
                                                        itemBuilder: (context, i) {
                                                          return ListTile(
                                                            title: Text(callByList[i]),
                                                            onTap: () {
                                                              callBy = callByList[i];
                                                              callByUpdate = 0;

                                                              setStateTickets((){});
                                                              Navigator.pop(context);
                                                            },
                                                          );
                                                        }),
                                                  ),
                                                ));
                                              }),
                                        );
                                      }
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Upcoming Tickets:", style: TextStyle(fontWeight: FontWeight.w700)),
                                      SizedBox(height: 10),
                                      Container(
                                        height: 250,
                                        width: 150,
                                        child: tickets.isEmpty ? Text("No pending tickets\nat the moment.", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center) : ListView.builder(
                                            scrollDirection: Axis.vertical,
                                            itemCount: tickets.length,
                                            itemBuilder: (context, i) {
                                              return Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text("${i + 1}. ${tickets[i].codeAndNumber}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                              );
                                            }),
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
                ) : Container(
                  height: 300,
                  child: Center(child: Container(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator())),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  getTicketSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);

      List<dynamic> sorted = [];

      for (int i = 0; i < widget.user.servicesSet!.length; i++) {
        sorted.addAll(response
            .where((e) =>
        e['serviceType'].toString() == widget.user.servicesSet![i].toString() &&
            e['status'] == "Pending")
            .toList());
      }

      List<Ticket> newTickets = [];
      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      if (callBy == "Time Order") {
        newTickets.sort((a, b) => DateTime.parse(a.timeCreated!)
            .compareTo(DateTime.parse(b.timeCreated!)));

        newTickets.sort((a, b) => b.priority!.compareTo(a.priority!));
      } else {
        newTickets.sort((a, b) {
          if ((a.serviceType! == callBy) && (b.serviceType! != callBy)) return -1;
          if ((a.serviceType! != callBy) && (b.serviceType! == callBy)) return 1;
          return 0;
        });
      }

      newTickets.sort((a, b) => b.priority!.compareTo(a.priority!));

      return newTickets;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
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
      newTickets.sort((a, b) => DateTime.parse(a.timeTaken!)
          .compareTo(DateTime.parse(b.timeTaken!)));

      final realTickets = newTickets.where((e) => DateTime.parse(e.timeCreated!).day == dateNow.day && DateTime.parse(e.timeCreated!).month == dateNow.month && DateTime.parse(e.timeCreated!).year == dateNow.year).toList();

      final List<Ticket> dummyTicket = [];


      return realTickets.isEmpty ? dummyTicket : realTickets;
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
      response.sort((a, b) => int.parse(a['id'].toString()).compareTo(int.parse(b['id'].toString())));

      return response;
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
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

  inactiveDialog() {
    dialogOn = true;
    _play();
    final ringerSound = Timer.periodic(Duration(seconds: 5), (callback) {
      _play();
    });

    showDialog(context: context, builder: (_) => PopScope(
      onPopInvokedWithResult: (bool, value){
        ringerSound.cancel();
        _stop();
      },
      child: AlertDialog(
        content: GestureDetector(
          onTap: () {
            ringerSound.cancel();
            _stop();
            Navigator.pop(context);
          },
          child: Container(
            height: 80,
            width: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("INACTIVITY DETECTED", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                Text("Press to Dismiss", style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  resetRinger() {
    if (ringTimer != null) {
      print("ringerReset");
      dialogOn = false;
      ringTimer!.cancel();
      initRinger();
    }
  }

  initRinger() {
    print('ringerCalled');
    if (serving == null && tickets.isNotEmpty) {
      if (ringTimer == null) {
        print('ringerStart');
        ringTimer = Timer.periodic(Duration(seconds: 20), (value) {
          if (!dialogOn) {
            inactiveDialog();
          }
        });
      } else {
        print('ringerStart');
        ringTimer!.cancel();
        ringTimer = Timer.periodic(Duration(seconds: 20), (value) {
          if (!dialogOn) {
            Navigator.pop(context);
            inactiveDialog();
          }
        });
      }
    } else {
      print('Has Serving or No Pending');
    }
  }

  _play() {
    player.play(AssetSource('ringer.mp3'));
  }

  _stop() {
    player.stop();

  }
}
