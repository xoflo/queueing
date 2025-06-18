import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/media.dart';

final site = "192.168.1.154:8080";

// "localhost:8080"
// "192.168.1.154:8080"
stringToList(String text) {
  if (text != "") {
    String trimmed = text.substring(1, text.length - 1);
    List<String> parts = trimmed.split(',');
    List<String> result = parts.map((s) => s.trim().replaceAll('"', '')).toList();

    return result;
  } else {
    return [];
  }
}

logoBackground(BuildContext context, [int? width]) {
  return Stack(
    children: [MediaQuery.of(context).size.width > (width != null ? width : 1500)
        ? Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/logo.png'),
              SizedBox(height: 20),
              Text("Office of the Ombudsman", style: TextStyle(fontSize: 30), textAlign: TextAlign.center)
            ],
          )),
        )
        : Container(),
      Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: Colors.white70,
      ),
    ],
  );
}

getSettings(BuildContext context) async {
  try {
    final uri = Uri.parse('http://$site/queueing_api/api_controls.php');
    final result = await http.get(uri);
    final response = jsonDecode(result.body);
    return response;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Cannot connect to the server. Please try again.")));
    print(e);
    return [];
  }
}

getMedia(BuildContext context, String name) async {
  try {
    final uri = Uri.parse('http://$site/queueing_api/api_media.php');
    final result = await http.get(uri);
    List<dynamic> response = jsonDecode(result.body);
    final media = Media.fromJson(response.where((e) => e['name'] == name).toList()[0]);
    return media;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Cannot connect to the server. Please try again.")));
    print(e);
    return null;
  }
}

