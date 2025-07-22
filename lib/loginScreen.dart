import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:queueing/globals.dart';
import 'package:queueing/models/station.dart';
import 'package:queueing/screens/adminScreen.dart';
import 'package:queueing/screens/displayScreen.dart';
import 'package:queueing/screens/servicesScreen.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/screens/staffScreen.dart';

import 'models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController username = TextEditingController();
  TextEditingController pass = TextEditingController();
  bool obscure = true;

  @override
  void initState() {
    getIP();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill,
              image: Image.asset('images/background.jpg').image),
        ),
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 25),
                  Container(
                    height: MediaQuery.of(context).size.width < 400 ? 150 : 300,
                    child: Image.asset('images/logo.png'),
                  ),
                  SizedBox(height: 25),
                  Center(child: Text("Office of the Ombudsman", style: TextStyle(fontFamily: 'BebasNeue' ,fontSize: 60, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                  Center(child: Text("Queueing App", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                  SizedBox(height: 20),
                  Container(
                      width: 300,
                      child: TextField(
                        onSubmitted: (value) {
                          submit();
                        },
                        controller: username,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)
                            ),
                            hintText: 'User'
                        ),
                      )),
                  SizedBox(height: 10),
                  Container(
                      width: 300,
                      child: TextField(
                        obscureText: obscure,
                        controller: pass,
                        onSubmitted: (value) {
                          submit();
                        },
                        decoration: InputDecoration(
                          hintText: 'Password',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)
                          ),
                        ),
                      )),
                  IconButton(onPressed: () {
                    obscure = !obscure;
                    setState(() {

                    });
                  }, icon: obscure == true ? Icon(Icons.remove_red_eye): Icon(Icons.remove_red_eye_outlined)),
                  SizedBox(height: 10),
                  Container(
                    height: 50,
                    width: 300,
                    padding: EdgeInsets.all(5),
                    child: ElevatedButton(
                        onPressed: () {
                      submit();
                    }, child: Text("Log-in")),
                  ),

                  SizedBox(height: 10),

                  // comment
                  /*

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        child: ElevatedButton(onPressed: () async {
                          try {
                            final uri = Uri.parse('http://$site/queueing_api/api_controls.php');
                            final result = await http.get(uri);

                            print(result.headers);

                            if (result.statusCode == 200) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => DisplayScreen()));
                            }
                          } catch(e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server not found.")));
                          }
                        }, child: Text("Queue Screen")),
                      ),
                      SizedBox(width: 10),
                      Container(
                        height: 40,
                        child: ElevatedButton(onPressed: () async {
                          try {
                            final uri = Uri.parse('http://$site/queueing_api/api_controls.php');
                            final result = await http.get(uri);

                            if (result.statusCode == 200) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ServicesScreen()));
                            }
                          } catch(e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server not found.")));
                          }

                        }, child: Text("Services Kiosk")),
                      ),
                    ],
                  ),
                   */
                   //comment
                  SizedBox(height: 10),
                  TextButton(onPressed: () async {
                    TextEditingController ip = TextEditingController();
                    ip.text = site ?? "";

                    showDialog(context: context, builder: (_) => AlertDialog(
                      title: Text("Set Database IP"),
                      content: Container(
                        height: 60,
                        child: Column(
                          children: [
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'IP Address'
                              ),
                              controller: ip,
                            )
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () async {
                          await saveIP(ip.text);
                          await getIP();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("IP Set to '$site'")));
                          Navigator.pop(context);
                        }, child: Text("Set"))
                      ],
                    ));
                  }, child: Text("Set IP"))

                ]
            ),
          ),
        ),
      )
    );
  }

  submit() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final result = await http.get(uri);
      final users = jsonDecode(result.body);
      final sorted = users.where((e) => e['username'] == username.text.trim() && e['pass'] == pass.text.trim()).toList();
      if (sorted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No user found.")));
      } else {
        User user = User.fromJson(sorted[0]);
        final List<dynamic> stations = await _getStationSQL();
        final userStation = stations.where((e) => int.parse(e['id']) == user.assignedStationId).toList();
        Station? thisStation;

        if (userStation.isNotEmpty) {
          final Station station = Station.fromJson(userStation[0]);
          thisStation = station;
          user.update({
            'assignedStation': "${station.nameAndNumber}_${station.id}"
          });
        } else {
          user.update({
            'assignedStation': "All_999"
          });
        }


        if (user.loggedIn == null || user.loggedIn!.difference(DateTime.now()).inSeconds < -3) {
          if (user.userType == 'Admin') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(user: user)));
          }
          if (user.userType == 'Staff') {
            if (user.assignedStationId != 999) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => StaffSession(user: user, station: thisStation!)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => StaffScreen(user: user)));
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("This user is currently logged-in")));
        }

      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong. (${site == null || site == "" ? "No IP" : site})")));
      print(e);
    }
  }

  Future<List<dynamic>> _getStationSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_station.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);
      response.sort((a, b) => int.parse(a['id'].toString())
          .compareTo(int.parse(b['id'].toString())));

      response.sort((a, b) => int.parse(a['displayIndex'].toString())
          .compareTo(int.parse(b['displayIndex'].toString())));

      return response;
    } catch (e) {
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
    } catch(e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }
}