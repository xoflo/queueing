import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _boxName = 'settingsBox';
  static const String _ipKey = 'ip_address';

  static const String _boxNamePrinter = 'printerBox';
  static const String _printerKey = 'printer';

  static const String _boxNameSize = 'sizeBox';
  static const String _sizeKey = 'size';

  static Future<void> saveIP(String ip) async {
    var box = await Hive.openBox(_boxName);
    await box.put(_ipKey, ip);
  }

  static Future<String?> getIP() async {
    var box = await Hive.openBox(_boxName);
    return box.get(_ipKey);
  }

  static Future<void> savePrinter(String printer) async {
    var box = await Hive.openBox(_boxNamePrinter);
    await box.put(_printerKey, printer);
  }

  static Future<String?> getPrinter() async {
    var box = await Hive.openBox(_boxNamePrinter);
    return box.get(_printerKey);
  }

  static Future<void> saveSize(String size) async {
    var box = await Hive.openBox(_boxNameSize);
    await box.put(_sizeKey, size);
  }

  static Future<String?> getSize() async {
    var box = await Hive.openBox(_boxNameSize);
    return box.get(_sizeKey);
  }



}
