import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';

class User {
  int? id;
  String? pass;
  String? userType;
  List<dynamic>? serviceType;
  String? username;
  DateTime? loggedIn;
  List<dynamic>? servicesSet;


  User.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.pass = data['pass'];
    this.userType = data['userType'];
    this.serviceType = stringToList(data['serviceType']);
    this.username = data['username'];
    this.loggedIn = data['loggedIn'] != null ? DateTime.parse(data['loggedIn']) : null;
    this.servicesSet = data['servicesSet'] != null ? stringToList(data['servicesSet'].toString()) : null;
  }

  update(dynamic data) async {
    try {
      final body = {
        'id': data['id'] ?? this.id,
        'pass' : data['pass'] ?? this.pass,
        'userType': data['userType'] ?? this.userType,
        'serviceType': data['serviceType'] ?? this.serviceType.toString(),
        'username': data['username'] ?? this.username,
        'loggedIn': data['loggedIn'] ?? this.loggedIn.toString(),
        'servicesSet': data['servicesSet'] ?? this.servicesSet.toString(),
      };

      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final response = await http.put(uri, body: jsonEncode(body));
    } catch(e) {
      print(e);
    }
  }
}