import 'dart:convert';
import 'package:http/http.dart' as http;
import '../globals.dart';

class Userlog {
  int? id;
  String? timestamp;
  int? state;
  String? user;
  int? userId;


  Userlog.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.timestamp = data['timestamp'];
    this.state = int.parse(data['state']);
    this.user = data['user'];
    this.userId = int.parse(data['userId']);

  }

}