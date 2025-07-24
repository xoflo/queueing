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
  String? gender;

  DateTime? timeCreatedAsDate;
  String? codeAndNumber;
  int? blinker;
  
  String? servingTime;

  Ticket.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.timeCreated = data['timeCreated'];
    this.number = data['number'];
    this.serviceCode = data['serviceCode'];
    this.serviceType = data['serviceType'];
    this.userAssigned = data['userAssigned'];
    this.stationName = data['stationName'];
    this.stationNumber = int.parse(data['stationNumber']);
    this.timeTaken = data['timeTaken'] == null || data['timeTaken'] == "" ? null : data['timeTaken'];
    this.timeDone = data['timeDone'] == null || data['timeDone'] == "" ? null : data['timeDone'];
    this.status = data['status'];
    this.log = data['log'];
    this.priority = int.parse(data['priority']);
    this.priorityType = data['priorityType'];
    this.printStatus = int.parse(data['printStatus']);
    this.callCheck = int.parse(data['callCheck']);
    this.ticketName = data['ticketName'];
    this.codeAndNumber = "${data['serviceCode']}${data['number']}";
    this.blinker = int.parse(data['blinker']);
    this.gender = data['gender'];

    this.timeCreatedAsDate = DateTime.parse(data['timeCreated'].toString());


    if ((data['timeTaken'] != null && data['timeTaken'] != "") && (data['timeDone'] != null && data['timeDone'] != "")) {
      final timeDifference = DateTime.parse(data['timeDone']).difference(DateTime.parse(data['timeTaken']));
      this.servingTime = "${_printDuration(timeDifference)}";
      print("servingTime: $servingTime");
    } else {
      this.servingTime = null;
    }
  }

  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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
        'blinker': data['blinker'] ?? this.blinker,
        'gender': data['gender'] ?? this.gender,
      };

      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');
      final response = await http.put(uri, body: jsonEncode(body));
      print("servingStream: ${response.body}");
      return;
    } catch(e) {
      print(e);
      return;
    }
  }

}