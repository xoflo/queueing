import 'package:flutter/material.dart';
import 'package:queueing/screens/adminScreen.dart';
import 'package:queueing/screens/displayScreen.dart';
import 'package:queueing/screens/servicesScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Ombudsman Queueing", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
              SizedBox(height: 20),
              Container(
                  width: 250,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'User'
                    ),
                  )),
              Container(
                  width: 250,
                  child: TextField(
                    decoration: InputDecoration(
                        hintText: 'Password'
                    ),
                  )),
              SizedBox(height: 20),
              ElevatedButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AdminScreen()));
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
}