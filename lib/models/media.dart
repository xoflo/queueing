import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../globals.dart';

class Media {
  int? id;
  String? name;
  String? link;

  Media.fromJson(dynamic data) {
    this.id = int.parse(data['id']);
    this.name = data['name'];
    this.link = data['link'];

  }

  update(dynamic data) async {
    try {
      final body = {
        'id': data['id'] ?? this.id,
        'name' : data['name'] ?? this.name,
        'link': data['link'] ?? this.link,
      };

      final uri = Uri.parse('http://$site/queueing_api/api_media.php');
      final response = await http.put(uri, body: jsonEncode(body));
    } catch(e) {
      print(e);
    }
  }
}