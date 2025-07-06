import 'dart:convert';
import 'package:queueing/models/services/service.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';

class User {
  int? id;
  String? pass;
  String? userType;
  List<dynamic>? serviceType;
  String? username;
  DateTime? loggedIn;
  List<dynamic>? servicesSet;


  User.fromJson(dynamic data, int logIn) {

    id = int.parse(data['id']);
    pass = data['pass'];
    userType = data['userType'];
    serviceType = data['serviceType'] != null || data['serviceType'] != "" ? stringToList(data['serviceType'].toString()) : null;
    username = data['username'];
    loggedIn = data['loggedIn'] == null || data['loggedIn'] == "" ? null : DateTime.parse(data['loggedIn']);
    servicesSet = data['servicesSet'] != null || data['servicesSet'] != "" ? stringToList(data['servicesSet'].toString()) : null;

    if (userType == "Staff" && logIn == 1) {
      updateAssignedServices();
    }
  }

  update(dynamic data) async {
    try {
      final body = {
        'id': data['id'] ?? id,
        'pass' : data['pass'] ?? pass,
        'userType': data['userType'] ?? userType,
        'serviceType': data['serviceType'] ?? serviceType.toString(),
        'username': data['username'] ?? username,
        'loggedIn': data['loggedIn'] ?? loggedIn.toString(),
        'servicesSet': data['servicesSet'] ?? servicesSet.toString(),
      };

      print(body);

      this.serviceType = data['serviceType'] != null ? stringToList(data['serviceType']) : serviceType;
      this.servicesSet = data['servicesSet'] != null ? stringToList(data['servicesSet']) : servicesSet;

      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final response = await http.put(uri, body: jsonEncode(body));
      print(response.body);
    } catch(e) {
      print(e);
    }
  }



  updateAssignedServices() async {

    List<String> existingServices = [];
    List<String> toKeep = [];
    String? serviceSetHere;

    if (serviceType != null) {
      final List<dynamic> services = await getServiceSQL();

      services.forEach((e) {
        existingServices.add(e['serviceType']!);
      });

      for (int i = 0; i < serviceType!.length; i++) {
        if (existingServices.contains(serviceType![i])) {
          toKeep.add(serviceType![i]);
        }
      }

      if (toKeep.length > 3) {
        serviceSetHere = toKeep.sublist(0, 3).toString();
      } else {
        serviceSetHere = toKeep.isNotEmpty ? toKeep.toString() : "";
      }

      update({
        'serviceType': toKeep.isNotEmpty ? toKeep.toString() : "",
        'servicesSet' : serviceSetHere,
      });

    }

  }
}