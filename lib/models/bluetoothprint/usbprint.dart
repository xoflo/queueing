import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';


class Usbprint {
  List<PrinterDevice> devices = [];
  var printerManager = PrinterManager.instance;
  List<int>? pendingTask;
  var defaultPrinterType = PrinterType.usb;

  PrinterDevice? selectedDevice;


  interface() {
    return AlertDialog(
      content: StatefulBuilder(
        builder: (BuildContext context, setState) {
          return Container(
            width: 400,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Devices Found: ${devices.length}"),
                      Text(" | Selected: ${selectedDevice != null ? selectedDevice!.name : "None"}"),
                      TextButton(onPressed: () {
                        _scan(PrinterType.usb);
                        setState((){});
                      }, child: Text("Scan Devices"))
                    ],
                  ),
                  Container(
                    height: 350,
                    child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, i) {
                          return ListTile(
                            title: Text(devices[i].name),
                            onTap: () async {
                              final PrinterDevice device = PrinterDevice(name: devices[i].name, productId: devices[i].productId, vendorId: devices[i].vendorId);
                              await _connectDevice(context, device);
                              selectedDevice = device;
                              setState((){});
                            },
                          );
                        }),
                  ),
                  TextButton(
                      child: Text("Print Test"),
                      onPressed: () async {
                        try {
                          final bytes  = await buildTicket();
                          await printTicket(bytes);
                        } catch(e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      })
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  buildTicket() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += bytes + generator.text('Office of the Ombudsman', styles: const PosStyles(align: PosAlign.center));
    bytes += bytes + generator.text('Test Print');

    return bytes;
  }

  buildTicketQueue(String codeAndNumber, String timeCreated, String priority, String ticketname) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += utf8.encode('\n');
      bytes += [0x1B, 0x21, 0x30];
      bytes += utf8.encode('Office of the Ombudsman\n');
      bytes += [0x1B, 0x21, 0x08];
      bytes += utf8.encode('Davao City, Philippines\n');
      bytes += utf8.encode('\n');
      bytes += [0x1B, 0x21, 0x10];
      bytes += utf8.encode('YOUR TICKET NUMBER IS:\n');
      bytes += [0x1D, 0x21, 0x33];
      bytes += utf8.encode('$codeAndNumber\n');
      bytes += [0x1D, 0x21, 0x00];
      bytes += utf8.encode('Time: $timeCreated\n');
      bytes += utf8.encode('Priority: $priority\n');
      bytes += utf8.encode('Name: $ticketname\n');
      bytes += [0x1D, 0x56, 0x00];

      return 1;
    } catch(e) {
      return 0;
    }
  }

  _scan(PrinterType type) {
    devices.clear();
    printerManager.discovery(type: PrinterType.usb).listen((device) {
      devices.add(device);
    });
  }

  _connectDevice(BuildContext context, PrinterDevice selectedPrinter) async {
    await printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(name: selectedPrinter.name, productId: selectedPrinter.productId, vendorId: selectedPrinter.vendorId));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${selectedPrinter.name} ${selectedPrinter.productId} ${selectedPrinter.vendorId}")));
  }

  printTicket(List<int> bytes) async {
    await printerManager.send(type: PrinterType.usb, bytes: bytes);
  }
}

