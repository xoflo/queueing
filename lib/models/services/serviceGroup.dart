
import 'package:queueing/models/services/service.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../globals.dart';

class ServiceGroup {
  int? id;
  String? name;
  String? assignedGroup;


  ServiceGroup.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.name = data['name'];
    this.assignedGroup = data['assignedGroup'];
  }

  update(dynamic data) async {

    try {

      final body = {
        'id': data['id'] ?? this.id,
        'name' : data['name'] ?? this.name,
        'assignedGroup': data['assignedGroup'] ?? this.assignedGroup,
      };

      final uri = Uri.parse('http://$site/queueing_api/api_serviceGroup.php');

      final response = await http.put(uri, body: jsonEncode(body));

    } catch(e) {
      print(e);
    }
  }
}