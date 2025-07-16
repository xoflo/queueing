import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _boxName = 'settingsBox';
  static const String _ipKey = 'ip_address';

  static Future<void> saveIP(String ip) async {
    var box = await Hive.openBox(_boxName);
    await box.put(_ipKey, ip);
  }

  static Future<String?> getIP() async {
    var box = await Hive.openBox(_boxName);
    return box.get(_ipKey);
  }




}
