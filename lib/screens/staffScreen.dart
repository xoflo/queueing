import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/models/station.dart';

import '../models/user.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key, required this.user});

  final User user;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {

  int port = 80;

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
                          onTap: () {

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

      final uri = Uri.parse('http://localhost:$port/queueing_api/api_station.php');

      final result = await http.get(uri);

      final response = jsonDecode(result.body);

      print("response1: $response");

      response.sort((a, b) => int.parse(a['id'].toString()).compareTo(int.parse(b['id'].toString())));

      print("response2: $response");

      return response;
    } catch(e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }
}
