import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:queueing/globals.dart';
import 'package:queueing/models/service.dart';
import 'package:queueing/screens/adminScreen.dart';
import 'package:http/http.dart' as http;

import '../models/priority.dart';
import '../models/ticket.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {

  TextEditingController name = TextEditingController();
  String priorityType = "None";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 100,
            child: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setStateRow) {
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    spacing: 10,
                    children: [
                      Container(
                        width: (MediaQuery.of(context).size.width * 1/2) - 40,
                        child: TextField(
                          controller: name,
                          decoration: InputDecoration(
                              labelText: 'Name (Optional)',
                              labelStyle: TextStyle(color: Colors.grey)
                          ),
                        ),
                      ),
                      Text("Priority:", style: TextStyle(fontSize: 30)),
                      Container(
                        height: 50,
                        width: (MediaQuery.of(context).size.width * 1/2) - 120,
                        child: FutureBuilder(
                          future: getPriority(),
                          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                            return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? StatefulBuilder(
                              builder: (BuildContext context, void Function(void Function()) setStateList) {
                                return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, i) {
                                      final Priority priority = Priority.fromJson(snapshot.data![i]);

                                      return Container(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (priorityType == priority.priorityName!) {
                                              priorityType = "None";
                                              setStateList((){});
                                            } else {
                                              priorityType = priority.priorityName!;
                                              setStateList((){});
                                            }

                                          },
                                          child: Card(
                                            color: colorHandler(priority.priorityName!),
                                            clipBehavior: Clip.antiAlias,
                                            child: Center(
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                                child: Text(priority.priorityName!),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                              },
                            ) : Container(
                              child: Text("No Priority Types Added", style: TextStyle(color: Colors.grey)),
                            ) : Container();
                          },
                        )
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height - 100,
            child: FutureBuilder(
              future: getServiceSQL(),
              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                return snapshot.connectionState == ConnectionState.done ? ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, i){
                      final service = Service.fromJson(snapshot.data![i]);
                      return Container(
                        padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
                        height: 200,
                        child: ElevatedButton(onPressed: () {
                          addTicketSQL(service.serviceType!,service.serviceCode!, (priorityType == "None" ? 0 : 1));
                        }, child: Padding(padding: EdgeInsets.all(20),
                        child: Text(service.serviceType!, style: TextStyle(fontSize: 80)))),
                      );
                    }) : Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      )
    );
  }

  colorHandler(String priority) {
    if (priority == priorityType) {
      return Colors.blueGrey;
    } else {
      return Colors.white70;
    }
  }


  toDateTime(DateTime date) {
    DateTime(date.year, date.month, date.day);
  }

  getTicketSQL(String serviceType) async {

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response.where((e) => e['status'] == "Pending" && toDateTime(DateTime.parse(e['timeCreated'])) == toDateTime(DateTime.now()) && e['serviceType'] == serviceType).toList();
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

  addTicketSQL(String serviceType, String serviceCode, int priority) async {

    final String timestamp = DateTime.now().toString();

    final List<Ticket> tickets =  await getTicketSQL(serviceType);
    final number = tickets.length + 1;
    final numberParsed = number.toString().padLeft(4, '0');
    print(numberParsed);

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');
      final body = {
        "timeCreated": timestamp,
        "number": numberParsed,
        "serviceCode": serviceCode,
        "serviceType": serviceType,
        "userAssigned": "",
        "stationName": "",
        "stationNumber": "",
        "timeTaken": "",
        "timeDone": "",
        "status": "Pending",
        "log": "$timestamp: ticketGenerated",
        "priority": priority,
        "priorityType": "$priorityType",
        "printStatus": 1,
        "callCheck": 0
      };

      final result = await http.post(uri, body: jsonEncode(body));
      print(result.body);


    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
    }
  }


  getServiceSQL() async {

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_service.php');

      final result = await http.get(uri);

      final response = jsonDecode(result.body);

      print("response1: $response");

      response.sort((a, b) => int.parse(a['id'].toString()).compareTo(int.parse(b['id'].toString())));

      print("response2: $response");

      return response;
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  getPriority() async {
    final uri = Uri.parse('http://$site/queueing_api/api_priorities.php');
    final result = await http.get(uri);
    final response = jsonDecode(result.body);
    return response;
  }
}
