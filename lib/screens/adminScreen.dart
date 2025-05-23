import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:queueing/screens/servicesScreen.dart';
import 'package:http/http.dart' as http;


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {

  int screenIndex = 0;

  TextEditingController serviceType = TextEditingController();
  TextEditingController serviceCode = TextEditingController();

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
                      tooltip: 'Tellers',
                      onPressed: (){
                        screenIndex = 2;
                        setState(() {});
                      }, icon: Icon(Icons.desktop_windows_rounded)),

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
      return "Tellers";
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
      return tellersView();
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

                      return ListTile(
                        title: Text("Service: $serviceType"),
                        subtitle: Text("Code: $serviceCode"),
                        trailing: IconButton(onPressed: () {
                          deleteService(i);
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

    final uri = Uri.parse('http://localhost:8080/queueing_api/api_service.php');
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
    final uri = Uri.parse('http://localhost:8080/queueing_api/api_service.php');
    final body = jsonEncode({'serviceType': "${serviceType.text}", 'serviceCode': "${serviceCode.text}"});

    final result = await http.post(uri, body: body);
    print("result: ${result.body}");


    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Service Added")));
    setState(() {

    });

  }

  getServiceSQL() async {
    final uri = Uri.parse('http://localhost:8080/queueing_api/api_service.php');

    final result = await http.get(uri);

    final response = jsonDecode(result.body);

    print("response1: $response");

    response.sort((a, b) => int.parse(a['id']).compareTo(int.parse(b['id'])));

    print("response2: $response");

    return response;

  }

  clearServiceFields() {
    serviceCode.clear();
    serviceType.clear();
  }


  usersView() {
    return Container(
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(onPressed: () {
                addService();
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
                      print("$i: ${snapshot.data![i]}");
                      final serviceType = snapshot.data![i]['serviceType'];
                      final serviceCode = snapshot.data![i]['serviceCode'];

                      return ListTile(
                        title: Text("Service: $serviceType"),
                        subtitle: Text("Code: $serviceCode"),
                        trailing: IconButton(onPressed: () {
                          deleteService(i);
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

  getUserSQL() async {
    final uri = Uri.parse('http://localhost:8080/queueing_api/api_user.php');

    final result = await http.get(uri);

    final response = jsonDecode(result.body);

    print("response1: $response");

    response.sort((a, b) => int.parse(a['id']).compareTo(int.parse(b['id'])));

    print("response2: $response");

    return response;

  }

  tellersView() {
    return Container(
      child: Column(
        children: [
          Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(onPressed: () {}, child: Text("+ Add Teller"))),

        ],
      ),
    );
  }
}
