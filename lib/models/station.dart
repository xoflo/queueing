import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';

class Station {
  int? id;
  int? stationNumber;
  int? inSession;
  String? userInSession;
  String? ticketServing;
  String? stationName;
  String? sessionPing;


  Station.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.stationNumber = int.parse(data['stationNumber']);
    this.inSession = int.parse(data['inSession']);
    this.userInSession = data['userInSession'];
    this.ticketServing = data['ticketServing'];
    this.stationName = data['stationName'];
    this.sessionPing = data['sessionPing'];
  }

  update(dynamic data) async {

    int port = 80;

    try {

      final body = {
        'id': data['id'] ?? this.id,
        'stationNumber' : data['stationNumber'] ?? this.stationNumber,
        'inSession': data['inSession'] ?? this.inSession,
        'userInSession': data['userInSession'] ?? this.userInSession,
        'ticketServing': data['ticketServing'] ?? this.ticketServing,
        'stationName': data['stationName'] ?? this.stationName,
        'sessionPing': data['sessionPing'] ?? this.sessionPing
      };


      inSession = int.parse(data['inSession'].toString());
      userInSession = data['userInSession'] ?? userInSession;
      sessionPing = data['sessionPing']  ?? sessionPing;

      final uri = Uri.parse('http://$site/queueing_api/api_station.php');

      final response = await http.put(uri, body: jsonEncode(body));

    } catch(e) {
      print(e);
    }
  }
}