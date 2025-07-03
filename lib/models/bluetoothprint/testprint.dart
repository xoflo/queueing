import 'dart:convert';
import 'dart:typed_data';
import 'printerenum.dart';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

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

  ticket(String codeAndNumber, String timeCreated, String priority, String ticketname) {

    try {
      int result = 0;

      bluetooth.isConnected.then((isConnected) {
        if (isConnected == true) {
          bluetooth.printNewLine();
          bluetooth.printCustom("Office of the Ombudsman", Size.boldLarge.val, Align.center.val);
          bluetooth.printCustom("Davao City, Philippines", Size.bold.val, Align.center.val);
          bluetooth.printNewLine();
          bluetooth.printCustom("YOUR TICKET NUMBER IS:", Size.medium.val, Align.center.val);
          List<int> bytes = [0x1D, 0x21, 0x33];
          bytes += utf8.encode("$codeAndNumber\n");
          bytes += [0x1D, 0x21, 0x00];
          bluetooth.writeBytes(Uint8List.fromList(bytes));
          bluetooth.printCustom("Time: $timeCreated", Size.bold.val, Align.left.val);
          bluetooth.printCustom("Priority: $priority", Size.bold.val, Align.left.val);
          bluetooth.printCustom("Name: $ticketname", Size.bold.val, Align.left.val);
          bluetooth
              .paperCut();

          result = 1;
        }
      });

      return result;
    } catch(e) {
      return 0;
    }

  }

}


