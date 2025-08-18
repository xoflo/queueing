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

  safeConvert(dynamic) {
    return dynamic.runtimeType == "".runtimeType ? int.parse(dynamic) : dynamic;
  }

  Ticket.fromJson(dynamic data) {
    this.id = safeConvert(data['id']);
    this.timeCreated = data['timeCreated'];
    this.number = data['number'];
    this.serviceCode = data['serviceCode'];
    this.serviceType = data['serviceType'];
    this.userAssigned = data['userAssigned'];
    this.stationName = data['stationName'];
    this.stationNumber = safeConvert(data['stationNumber']);
    this.timeTaken = data['timeTaken'] == null || data['timeTaken'] == "" ? null : data['timeTaken'];
    this.timeDone = data['timeDone'] == null || data['timeDone'] == "" ? null : data['timeDone'];
    this.status = data['status'];
    this.log = data['log'];
    this.priority = safeConvert(data['priority']);
    this.priorityType = data['priorityType'];
    this.printStatus = safeConvert(data['printStatus']);
    this.callCheck = safeConvert(data['callCheck']);
    this.ticketName = data['ticketName'];
    this.codeAndNumber = "${data['serviceCode'] ?? ""}${data['number'] ?? ""}";
    this.blinker = safeConvert(data['blinker']);
    this.gender = data['gender'];

    this.timeCreatedAsDate = DateTime.parse(data['timeCreated'].toString());


    if ((data['timeTaken'] != null && data['timeTaken'] != "") && (data['timeDone'] != null && data['timeDone'] != "")) {
      final timeDifference = DateTime.parse(data['timeDone'].toString()).difference(DateTime.parse(data['timeTaken'].toString()));
      this.servingTime = "${_printDuration(timeDifference)}";
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
      return;
    } catch(e) {
      print(e);
      return;
    }
  }

}

class TicketSession {
  final String? ticketCodeAndNumber;
  final String? gender;
  final String? priorityType;
  final String? staff;
  final String? service;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? duration;
  final String? status;
  final String? fullLog;


  TicketSession({
    this.ticketCodeAndNumber,
    this.gender,
    this.priorityType,
    this.staff,
    this.service,
    this.startTime,
    this.endTime,
    this.duration,
    this.status,
    this.fullLog,
  });
}

extension TicketLogParser on Ticket {
  List<TicketSession> getSessions() {
    if (log == null || log!.isEmpty) return [];

    final regex = RegExp(
      r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+): (.+?)(?:,|$)',
      multiLine: false,
    );

    final matches = regex.allMatches(log!);
    List<TicketSession> sessions = [];

    DateTime? ticketGeneratedTime;
    DateTime? currentStart;
    String? currentStaff;
    String? lastService;
    String? currentStationName;
    bool hasServing = false;

    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      return "${twoDigits(d.inHours)}:"
          "${twoDigits(d.inMinutes % 60)}:"
          "${twoDigits(d.inSeconds % 60)}";
    }

    String safeDuration(DateTime? start, DateTime? end, {bool cap24h = false}) {
      if (start != null && end != null) {
        final diff = end.difference(start);

        if (cap24h && diff.inHours >= 24) {
          return "24:00:00+";
        }

        return formatDuration(diff);
      }
      return "00:00:00";
    }

    void endSession(DateTime endTime, String status) {
      sessions.add(TicketSession(
        ticketCodeAndNumber: codeAndNumber ?? '',
        gender: gender,
        priorityType: priorityType,
        fullLog: log,
        staff: currentStaff ?? "None",
        service: lastService,
        startTime: currentStart ?? endTime,
        endTime: endTime,
        duration: safeDuration(currentStart, endTime, cap24h: true),
        status: status,
      ));
      currentStart = null;
      currentStaff = null;
      currentStationName = null;
      hasServing = false;
    }

    for (final match in matches) {
      final timestamp = DateTime.tryParse(match.group(1) ?? '');
      if (timestamp == null) continue;
      final message = match.group(2) ?? '';

      if (message.startsWith('ticketGenerated')) {
        ticketGeneratedTime = timestamp;
        final genMatch = RegExp(r'ticketGenerated (.+)').firstMatch(message);
        if (genMatch != null) {
          lastService = genMatch.group(1);
        } else {
          lastService = "${serviceCode}";
        }
        hasServing = false;
      }

      else if (message.startsWith('serving on')) {
        final staffMatch = RegExp(r'serving on (.+?) by (.+)').firstMatch(message);
        if (staffMatch != null) {
          currentStationName = staffMatch.group(1);
          currentStaff = staffMatch.group(2);
        }
        currentStart = timestamp;
        hasServing = true;
      }

      else if (message.startsWith('ticket transferred to')) {
        final toMatch = RegExp(r'ticket transferred to (.+)').firstMatch(message);
        if (hasServing) {
          endSession(timestamp, "Done");
        } else {
          sessions.add(TicketSession(
            ticketCodeAndNumber: codeAndNumber ?? '',
            gender: gender,
            priorityType: priorityType,
            fullLog: log,
            staff: "None",
            service: lastService,
            startTime: ticketGeneratedTime ?? timestamp,
            endTime: timestamp,
            duration: "00:00:00",
            status: "Pending",
          ));
        }
        lastService = toMatch != null ? toMatch.group(1) : lastService;
      }

      else if (message.startsWith('Ticket Released')) {
        if (hasServing) {
          endSession(timestamp, "Released");
        }
      }

      else if (message.startsWith('Ticket Session Finished')) {
        if (hasServing) {
          endSession(timestamp, "Done");
        }
      }
    }

    // 👇 Handle cases after parsing all logs
    if (hasServing && currentStart != null) {
      // Still serving → mark as Serving
      sessions.add(TicketSession(
        ticketCodeAndNumber: codeAndNumber ?? '',
        gender: gender,
        priorityType: priorityType,
        fullLog: log,
        staff: currentStaff ?? "None",
        service: lastService,
        startTime: currentStart!,
        endTime: null,
        duration: safeDuration(currentStart, DateTime.now(), cap24h: true),
        status: "Serving",
      ));
    } else if (sessions.isEmpty) {
      // Nothing else happened → Pending
      sessions.add(TicketSession(
        ticketCodeAndNumber: codeAndNumber ?? '',
        gender: gender,
        priorityType: priorityType,
        fullLog: log,
        staff: "None",
        service: lastService,
        startTime: ticketGeneratedTime ?? DateTime.now(),
        endTime: null,
        duration: "00:00:00",
        status: 'Pending',
      ));
    }

    return sessions;
  }
}













