import 'dart:typed_data';

import '../ticket.dart';
import 'printerenum.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

///Test printing
class TestPrint {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  sample() async {
    ByteData bytesAsset = await rootBundle.load("assets/images/logo.png");
    Uint8List imageBytesFromAsset = bytesAsset.buffer
        .asUint8List(bytesAsset.offsetInBytes, bytesAsset.lengthInBytes);

    bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {
        bluetooth.printNewLine();
        bluetooth.printCustom("Office of the Ombudsman", Size.extraLarge.val, Align.center.val);
        bluetooth.printNewLine();
        bluetooth.printImageBytes(imageBytesFromAsset); //image from Asset
        bluetooth.printNewLine();
        bluetooth.printCustom("XXXXX", 15, Align.center.val);
        bluetooth.printNewLine();
        bluetooth.printCustom("Time Generated: 12345678", Size.bold.val, Align.left.val);
        bluetooth.printCustom("Priority: None", Size.bold.val, Align.left.val);
        bluetooth.printCustom("Name: ", Size.bold.val, Align.left.val);
        bluetooth
            .paperCut();
      }
    });
  }

  printTicket(Ticket ticket) async {
    ByteData bytesAsset = await rootBundle.load("assets/images/logo.png");
    Uint8List imageBytesFromAsset = bytesAsset.buffer
        .asUint8List(bytesAsset.offsetInBytes, bytesAsset.lengthInBytes);

    bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {
        bluetooth.printNewLine();
        bluetooth.printCustom("Office of the Ombudsman", Size.extraLarge.val, Align.center.val);
        bluetooth.printNewLine();
        bluetooth.printImageBytes(imageBytesFromAsset); //image from Asset
        bluetooth.printNewLine();
        bluetooth.printCustom("${ticket.codeAndNumber}", 15, Align.center.val);
        bluetooth.printNewLine();
        bluetooth.printCustom("Time Generated: ${ticket.timeCreated}", Size.bold.val, Align.left.val);
        bluetooth.printCustom("Priority: ${ticket.priority}", Size.bold.val, Align.left.val);
        bluetooth.printCustom("Name: ${ticket.ticketName}", Size.bold.val, Align.left.val);
        bluetooth
            .paperCut();
      }
    });
  }

}


