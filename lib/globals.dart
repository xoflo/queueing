import 'package:flutter/material.dart';

final site = "192.168.1.38:8080";

// "localhost:8080"
// "192.168.1.154:8080"

logoBackground(BuildContext context) {
  return Opacity(
    opacity: 0.2,
    child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('logo.png'),
            SizedBox(height: 20),
            Text("Office of the Ombudsman", style: TextStyle(fontSize: 30))
          ],
        )),
  );
}