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
      body: MediaQuery.of(context).size.width < 350 || MediaQuery.of(context).size.height < 550 ? Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Center(child: Text("Expand Screen Size to Display", style: TextStyle(fontSize: 30))),
      ) : Center(
        child: SingleChildScrollView(
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
                  width: 300,
                  padding: EdgeInsets.all(5),
                  child: ElevatedButton(onPressed: () {
                    submit();
                  }, child: Text("Log-in")),
                ),
          
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
        ),
      )
    );
  }

  submit() async{
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final result = await http.get(uri);
      final users = jsonDecode(result.body);
      final sorted = users.where((e) => e['username'] == username.text.trim() && e['pass'] == pass.text.trim()).toList();
      if (sorted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No user found.")));
      } else {
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