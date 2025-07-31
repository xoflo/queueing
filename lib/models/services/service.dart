import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../globals.dart';

class Service {
  int? id;
  String? serviceType;
  String? serviceCode;
  String? assignedGroup;
  String? timeCreated;
  int? displayIndex;
  DateTime? timeCreatedAsDate;


  Service.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.serviceType = data['serviceType'];
    this.serviceCode = data['serviceCode'];
    this.assignedGroup = data['assignedGroup'] == null || data['assignedGroup'] == "" ? null : data['assignedGroup'];
    this.timeCreated = data['timeCreated'];
    this.displayIndex = int.parse(data['displayIndex']);
    this.timeCreatedAsDate = data['timeCreated'] != null ? DateTime.parse(data['timeCreated']) : data['timeCreated'];

  }

  update(dynamic data) async {

    try {
      final body = {
        'id': data['id'] ?? this.id,
        'serviceType' : data['serviceType'] ?? this.serviceType,
        'serviceCode': data['serviceCode'] ?? this.serviceCode,
        'displayIndex': data['displayIndex'] ?? this.displayIndex,
        'assignedGroup': data['assignedGroup'] == null || data['assignedGroup'] == "" ? null : data['assignedGroup'],
      };

      final uri = Uri.parse('http://$site/queueing_api/api_service.php');

      final response = await http.put(uri, body: jsonEncode(body));

    } catch(e) {
      print(e);
    }
  }

  delete() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_service.php');
      final body = {
        'id': this.id,
      };

      final response = await http.delete(uri, body: jsonEncode(body));
    } catch(e) {
      print(e);
    }
  }

  selfDeleteWithoutGroup() async {
    List<dynamic> serviceGroups = await getServiceGroupSQL();
    List<String> existingGroups = [];

    for (int i = 0; i < serviceGroups.length; i++) {
      existingGroups.add(serviceGroups[i]['name']);
    }


    if (assignedGroup != "_MAIN_") {
      if (existingGroups.contains(assignedGroup) == false) {
        delete();
        return 0;
      } else {
        return 1;
      }
    } else {
      return 1;
    }

  }
}