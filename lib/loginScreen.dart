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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
                fit: BoxFit.fill,
                image: Image.asset('images/background.jpg').image),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 25),
                Container(
                  height: MediaQuery.of(context).size.width < 400 ? 150 : 300,
                  child: Image.asset('images/logo.png'),
                ),
                SizedBox(height: 25),
                Center(child: Text("Office of the Ombudsman", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 40,
                      child: ElevatedButton(onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DisplayScreen()));
                      }, child: Text("Queue Screen")),
                    ),
                    SizedBox(width: 10),
                    Container(
                      height: 40,
                      child: ElevatedButton(onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ServicesScreen()));
                      }, child: Text("Services Kiosk")),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                TextButton(onPressed: () async {
                  TextEditingController ip = TextEditingController();
                  ip.text = await getIP();

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
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("IP Set to '${site}'")));
                      }, child: Text("Set"))
                    ],
                  ));
                }, child: Text("Set IP"))

              ]
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
        print(sorted[0]);
        final user = User.fromJson(sorted[0]);


        if (user.loggedIn == null || user.loggedIn!.difference(DateTime.now()).inSeconds < -3) {
          if (user.userType == 'Admin') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen(user: user)));
          }
          if (user.userType == 'Staff') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => StaffScreen(user: user)));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("This user is currently logged-in")));
        }

      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Something went wrong.")));
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