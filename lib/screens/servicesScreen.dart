import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:queueing/globals.dart';
import 'package:queueing/models/services/service.dart';
import 'package:queueing/models/services/serviceGroup.dart';
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

  List<String> lastAssigned = [];
  String assignedGroup = "_MAIN_";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        logoBackground(context),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Please select a service"),
            StatefulBuilder(
              builder: (BuildContext context,
                  void Function(void Function()) setStateList) {
                return FutureBuilder(
                  future: getServiceGroups(assignedGroup),
                  builder: (BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    return Column(
                      children: [
                        lastAssigned.isNotEmpty
                            ? TextButton(
                                onPressed: () {
                                  assignedGroup = lastAssigned.last;
                                  lastAssigned.removeLast();
                                  setStateList((){});
                                },
                                child: Text("Return"))
                            : Container(),
                        snapshot.connectionState == ConnectionState.done
                            ? Container(
                              height: MediaQuery.of(context).size.height - 100,
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 5 : 3),
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, i) {
                                      return snapshot.data![i]['serviceType'] !=
                                              null
                                          ? Builder(builder: (context) {
                                              final service = Service.fromJson(
                                                  snapshot.data![i]);
                                              return GestureDetector(
                                                onTap: () {
                                                  priorityDialog(service);
                                                },
                                                child: Card(
                                                  child:
                                                      Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text(service.serviceType!),
                                                        ],
                                                      ),
                                                ),
                                              );
                                            })
                                          : Builder(builder: (context) {
                                              final group = ServiceGroup.fromJson(
                                                  snapshot.data![i]);
                                              return GestureDetector(
                                                onTap: () {
                                                  lastAssigned.add(assignedGroup);
                                                  assignedGroup = group.name!;
                                                  setStateList((){});
                                                },
                                                child: Card(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(group.name!),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            });
                                    }),
                              ),
                            )
                            : Center(
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  child: CircularProgressIndicator(
                                    color: Colors.blue,
                                  ),
                                ),
                              )
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    ));
  }

  nameDialog(Service service, String priorityType) {
    TextEditingController name = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(""),
      content: Container(
        height: 100,
        width: 100,
        child: TextField(
          controller: name,
          decoration: InputDecoration(
            labelText: "Name")
          )
        ),
      actions: [
        TextButton(onPressed: () {
          addTicketSQL(service.serviceType!, service.serviceCode!, priorityType, name.text);
        }, child: Text(""
            "Submit"))
      ],
      ),
    );

  }

  priorityDialog(Service service) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text("Select priorities (if applicable)"),
      content: FutureBuilder(
        future: getPriority(),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? Container(
            height: 400,
            width: 400,
            child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, i) {
                  final priority = Priority.fromJson(snapshot.data![i]);
                  return GestureDetector(
                    onTap: () {

                      addTicketSQL(service.serviceType!,service.serviceCode!, priority.priorityName!);
                    },
                    child: Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(priority.priorityName!)
                        ],
                      ),
                    ),
                  );

            }),
          ) : Container(
            height: 300,
            child: Center(
              child: Text(
                "No Priorites added.",style: TextStyle(color: Colors.grey),
              ),
            ),
          ) : Container(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    ));
  }


  toDateTime(DateTime date) {
    DateTime(date.year, date.month, date.day);
  }

  getTicketSQL(String serviceType) async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response
          .where((e) =>
              e['status'] == "Pending" &&
              toDateTime(DateTime.parse(e['timeCreated'])) ==
                  toDateTime(DateTime.now()) &&
              e['serviceType'] == serviceType)
          .toList();
      List<Ticket> newTickets = [];

      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a, b) => DateTime.parse(a.timeCreated!)
          .compareTo(DateTime.parse(b.timeCreated!)));

      return newTickets;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  addTicketSQL(String serviceType, String serviceCode, String priorityType, [String? ticketName]) async {
    final String timestamp = DateTime.now().toString();

    final List<Ticket> tickets = await getTicketSQL(serviceType);
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
        "priority": priorityType != "None" ? 1 : 0,
        "priorityType": "$priorityType",
        "printStatus": 1,
        "callCheck": 0,
        "ticketName": ticketName ?? ""
      };

      final result = await http.post(uri, body: jsonEncode(body));
      print(result.body);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket Created Successfully")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));

      print(e);
    }
  }

  getServiceGroups(String assignedGroup) async {
    try {
      final uriGroup =
          Uri.parse('http://$site/queueing_api/api_serviceGroup.php');
      final resultGroup = await http.get(uriGroup);
      List<dynamic> responseGroup = jsonDecode(resultGroup.body);

      final uriService = Uri.parse('http://$site/queueing_api/api_service.php');
      final resultService = await http.get(uriService);
      List<dynamic> responseService = jsonDecode(resultService.body);

      print(responseService);
      print(responseGroup);

      List<dynamic> resultsToReturn = [];

      for (int i = 0; i < responseGroup.length; i++) {
        if (responseGroup[i]['assignedGroup'] == assignedGroup) {
          resultsToReturn.add(responseGroup[i]);
        }
      }

      for (int i = 0; i < responseService.length; i++) {
        if (responseService[i]['assignedGroup'] == assignedGroup) {
          resultsToReturn.add(responseService[i]);
        }
      }
      print('return: $resultsToReturn');

      return resultsToReturn;
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  getPriority() async {
    final uri = Uri.parse('http://$site/queueing_api/api_priorities.php');
    final result = await http.get(uri);
    List<dynamic> response = jsonDecode(result.body);
    response.add({"priorityName": "None", "id": 999.toString()});
    return response;
  }
}
