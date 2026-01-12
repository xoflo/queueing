import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:queueing/deviceInfo.dart';
import 'package:queueing/globals.dart';
import 'package:queueing/models/controls.dart';
import 'package:queueing/models/station.dart';
import 'package:queueing/screens/adminScreen.dart';
import 'package:queueing/screens/displayScreen.dart';
import 'package:queueing/screens/servicesScreen.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/screens/staffScreen.dart';

import 'models/user.dart';
import 'node.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.debug});

  final int debug;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController username = TextEditingController();
  TextEditingController pass = TextEditingController();
  bool obscure = true;

  @override
  void initState() {

    if (widget.debug == 1) {
      username.text = 'staff';
      pass.text = 'staff';
    }

    getIP();
  }

  @override
  Widget build(BuildContext context) {
    NodeSocketService().connect(context: context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                      BatteryWidget(),
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

                      widget.debug == 1 ? Row(
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
                      ) : SizedBox(),

                      //comment

                      /*

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
                      }, child: Text("Set IP")),

                       */


                      Text("v1.0.8", style: TextStyle(color: Colors.grey)),
                    ]
                ),
              ),
            ),
          )
        ],
      )
    );
  }

  submit() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final result = await http.get(uri);

      print(result.body);

      List<User> realUsers = [];

      final List<dynamic> users = jsonDecode(result.body);

      print(users);
      final List<dynamic> sorted = users.where((e) => e['username'] == username.text.trim() && e['pass'] == pass.text.trim()).toList();
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



          if (user.userType == 'Admin') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(user: user)));
          }

          if (user.userType == 'Staff') {
            final List<dynamic> stations = await _getStationSQL();
            final List<Control> controls = await _getControls();

            final value = controls.where((e) => e.controlName == 'One Session per User').toList()[0].value;


            if (value == 1) {
              final activeStations = stations.where((s) {
                final int inSession = s['inSession'] is int
                    ? s['inSession']
                    : int.parse(s['inSession'].toString());

                final String userInSession = s['userInSession'].toString();
                final String sessionPing = s['sessionPing'].toString();

                print('session: $sessionPing');


                return inSession == 1 &&
                    userInSession == user.username &&
                    sessionPing.isNotEmpty;
              }).toList();

              if (activeStations.isNotEmpty) {
                final timestamp = DateTime.parse(activeStations[0]['sessionPing']);
                final now = DateTime.now();

                if (now.difference(timestamp).inSeconds > 5) {

                  print("diffSec: ${now.difference(timestamp).inSeconds}");

                  final v = await _getVersion();

                  if (version == v) {
                    if (user.assignedStationId != 999) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => StaffSession(user: user, station: thisStation!)));
                    } else {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => StaffScreen(user: user)));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Old Version. Update Required.")));
                  }

                } else {

                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("This user is already in a session.")));
                  return;
                }

              }
            }

            final v = await _getVersion();

            if (version == v) {
              if (user.assignedStationId != 999) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => StaffSession(user: user, station: thisStation!)));
              } else {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => StaffScreen(user: user)));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Old Version. Update Required.")));
            }

          }



      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong. (${site == null || site == "" ? "No IP" : site})")));
      print(e);
    }
  }


  _getVersion() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_version.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);

      print(response);

      final ver = response[0]['version'].toString();

      print(ver);

      return ver;
    } catch (e) {
      print(e);
      return [];
    }
  }


  Future<List<Control>> _getControls() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_controls.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);

      List<Control> controls = [];

      for (int i = 0; i < response.length; i++) {
        controls.add(Control.fromJson(response[i]));
      }

      return controls;
    } catch (e) {
      print(e);
      return [];
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