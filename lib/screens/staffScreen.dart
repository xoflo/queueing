import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Welcome, ${widget.user.username}", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)))),
            Divider(),
            SizedBox(height: 10),
            FutureBuilder(
              future: getStationSQL(),
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                return snapshot.connectionState == ConnectionState.done ? Container(
                  height: MediaQuery.of(context).size.height - 110,
                  child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, i) {
                      final station = Station.fromJson(snapshot.data![i]);
                        return InkWell(
                          child: Card(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${station.serviceType}"),
                              Text("${station.stationName} ${station.stationNumber}"),
                              station.inSession == 0 ? Text("Available", style: TextStyle(color: Colors.green)) : Text("${station.userInSession}", style: TextStyle(color: Colors.redAccent))
                            ],
                          )),
                          onTap: () async {
                            final timestamp = DateTime.now().toString();

                            if (station.inSession == 1) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Station is currently in session.")));
                            } else {
                              await station.update({
                                "inSession": 1,
                                "userInSession": widget.user.username,
                                "sessionPing": timestamp
                              });

                              Navigator.push(context, MaterialPageRoute(builder: (_) => StaffSession(user: widget.user, station: station)));

                            }

                          },
                        );
                      }),
                ) : Center(
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
    );
  }


  getStationSQL() async {

    try {

      final uri = Uri.parse('http://$site/queueing_api/api_station.php');

      final result = await http.get(uri);

      final response = jsonDecode(result.body);

      print("response1: $response");

      return response;
    } catch(e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
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

  @override
  void initState() {
    pingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {

      await widget.station.update({
        "sessionPing": DateTime.now().toString()
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
      body: Container(
        padding: EdgeInsets.all(20),
        child: FutureBuilder(
          future: getTicketSQL(),
          builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshot) {


            return Column(
              children: [
                Text("${widget.user.username}: ${widget.station.serviceType} ${widget.station.stationName} ${widget.station.stationNumber}"),
                SizedBox(height: 20),
                Text("Serving Ticket: "),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: () {
                      final timestamp = DateTime.now();

                      snapshot.data![0].update({
                        "userAssigned": widget.user.username,
                        "status": "Serving",
                        "stationName": widget.station.stationName,
                        "stationNumber": widget.station.stationNumber,
                        "log": "${snapshot.data![0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                        "timeTaken": timestamp
                      });
                    }, child: Text("Call Next")),
                    SizedBox(width: 10),
                    ElevatedButton(onPressed: () {
                    }, child: Text("Transfer")),
                    SizedBox(width: 10),
                    ElevatedButton(onPressed: () {
                    }, child: Text("Call Again")),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }

  getTicketSQL() async {

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response.where((e) => e['serviceType'] == widget.user.serviceType && e['status'] == "Pending" && e['userAssigned'] == "").toList();
      List<Ticket> newTickets = [];


      for (int i = 0; i< sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a,b) => DateTime.parse(a.timeCreated!).compareTo(DateTime.parse(b.timeCreated!)));

      return newTickets;

    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }

}

