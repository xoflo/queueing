import 'dart:convert';

import 'package:http/http.dart' as http;

class Station {
  int? id;
  int? stationNumber;
  int? inSession;
  String? userInSession;
  String? serviceType;
  String? ticketServing;
  String? stationName;


  Station.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.stationNumber = int.parse(data['stationNumber']);
    this.inSession = int.parse(data['inSession']);
    this.userInSession = data['userInSession'];
    this.serviceType = data['serviceType'];
    this.ticketServing = data['ticketServing'];
    this.stationName = data['stationName'];
  }

  update(dynamic data) async {
    try {

      final body = {
        'id': data['id'] ?? this.id,
        'stationNumber' : data['stationNumber'] ?? this.stationNumber,
        'inSession': data['inSession'] ?? this.inSession,
        'userInSession': data['userInSession'] ?? this.userInSession,
        'serviceType': data['serviceType'] ?? this.serviceType,
        'ticketServing': data['ticketServing'] ?? this.ticketServing,
        'stationName': data['stationName'] ?? this.stationName
      };

      final uri = Uri.parse('http://localhost:80/queueing_api/api_station.php');

      final response = await http.put(uri, body: jsonEncode(body));

    } catch(e) {
      print(e);
    }
  }
}