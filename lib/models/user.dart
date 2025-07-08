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


  User.fromJson(dynamic data) {

    id = int.parse(data['id']);
    pass = data['pass'];
    userType = data['userType'];
    serviceType = data['serviceType'] == null ? [] : stringToList(data['serviceType'].toString());
    username = data['username'];
    loggedIn = data['loggedIn'] == null ? null : DateTime.parse(data['loggedIn']);
    servicesSet = data['servicesSet'] != null || data['servicesSet'] != "" || data['serviceType'] != "[]" ? stringToList(data['servicesSet'].toString()) : null;

  }

  update(dynamic data) async {
    try {
      final body = {
        'id': data['id'] ?? id,
        'pass' : data['pass'] ?? pass,
        'userType': data['userType'] ?? userType,
        'serviceType': data['serviceType'] == null ? serviceType!.isEmpty ? null : serviceType.toString() : data['serviceType'].toString(),
        'username': data['username'] ?? username,
        'loggedIn': data['loggedIn'] == null ? loggedIn == null ? null : data['loggedIn'].toString() : loggedIn,
        'servicesSet': data['servicesSet'] == null ? servicesSet!.isEmpty ? null : servicesSet.toString() : data['servicesSet'].toString(),
      };
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final response = await http.put(uri, body: jsonEncode(body));
    } catch(e) {
      print(e);
    }
  }

  updateAssignedServices(int id) async {

    final User user = await getUserSQL(id);

    List<String> existingServices = [];
    List<String> toKeep = [];
    String? serviceSetHere;

    if (user.serviceType != null) {
      final List<dynamic> services = await getServiceSQL();

      for (int i = 0; i < services.length; i++) {
        existingServices.add(services[i]['serviceType']!);
      }

      for (int i = 0; i < user.serviceType!.length; i++) {
        if (existingServices.contains(user.serviceType![i])) {
          toKeep.add(user.serviceType![i]);
        }
      }

      if (toKeep.length > 3) {
        serviceSetHere = toKeep.sublist(0, 3).toString();
      } else {
        serviceSetHere = toKeep.isNotEmpty ? toKeep.toString() == "[]" ? null : toKeep.toString() : "";
      }

      update({
        'serviceType': toKeep.isNotEmpty ? toKeep.toString() == "[]" ? null : toKeep.toString() : "",
        'servicesSet' : serviceSetHere,
      });

    }

  }

  getUserSQL(int id) async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_user.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);

      print(response);

      final user = response.where((e) => int.parse(e['id']) == id).toList()[0];

      return User.fromJson(user);
    } catch (e) {
      print(e);
    }
  }
}