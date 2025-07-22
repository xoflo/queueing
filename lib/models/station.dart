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
  int? displayIndex;
  String? nameAndNumber;

  Station.fromJson(dynamic data) {
    id = int.parse(data['id']);
    stationNumber = data['stationNumber'] != null ? int.parse(data['stationNumber'].toString()) : data['stationNumber'];
    inSession = data['inSession'] != null ? int.parse(data['inSession'].toString()) : 0;
    userInSession = data['userInSession'];
    ticketServing = data['ticketServing'];
    stationName = data['stationName'];
    sessionPing = data['sessionPing'];
    displayIndex = data['displayIndex'] != null ? int.parse(data['displayIndex'].toString()) : data['displayIndex'];

    nameAndNumber = "${stationName}${stationNumber == 0 ? "" : " $stationNumber"}";
  }

  update(dynamic data) async {
    try {
      final body = {
        'id': data['id'] ?? id,
        'stationNumber' : data['stationNumber'] ?? stationNumber,
        'inSession': data['inSession'] ?? inSession,
        'userInSession': data['userInSession'] ?? userInSession,
        'ticketServing': data['ticketServing'] ?? ticketServing,
        'stationName': data['stationName'] ?? stationName,
        'sessionPing': data['sessionPing'] ?? sessionPing,
        'displayIndex' : data['displayIndex'] ?? stationNumber,
      };

      stationNumber = data['stationNumber'] ?? stationNumber;
      stationName = data['stationName'] ?? stationName;
      inSession = data['inSession'] != null ? int.parse(data['inSession'].toString()) : inSession;
      userInSession = data['userInSession'] ?? userInSession;
      sessionPing = data['sessionPing']  ?? sessionPing;
      displayIndex = data['displayIndex'] ?? displayIndex;
      ticketServing = data['ticketServing'] ?? ticketServing;

      nameAndNumber = "${stationName}${stationNumber == 0 ? "" : " $stationNumber"}";

      final uri = Uri.parse('http://$site/queueing_api/api_station.php');
      final response = await http.put(uri, body: jsonEncode(body));
      return;
    } catch(e) {
      print(e);
      return;
    }
  }
}