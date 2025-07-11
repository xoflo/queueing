import 'dart:convert';

import 'package:http/http.dart' as http;

import '../globals.dart';

class Control {
  int? id;
  String? controlName;
  int? value;
  String? other;

  Control.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.controlName = data['controlName'];
    this.value = int.parse(data['value']);
    this.other = data['other'];

  }

  update(dynamic data) async {
    try {
      final body = {
        'id': data['id'] ?? this.id,
        'controlName' : data['controlName'] ?? this.controlName,
        'value': data['value'] ?? this.value,
        'other' : data['other'] ?? this.other,
      };

      final uri = Uri.parse('http://$site/queueing_api/api_controls.php');
      final response = await http.put(uri, body: jsonEncode(body));
    } catch(e) {
      print(e);
    }
  }
}