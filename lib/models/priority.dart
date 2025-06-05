import 'dart:convert';

import 'package:http/http.dart' as http;

import '../globals.dart';

class Priority {
  int? id;
  String? priorityName;


  Priority.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.priorityName = data['priorityName'];

  }

  update(dynamic data) async {

    try {

      final body = {
        'id': data['id'] ?? this.id,
        'priorityName' : data['priorityName'] ?? this.priorityName,
      };

      final uri = Uri.parse('http://$site/queueing_api/api_priorities.php');

      final response = await http.put(uri, body: jsonEncode(body));

    } catch(e) {
      print(e);
    }
  }
}