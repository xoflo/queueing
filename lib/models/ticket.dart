import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';
import 'package:flutter/material.dart';

class Ticket {
  int? id;
  String? timeCreated;
  String? number;
  String? serviceCode;
  String? serviceType;
  String? userAssigned;
  String? stationName;
  int? stationNumber;
  String? timeTaken;
  String? timeDone;
  String? status;
  String? log;
  int? priority;
  String? priorityType;
  int? printStatus;
  int? callCheck;
  String? ticketName;

  String? codeAndNumber;

  Ticket.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.timeCreated = data['timeCreated'];
    this.number = data['number'];
    this.serviceCode = data['serviceCode'];
    this.serviceType = data['serviceType'];
    this.userAssigned = data['userAssigned'];
    this.stationName = data['stationName'];
    this.stationNumber = int.parse(data['stationNumber']);
    this.timeTaken = data['timeTaken'];
    this.timeDone = data['timeDone'];
    this.status = data['status'];
    this.log = data['log'];
    this.priority = int.parse(data['priority']);
    this.priorityType = data['priorityType'];
    this.printStatus = int.parse(data['printStatus']);
    this.callCheck = int.parse(data['callCheck']);
    this.ticketName = data['ticketName'];
    this.codeAndNumber = "${data['serviceCode']}${data['number']}";
  }

  update(dynamic data) async {

    try {

      final body = {
        'id': data['id'] ?? this.id,
        'timeCreated': data['timeCreated'] ?? this.timeCreated,
        'number': data['number'] ?? this.number,
        'serviceCode': data['serviceCode'] ?? this.serviceCode,
        'serviceType': data['serviceType'] ?? this.serviceType,
        'userAssigned': data['userAssigned'] ?? this.userAssigned,
        'stationName': data['stationName'] ?? this.stationName,
        'stationNumber': data['stationNumber'] ?? this.stationNumber,
        'timeTaken': data['timeTaken'] ?? this.timeTaken,
        'timeDone': data['timeDone'] ?? this.timeDone,
        'status': data['status'] ?? this.status,
        'log': data['log'] ?? this.log,
        'priority': data['priority'] ?? this.priority,
        'priorityType': data['priorityType'] ?? this.priorityType,
        'printStatus': data['printStatus'] ?? this.printStatus,
        'callCheck': data['callCheck'] ?? this.callCheck,
        'ticketName': data['ticketName'] ?? this.ticketName,
      };
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');
      final response = await http.put(uri, body: jsonEncode(body));
    } catch(e) {
      print(e);
    }
  }

}