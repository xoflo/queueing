import 'dart:convert';

import 'package:http/http.dart' as http;

class User {
  int? id;
  String? pass;
  String? userType;
  List<dynamic>? serviceType;
  String? username;


  User.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.pass = data['pass'];
    this.userType = data['userType'];
    this.serviceType = stringToList(data['serviceType']);
    this.username = data['username'];
  }

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

  update(dynamic data) async {
    try {

      final body = {
        'id': data['id'] ?? this.id,
        'pass' : data['pass'] ?? this.pass,
        'userType': data['userType'] ?? this.userType,
        'serviceType': data['serviceType'] ?? this.serviceType,
        'username': data['username'] ?? this.username,
      };

      final uri = Uri.parse('http://localhost:80/queueing_api/api_user.php');

      final response = await http.put(uri, body: jsonEncode(body));

    } catch(e) {
      print(e);
    }
  }
}