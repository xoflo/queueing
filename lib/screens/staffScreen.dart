import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';
import 'package:queueing/models/service.dart';
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

    update = Timer.periodic(Duration(seconds: 2, milliseconds: 500), (value) async {
      final List<dynamic> result = await getStationSQL();
      List<dynamic> pingSorted = result.where((e) => e['sessionPing'] != "").toList();

      for (int i = 0; i < pingSorted.length; i++) {
        final station = Station.fromJson(pingSorted[i]);

        final pingDate = DateTime.parse(station.sessionPing!);
        if (DateTime.now().difference(pingDate).inSeconds > 5) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediaQuery.of(context).size.width < 600 || MediaQuery.of(context).size.height < 600 ? Container(
        child: Center(child: Text("Expand Screen Size to Display", style: TextStyle(fontSize: 30))),
      ) : Stack(
        children: [
          logoBackground(context),
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Welcome, ${widget.user.username}",
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.w700)))),
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
                                                  Text("${station.serviceType}"),
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
                                            await station.update({
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
    );
  }

  getStationSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_station.php');

      final result = await http.get(uri);

      final response = jsonDecode(result.body);

      print("response1: $response");

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

  @override
  void initState() {
    pingTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await widget.station.update({
        "sessionPing": DateTime.now().toString(),
        "inSession": 1,
        "userInSession": widget.user.username,
      });
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
    return Scaffold(
      body: MediaQuery.of(context).size.width < 600 || MediaQuery.of(context).size.height < 600 ? Container(
        child: Center(child: Text("Expand Screen Size to Display", style: TextStyle(fontSize: 30))),
      ) : Stack(
        children: [
        logoBackground(context),
          Container(
            padding: EdgeInsets.all(20),
            child: FutureBuilder(
              future: getTicketSQL(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Ticket>> snapshot) {
                return snapshot.connectionState == ConnectionState.done
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("User In-Session: "),
                              Text("${widget.user.username}", style: TextStyle(fontWeight: FontWeight.w700))
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Station: "),
                              Text("${widget.station.serviceType} | ${widget.station.stationName} ${widget.station.stationNumber}", style: TextStyle(fontWeight: FontWeight.w700))
                              ],
                          ),
                          SizedBox(height: 20),
                          serving != null ? Text("Serving Ticket: ") : Card(
                            child: Container(
                              height: 350,
                              width: 250,
                              child: Center(
                                child: Text("No ticket to serve at the moment.", style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          ),
                          StatefulBuilder(
                            builder: (BuildContext context, void Function(void Function()) setState) {
                              return FutureBuilder(
                                future: getServingTicketSQL(),
                                builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshotServing) {
                                  return snapshotServing.connectionState == ConnectionState.done ? snapshotServing.data!.length != 0 ? Builder(
                                    builder: (context) {
                                      serving = Ticket.fromJson(snapshotServing.data!.last);

                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        child: Padding(
                                          padding: const EdgeInsets.all(30.0),
                                          child: Container(
                                            height: 350,
                                            width: 250,
                                            child: Column(
                                              children: [
                                                Text("${snapshotServing.data!.last.serviceType}",
                                                    style: TextStyle(fontSize: 30)),
                                                Text(
                                                    "${snapshotServing.data!.last.serviceCode}${snapshotServing.data!.last.number}",
                                                    style: TextStyle(fontSize: 30)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  ): Container() : Container(
                                    height: 100,
                                    width: 100,
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                  onPressed: () {
                                    if (snapshot.data!.isNotEmpty) {
                                      if (serving != null) {
                                        showDialog(context: context, builder: (_) => AlertDialog(
                                          title: Text("Confirm Done?"),
                                          content: Container(
                                            height: 300,
                                            width: 300),
                                          actions: [
                                            TextButton(onPressed: () {
                                              final timestamp = DateTime.now().toString();

                                              serving!.update({
                                                "status": "Done",
                                                "timeDone": timestamp,
                                                "log": "${serving!.log}, $timestamp: ticket session finished"
                                              });

                                              snapshot.data![0].update({
                                                "userAssigned": widget.user.username,
                                                "status": "Serving",
                                                "stationName": widget.station.stationName,
                                                "stationNumber": widget.station.stationNumber,
                                                "log":
                                                "${snapshot.data![0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                                "timeTaken": timestamp
                                              });
                                            }, child: Text("Confirm"))
                                          ],
                                        ));
                                      } else {
                                        final timestamp = DateTime.now().toString();

                                        snapshot.data![0].update({
                                          "userAssigned": widget.user.username,
                                          "status": "Serving",
                                          "stationName": widget.station.stationName,
                                          "stationNumber": widget.station.stationNumber,
                                          "log":
                                          "${snapshot.data![0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                          "timeTaken": timestamp
                                        });
                                      }

                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No pending tickets to serve at the moment.")));
                                    }

                                    setState(() {});
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
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No ticket being servied at the moment.")));
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
                          )
                        ],
                      )
                    : Container(
                        height: 400,
                        child: Center(
                          child: Container(
                            height: 100,
                            width: 100,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  getTicketSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      print("responseLength: ${response.length}");
      final sorted = response
          .where((e) =>
              e['serviceType'] == widget.station.serviceType &&
              e['status'] == "Pending")
          .toList();
      List<Ticket> newTickets = [];

      print("serviceType: ${widget.station.serviceType}");

      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a, b) => DateTime.parse(a.timeCreated!)
          .compareTo(DateTime.parse(b.timeCreated!)));

      newTickets.sort((a, b) => a.priority!.compareTo(b.priority!));

      print("newTickets: ${newTickets.length}");

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
      print("responseLength: ${response.length}");
      final sorted = response
          .where((e) =>
              e['serviceType'] == widget.station.serviceType &&
              e['status'] == "Serving" &&
              e['userAssigned'] == widget.user.username)
          .toList();
      List<Ticket> newTickets = [];

      print("serviceType: ${widget.user.serviceType}");

      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a, b) => DateTime.parse(a.timeTaken!)
          .compareTo(DateTime.parse(b.timeTaken!)));

      print("newTickets: ${newTickets.length}");

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
