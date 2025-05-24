import 'dart:convert';

import 'package:http/http.dart' as http;

class Service {
  int? id;
  String? serviceType;
  String? serviceCode;


  Service.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.serviceType = data['serviceType'];
    this.serviceCode = data['serviceCode'];
  }

  update(dynamic data) async {
    try {

      final body = {
        'id': data['id'] ?? this.id,
        'serviceType' : data['serviceType'] ?? this.serviceType,
        'serviceCode': data['serviceCode'] ?? this.serviceCode,
      };

      final uri = Uri.parse('http://localhost:80/queueing_api/api_service.php');

      final response = await http.put(uri, body: jsonEncode(body));

    } catch(e) {
      print(e);
    }
  }
}