import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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

  int port = 80;
  late Timer pingCheck;

  @override
  void initState() {
    pingCheck = Timer.periodic(Duration(seconds: 10), (timer) async {
      List<dynamic> result = await getStationSQL();
      final sorted = result.where((e) => e['sessionPing'] != "").toList();

      final List<Station> stations = [];

      for (int i = 0; i < sorted.length; i++) {
       stations.add(Station.fromJson(sorted[i]));
      }

      for (int i = 0; i < stations.length; i++) {
        if (DateTime.parse(stations[i].sessionPing!).difference(DateTime.now()).inSeconds < 5) {
          await stations[i].update({
            "inSession": 0,
            "sessionPing": "",
            "userInSession": ""
          });
        }
      }

    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 300,
                child: Image.asset('images/logo.png'),
              ),
              SizedBox(height: 50),
              Text("Ombudsman Queueing", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
              SizedBox(height: 20),
              Container(
                  width: 250,
                  child: TextField(
                    onSubmitted: (value) {
                      submit();
                    },
                    controller: username,
                    decoration: InputDecoration(
                      hintText: 'User'
                    ),
                  )),
              Container(
                  width: 250,
                  child: TextField(
                    obscureText: obscure,
                    controller: pass,
                    onSubmitted: (value) {
                      submit();
                    },
                    decoration: InputDecoration(
                        hintText: 'Password'
                    ),
                  )),
              IconButton(onPressed: () {
                obscure = !obscure;
                setState(() {

                });
              }, icon: obscure == true ? Icon(Icons.remove_red_eye): Icon(Icons.remove_red_eye_outlined)),
              SizedBox(height: 20),
              ElevatedButton(onPressed: () {
                submit();
              }, child: Text("Log-in")),

              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DisplayScreen()));
                  }, child: Text("Queue Display")),
                  SizedBox(width: 10),
                  ElevatedButton(onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ServicesScreen()));
                  }, child: Text("Queue Services")),
                ],
              ),




            ]
        ),
      )
    );
  }

  submit() async{

    try {

      final uri = Uri.parse('http://localhost:$port/queueing_api/api_user.php');
      final result = await http.get(uri);
      final users = jsonDecode(result.body);
      final sorted = users.where((e) => e['username'] == username.text && e['pass'] == pass.text).toList();
      print(sorted);


      if (sorted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No user found.")));

      } else {
        final user = User.fromJson(sorted[0]);

        if (user.userType == 'Admin') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen()));
        }

        if (user.userType == 'Staff') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => StaffScreen(user: user)));
        }

      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong.")));
    }

  }

  getStationSQL() async {

    try {

      final uri = Uri.parse('http://localhost:$port/queueing_api/api_station.php');

      final result = await http.get(uri);

      final response = jsonDecode(result.body);

      print('response: $response');

      return response;
    } catch(e) {
      print(e);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }
}