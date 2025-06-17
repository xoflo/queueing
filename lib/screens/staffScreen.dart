import 'dart:async';
import 'dart:convert';
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

    update = Timer.periodic(Duration(seconds: 2), (value) async {
      final List<dynamic> result = await getStationSQL();
      List<dynamic> pingSorted = result.where((e) => e['sessionPing'] != "").toList();

      final DateTime newTime = DateTime.now();
      widget.user.update({
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

    super.initState();
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
            logoBackground(context, 350),
            Container(
              padding: EdgeInsets.all(20),
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
                                  fontSize: 30, fontWeight: FontWeight.w700)),
                          Spacer(),
                          IconButton(onPressed: () {

                            List<String> servicesSet = [];

                            showDialog(context: context, builder: (_) => AlertDialog(
                              title: Text("Set Services to Process"),
                              content: Container(
                                height: 400,
                                width: 400,
                                child: StatefulBuilder(
                                  builder: (BuildContext context, void Function(void Function()) setStateList) {
                                    return ListView.builder(
                                        itemCount: widget.user.serviceType!.length,
                                        itemBuilder: (context, i) {
                                          return CheckboxListTile(value: servicesSet.contains(widget.user.serviceType![i].toString()), onChanged: (value) {

                                            if (servicesSet.length == 3) {
                                              if (value == true) {
                                                servicesSet.removeLast();
                                                servicesSet.add(widget.user.serviceType![i].toString());
                                                setStateList((){});
                                              } else {
                                                servicesSet.remove(widget.user.serviceType![i].toString());
                                                setStateList((){});
                                              }
                                            }

                                          });
                                        });
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () {
                                  widget.user.update({
                                    "servicesSet": servicesSet.toString()
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You will now accomodate the set services.")));
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
                          ? Builder(
                            builder: (context) {
                              List<String> sorted = [];

                              for (int i = 0; i < snapshot.data!.length; i++) {
                                sorted.add(snapshot.data![i]['serviceType']);
                              }

                              sorted = sorted.toSet().toList();

                              return Container(
                                  height: MediaQuery.of(context).size.height - 110,
                                  child: GridView.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: MediaQuery.of(context).size.width < 700 ? 3 : 5),
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, i) {
                                        final station =
                                            Station.fromJson(snapshot.data![i]);
                                        return InkWell(
                                          child: Card(
                                              child: Container(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text("${station.stationName} ${station.stationNumber}"),
                                                station.inSession == 0
                                                    ? Text("Available",
                                                        style:
                                                            TextStyle(color: Colors.green))
                                                    : Text("${station.userInSession}",
                                                        style: TextStyle(
                                                            color: Colors.redAccent))
                                                                                  ],
                                                                                ),
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
                                );
                            }
                          )
                          : Center(
                              child: Container(
                                height: 100,
                                width: 100,
                                child: CircularProgressIndicator(
                                  color: Colors.redAccent,
                                ),
                              ),
                            );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  getServices() async {

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

  Ticket? serving;
  List<Ticket> tickets = [];
  int ticketLength = 0;
  int loadDone = 0;

  @override
  void initState() {
    pingTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      widget.station.update({
        "sessionPing": DateTime.now().toString(),
        "inSession": 1,
        "userInSession": widget.user.username,
      });

      List<Ticket> retrievedTickets = await getTicketSQL();

      if (ticketLength != retrievedTickets.length) {
        loadDone = 1;
        tickets = retrievedTickets;
        ticketLength = retrievedTickets.length;
        setState(() {});
      } else {
        if (loadDone == 0) {
          loadDone = 1;
          setState(() {});
        }
      }


    });
    super.initState();
  }

  @override
  void dispose() {
    pingTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: MediaQuery.of(context).size.width < 350 || MediaQuery.of(context).size.height < 550 ? Container(
          child: Center(child: Text("Expand Screen Size to Display", style: TextStyle(fontSize: 30), textAlign: TextAlign.center)),
        ) : SingleChildScrollView(
          child: Stack(
            children: [
            logoBackground(context, 350),
              Container(
                padding: EdgeInsets.all(20),
                child: loadDone != 0 ?  Column(
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
                        Text("${widget.station.stationName} ${widget.station.stationNumber}", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))
                      ],
                    ),
                    SizedBox(height: 30),
                    StatefulBuilder(
                      builder: (BuildContext context, void Function(void Function()) setState) {
                        return FutureBuilder(
                          future: getServingTicketSQL(),
                          builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshotServing) {
                            return snapshotServing.connectionState == ConnectionState.done ? snapshotServing.data!.length != 0 ? Builder(
                                builder: (context) {
                                  serving = snapshotServing.data!.last;
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Padding(
                                      padding: const EdgeInsets.all(30.0),
                                      child: Container(
                                        height: 300,
                                        width: 200,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text("${serving!.serviceType}",
                                                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
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
                              child: Container(
                                height: 300,
                                width: 200,
                                child: Center(
                                  child: Text("No ticket to serve at the moment.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                            ) : Container(
                              height: 100,
                              width: 100,
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () {

                              if (serving != null) {
                                showDialog(context: context, builder: (_) => AlertDialog(
                                  title: Text("Confirm Done?"),
                                  content: Container(
                                      height: 40),
                                  actions: [
                                    TextButton(onPressed: () {
                                      final timestamp = DateTime.now().toString();

                                      serving!.update({
                                        "status": "Done",
                                        "timeDone": timestamp,
                                        "log": "${serving!.log}, $timestamp: ticket session finished"
                                      });

                                      if (tickets.isNotEmpty) {
                                        tickets[0].update({
                                          "userAssigned": widget.user.username,
                                          "status": "Serving",
                                          "stationName": widget.station.stationName,
                                          "stationNumber": widget.station.stationNumber,
                                          "log":
                                          "${tickets[0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                          "timeTaken": timestamp
                                        });
                                      }

                                      setState(() {});
                                      Navigator.pop(context);
                                    }, child: Text("Confirm"))
                                  ],
                                ));
                              } else {
                                if (tickets.isNotEmpty) {
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

                                  setState(() {});
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No pending tickets to serve at the moment.")));
                                }
                              }
                            },
                            child: Text("Call Next")),
                        SizedBox(width: 10),
                        ElevatedButton(
                            onPressed: () {
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
                                                      'stationNumber': ""
                                                    });

                                                    Navigator.pop(context);
                                                    setState(() {});
                                                  },
                                                );
                                              }) : Center(
                                            child: Text("No Stations", style: TextStyle(color: Colors.grey)),
                                          ) : Center(
                                            child: Container(
                                              height: 50,
                                              width: 50,
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        }),
                                  ),
                                ));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No ticket being served at the moment.")));
                              }
                            }, child: Text("Transfer")),
                        SizedBox(width: 10),
                        ElevatedButton(
                            onPressed: () {
                              if (serving != null) {
                                serving!.update({
                                  "callCheck": 0
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No ticket being served at the moment.")));
                              }
                            }, child: Text("Call Again")),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Upcoming Tickets: ", style: TextStyle(fontWeight: FontWeight.w700)),
                        Container(
                          height: 40,
                          width: tickets.length * 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
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
                ) : Container(
                  height: MediaQuery.of(context).size.height,
                  child: Center(child: Container(
                      height: 100,
                      width: 100,
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

      for (int i = 0; i < widget.user.serviceType!.length; i++) {
        sorted.addAll(response
            .where((e) =>
        e['serviceType'].toString() == widget.user.serviceType![i].toString() &&
            e['status'] == "Pending")
            .toList());
      }

      List<Ticket> newTickets = [];
      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a, b) => DateTime.parse(a.timeCreated!)
          .compareTo(DateTime.parse(b.timeCreated!)));

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
}
