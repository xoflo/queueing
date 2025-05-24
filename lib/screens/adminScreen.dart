import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:queueing/models/service.dart';
import 'package:queueing/screens/servicesScreen.dart';
import 'package:http/http.dart' as http;

import '../models/station.dart';
import '../models/user.dart';


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {

  int screenIndex = 0;
  int port = 80;

  // Service

  TextEditingController serviceType = TextEditingController();
  TextEditingController serviceCode = TextEditingController();

  // Users

  TextEditingController user = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController userServiceType = TextEditingController();
  TextEditingController userType = TextEditingController();

  // Stations

  TextEditingController stationNumber = TextEditingController();
  TextEditingController stationName = TextEditingController();

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                spacing: 10,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(titleHandler(), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700))),

                  Spacer(),
                  IconButton(
                    color: colorHandler(screenIndex, 0),
                      tooltip: 'Services',
                      onPressed: () {
                      screenIndex = 0;
                      setState(() {});
                      }, icon: Icon(Icons.sticky_note_2)),
                  IconButton(
                      color: colorHandler(screenIndex, 1),
                      tooltip: 'Users',
                      onPressed: (){
                        screenIndex = 1;
                        setState(() {});
                      }, icon: Icon(Icons.supervised_user_circle_rounded)),
                  IconButton(
                      color: colorHandler(screenIndex, 2),
                      tooltip: 'Stations',
                      onPressed: (){
                        screenIndex = 2;
                        setState(() {});
                      }, icon: Icon(Icons.desktop_windows_rounded)),
                  IconButton(
                      tooltip: "Logout",
                      onPressed: () {
                    Navigator.pop(context);
                  }, icon: Icon(Icons.logout))

                ],
              ),
              Divider(),
              SizedBox(height: 10),
              screenHandler(screenIndex)
            ],
          ),
        ),
      ),
    );
  }

  titleHandler() {
    if (screenIndex == 0) {
      return "Services";
    }
    if (screenIndex == 1) {
      return "Users";
    }
    if (screenIndex == 2) {
      return "Stations";
    }
  }

  colorHandler(int i, int type) {
    if (i == type) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
  screenHandler(int i) {
    if (i == 0) {
      return servicesView();
    }

    if (i == 1) {
      return usersView();
    }

    if (i == 2) {
      return stationsView();
    }
  }

  servicesView() {
    return Container(
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(onPressed: () {
                addService();
              }, child: Text("+ Add Service"))),
          FutureBuilder(
            future: getServiceSQL(),
            builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? Container(
                padding: EdgeInsets.all(10),
                height: 400,
                child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, i) {
                      print("$i: ${snapshot.data![i]}");
                      final serviceType = snapshot.data![i]['serviceType'];
                      final serviceCode = snapshot.data![i]['serviceCode'];
                      final id = snapshot.data![i]['id'];

                      return ListTile(
                        title: Text("Service: $serviceType"),
                        subtitle: Text("Code: $serviceCode"),
                        trailing: IconButton(onPressed: () {
                          deleteService(id);
                        }, icon: Icon(Icons.delete)),
                      );
                    }),
              ) : Container(
                height: 400,
                child: Text("No services found", style: TextStyle(color: Colors.grey)),
              ) : Center(
                child: Container(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  deleteService(int i) async {

    final uri = Uri.parse('http://localhost:$port/queueing_api/api_service.php');
    final body = jsonEncode({'id': '$i'});

    final result = await http.delete(uri, body: body);

    print("result: ${result.body}");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Service Deleted")));
    setState(() {

    });

  }

  addService() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Add Service'),
      content: Container(
        height: 120,
        width: 250,
        child: Column(
          children: [
            Container(
                child: TextField(
                  controller: serviceType,
                  decoration: InputDecoration(
                    labelText: 'Service Type',
                  ),
                )),

            Container(
                child: TextField(
                  controller: serviceCode,
                  decoration: InputDecoration(
                    labelText: 'Service Code'
                  ),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () {
          addServiceSQL();
          clearServiceFields();
        }, child: Text("Add Service"))
      ],
    ));
  }

  addServiceSQL() async {
    final uri = Uri.parse('http://localhost:$port/queueing_api/api_service.php');
    final body = jsonEncode({'serviceType': "${serviceType.text[0].toUpperCase() + serviceType.text.substring(1).toLowerCase()}", 'serviceCode': "${serviceCode.text}"});

    final result = await http.post(uri, body: body);
    print("result: ${result.body}");


    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Service Added")));
    setState(() {

    });

  }

  getServiceSQL() async {
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

  clearServiceFields() {
    serviceCode.clear();
    serviceType.clear();
  }

  clearUserFields() {
    user.clear();
    password.clear();
    userServiceType.clear();
    userType.clear();
  }

  clearStationFields() {
    stationName.clear();
    stationNumber.clear();
  }


  usersView() {
    return Container(
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(onPressed: () {
                addUser();
              }, child: Text("+ Add User"))),
          FutureBuilder(
            future: getUserSQL(),
            builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? Container(
                padding: EdgeInsets.all(10),
                height: 400,
                child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, i) {
                      final user = User.fromJson(snapshot.data![i]);

                      return ListTile(
                        title: Text("${user.username}"),
                        subtitle: Text("Service: ${user.serviceType} | Authority: ${user.userType}"),
                        trailing: IconButton(onPressed: () {
                          deleteUser(user.id!);
                        }, icon: Icon(Icons.delete)),
                      );
                    }),
              ) : Container(
                height: 400,
                child: Text("No users found", style: TextStyle(color: Colors.grey)),
              ) : Center(
                child: Container(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  getUserSQL([String? userType, String? serviceType]) async {

    try {

      final uri = Uri.parse('http://localhost:$port/queueing_api/api_user.php');

      final result = await http.get(uri);

      final response = jsonDecode(result.body);

      print("response1: $response");

      dynamic newResult = response;

      if (userType != null) {
        newResult = newResult.where((e) => e['userType'] == 'Staff').toList();
      }

      if (serviceType != null) {
        newResult = newResult.where((e) => e['serviceType'] == serviceType).toList();
      }

      return newResult;

    } catch(e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }

  addUser() {
    bool obscure = true;

    String userType = "Admin";
    String display = "Select";

    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Add User'),
      content: StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setStateDialog) {
          return Container(
            height: 220,
            width: 250,
            child: Column(
              children: [
                Container(
                    child: TextField(
                      controller: user,
                      decoration: InputDecoration(
                        labelText: 'Username',
                      ),
                    )),

                Container(
                    child: Row(
                      children: [
                        Container(
                          width: 210,
                          child: TextField(
                            obscureText: obscure,
                            controller: password,
                            decoration: InputDecoration(
                                labelText: 'Password'
                            ),
                          ),
                        ),
                        IconButton(onPressed: () {
                          obscure = !obscure;
                          setStateDialog(() {

                          });
                        }, icon: Icon(obscure == true ? Icons.remove_red_eye: Icons.remove_red_eye_outlined))
                      ],
                    )),

                userType == 'Staff' ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListTile(
                    title: Text("Service Type: $display"),
                      onTap: () {
                        showDialog(context: context, builder: (_) => AlertDialog(
                          content: Container(
                            height: 400,
                            width: 300,
                            child: FutureBuilder(
                              future: getServiceSQL(),
                              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                                List<String> services = [];
                                return snapshot.connectionState == ConnectionState.done ? StatefulBuilder(
                                  builder: (BuildContext context, void Function(void Function()) setStateList) {
                                    return ListView.builder(
                                        itemCount: snapshot.data!.length,
                                        itemBuilder: (context, i) {
                                          final user = Service.fromJson(snapshot.data![i]);
                                          return CheckboxListTile(
                                              title: Text(user.serviceType!),
                                              value: services.contains(user.serviceType!),
                                              onChanged: (value) {
                                                if (value == true) {
                                                  services.add(user.serviceType!);
                                                  setStateList((){});
                                                }
                                              });
                                        });
                                  },
                                ) : Center(
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
                        ));
                      }

                  ),
                ) : Container(
                  height: 20,
                ),

                Row(
                  spacing: 5,
                  children: [
                    GestureDetector(
                        onTap: () {
                          userType = "Admin";
                          setStateDialog((){

                          });
                        },
                        child: Container(
                          height: 50,
                          width: 100,
                          child: Card(
                            child: Center(
                              child: Text("Admin"),
                            ),
                            color: userType == "Admin" ? Colors.redAccent : Colors.white,

                          ),
                        )),
                    GestureDetector(
                        onTap: () {
                          userType = "Staff";
                          setStateDialog((){

                          });
                        },
                        child: Container(
                          height: 50,
                          width: 100,
                          child: Card(
                            child: Center(
                              child: Text("Staff"),
                            ),
                            color: userType == "Staff" ? Colors.redAccent : Colors.white,

                          ),
                        ))
                  ],
                )
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () {
          try {
            addUserSQL(display, userType);
          } catch(e) {
            print(e);
          }
          clearUserFields();
        }, child: Text("Add User"))
      ],
    ));
  }

  addUserSQL(String serviceType, String userType) async {
    final uri = Uri.parse('http://localhost:$port/queueing_api/api_user.php');
    final body = jsonEncode({
        "username": "${user.text}",
        "pass": "${password.text}",
        "serviceType": "${serviceType}",
        "userType": "${userType}"
    });

    final result = await http.post(uri, body: body);
    print("result: ${result.body}");


    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Added")));
    setState(() {

    });

  }


  deleteUser(int i) async {

    final uri = Uri.parse('http://localhost:$port/queueing_api/api_user.php');
    final body = jsonEncode({'id': '$i'});

    final result = await http.delete(uri, body: body);

    print("result: ${result.body}");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Deleted")));
    setState(() {

    });

  }



  stationsView() {
    return Container(
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(onPressed: () {
                addStation();
              }, child: Text("+ Add Station"))),
          FutureBuilder(
            future: getStationSQL(),
            builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? Container(
                padding: EdgeInsets.all(10),
                height: 400,
                child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, i) {
                      final station = Station.fromJson(snapshot.data![i]);

                      return ListTile(
                        title: Text("${station.stationName} #${station.stationNumber} ${station.userInSession == "" ? "| Unassigned" : "| Assigned: ${station.userInSession}"}"),
                        subtitle: Text("${station.serviceType} | ${station.inSession == 1 ? "In Session": "Inactive"}"),
                        trailing: IconButton(onPressed: () {
                          deleteStation(station.id!);
                        }, icon: Icon(Icons.delete)),
                        onTap: () {
                        },
                      );
                    }),
              ) : Container(
                height: 400,
                child: Text("No stations found", style: TextStyle(color: Colors.grey)),
              ) : Center(
                child: Container(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  assignStaff(Station station) {

    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text("Assign Staff (${station.serviceType})"),
      content: FutureBuilder(
        future: getUserSQL('Staff', station.serviceType),
        builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          return Container(
            height: 400,
            width: 300,
            child: snapshot.connectionState == ConnectionState.done ? ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, i) {
                  final name = snapshot.data![i]['username'];

                  return ListTile(
                    title: Text(name),
                    onTap: () async {
                      await station.update({
                        'userInSession': "$name",
                      });

                      setState(() {

                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User assigned")));
                      Navigator.pop(context);
                    },
                  );
                }) : Center(
              child: Container(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              ),
            ),
          );
        },
      ),
    ));
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


  addStation() {
    String display = "Select";

    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Add Station'),
      content: StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setStateDialog) {
          return Container(
            height: 180,
            width: 250,
            child: Column(
              children: [
                Container(
                    child: TextField(
                      controller: stationName,
                      decoration: InputDecoration(
                        labelText: 'Station Name',
                      ),
                    )),

                Container(
                    child: TextField(
                      controller: stationNumber,
                      decoration: InputDecoration(
                          labelText: 'Station Number'
                      ),
                    )),

                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListTile(
                      title: Text("Service Type: $display"),
                      onTap: () {
                        showDialog(context: context, builder: (_) => AlertDialog(
                          content: Container(
                            height: 300,
                            width: 200,
                            child: FutureBuilder(
                              future: getServiceSQL(),
                              builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                                return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? Container(
                                  height: 300,
                                  width: 200,
                                  child: ListView.builder(
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, i) {
                                        final name = snapshot.data![i]['serviceType'];

                                        return ListTile(
                                          title: Text(name),
                                          onTap: () {
                                            Navigator.pop(context);
                                            display = name;
                                            setStateDialog((){});
                                          },
                                        );
                                      }),

                                ) : Text("No Services Found", style: TextStyle(color: Colors.grey)) : Container(
                                  height: 100,
                                  width: 100,
                                  child: CircularProgressIndicator(
                                    color: Colors.blue,
                                  ),
                                );
                              },
                            ),
                          ),
                        ));
                      }

                  ),
                ),

              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () {
          try {
            addStationSQL(display);
          } catch(e) {
            print(e);
          }
          clearUserFields();
        }, child: Text("Add Station"))
      ],
    ));
  }

  addStationSQL(String serviceType) async {
    final uri = Uri.parse('http://localhost:$port/queueing_api/api_station.php');
    final body = jsonEncode({
      "stationNumber": "${stationNumber.text}",
      "stationName": "${stationName.text[0].toUpperCase() + stationName.text.substring(1).toLowerCase()}",
      "serviceType": serviceType,
      "inSession": 0,
      "userInSession": "",
      "ticketServing": "",
    });

    print("serviceType: $serviceType");

    final result = await http.post(uri, body: body);
    print("result: ${result.body}");


    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Station Added")));
    setState(() {

    });

  }


  deleteStation(int i) async {

    final uri = Uri.parse('http://localhost:$port/queueing_api/api_station.php');
    final body = jsonEncode({'id': '$i'});

    final result = await http.delete(uri, body: body);

    print("result: ${result.body}");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Deleted")));
    setState(() {

    });

  }

}


