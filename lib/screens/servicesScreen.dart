import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:queueing/models/service.dart';
import 'package:queueing/screens/adminScreen.dart';
import 'package:http/http.dart' as http;

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {

  int port = 80;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: FutureBuilder(
          future: getServiceSQL(),
          builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            return snapshot.connectionState == ConnectionState.done ? ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, i){
                  final service = Service.fromJson(snapshot.data![i]);
                  return Container(
                    padding: EdgeInsets.fromLTRB(50, 10, 50, 10),
                    height: 250,
                    child: ElevatedButton(onPressed: () {
                      addTicketSQL(service.serviceType!, 0);
                    }, child: Text(service.serviceType!, style: TextStyle(fontSize: 100))),
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
      )
    );
  }

  addTicketSQL(String serviceType, int priority) async {
    int port = 80;

    final String timestamp = DateTime.now().toString();

    try {
      final uri = Uri.parse('http://localhost:$port/queueing_api/api_ticket.php');
      final body = {
        "timeCreated": timestamp,
        "number": 0,
        "serviceType": serviceType,
        "userAssigned": "",
        "stationNumber": "",
        "timeTaken": "",
        "timeDone": "",
        "status": "Pending",
        "log": "$timestamp: ticketGenerated",
        "priority": priority,
        "priorityType": "",
        "printStatus": 1
      };

      final result = await http.post(uri, body: jsonEncode(body));
      print(result.body);


    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
    }
  }


  getServiceSQL() async {
    int port = 80;

    try {
      final uri = Uri.parse('http://localhost:$port/queueing_api/api_service.php');

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
}
