import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:queueing/globals.dart';


class Usbprint {
  List<PrinterDevice> devices = [];
  var printerManager = PrinterManager.instance;
  List<int>? pendingTask;
  var defaultPrinterType = PrinterType.usb;

  PrinterDevice? selectedDevice;

  bool _scanning = false;

  // USB devices that are NOT printers (kiosk touchscreen, etc.)
  static const List<String> _ignoredNames = ['ILITEK'];

  bool _isIgnored(PrinterDevice d) {
    final n = d.name.toUpperCase();
    return _ignoredNames.any((x) => n.contains(x));
  }

  bool _isSelected(PrinterDevice d) {
    return selectedDevice != null &&
        selectedDevice!.vendorId == d.vendorId &&
        selectedDevice!.productId == d.productId;
  }

  /// Scans USB and returns each printer only once (de-duplicated by
  /// vendorId + productId), without non-printer devices.
  Future<List<PrinterDevice>> scanUsb({Duration wait = const Duration(seconds: 2)}) async {
    final found = <String, PrinterDevice>{};
    final done = Completer<void>();

    final sub = printerManager.discovery(type: PrinterType.usb).listen(
          (d) {
        if (_isIgnored(d)) return;
        found['${d.vendorId}_${d.productId}'] = d;
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
      onError: (_) {
        if (!done.isCompleted) done.complete();
      },
    );

    // Finish as soon as the scan ends, or after [wait] at the latest.
    await done.future.timeout(wait, onTimeout: () {});
    await sub.cancel();

    devices = found.values.toList();
    return devices;
  }

  /// Connects to the device. Only marks it as selected if it succeeded.
  Future<bool> connectDevice(PrinterDevice device) async {
    try {
      final dynamic ok = await printerManager.connect(
          type: PrinterType.usb,
          model: UsbPrinterInput(
              name: device.name,
              productId: device.productId,
              vendorId: device.vendorId));

      if (ok == false) return false;

      selectedDevice = device;
      return true;
    } catch (e) {
      print("USB connect failed: $e");
      return false;
    }
  }


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
                    ],
                  ),
                  TextButton(
                      onPressed: _scanning ? null : () async {
                        _scanning = true;
                        setState(() {});
                        await scanUsb();
                        _scanning = false;
                        try {
                          setState(() {});
                        } catch (_) {} // dialog was closed during the scan
                      },
                      child: Text(_scanning ? "Scanning..." : "Scan Devices")),
                  Container(
                    height: 350,
                    child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, i) {
                          final d = devices[i];
                          final selected = _isSelected(d);

                          return ListTile(
                            title: Text(d.name),
                            selected: selected,
                            trailing: selected
                                ? Icon(Icons.check_circle, color: Colors.green)
                                : null,
                            onTap: () async {
                              final ok = await connectDevice(d);

                              if (ok) {
                                await savePrinter("${d.name}_${d.productId}_${d.vendorId}");
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Could not connect to ${d.name}")));
                              }

                              try {
                                setState(() {});
                              } catch (_) {}
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

    bytes += generator.text('Office of the Ombudsman', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Test Print');

    return bytes;
  }

  buildTicketQueue(String codeAndNumber, String timeCreated, String priority, String ticketname) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);

      List<int> bytes = [];

      bytes += utf8.encode('\n');

      bytes += [0x1B, 0x61, 0x01];               // ESC a 1 -> center
      bytes += [0x1B, 0x21, 0x30];               // Double height + double width
      bytes += utf8.encode('Office of the\nOmbudsman\n');

      bytes += [0x1B, 0x21, 0x08];               // Emphasized
      bytes += utf8.encode('Davao City, Philippines\n');
      bytes += utf8.encode('\n');

      bytes += [0x1B, 0x21, 0x10];               // Slightly larger
      bytes += utf8.encode('YOUR TICKET NUMBER IS:\n');

      bytes += [0x1D, 0x21, 0x33];               // Very large
      bytes += utf8.encode('$codeAndNumber\n');

      bytes += [0x1D, 0x21, 0x00];               // Normal size

      bytes += [0x1B, 0x61, 0x00];               // ESC a 0 -> left
      bytes += utf8.encode('Time: $timeCreated\n');
      bytes += utf8.encode('Priority: $priority\n');
      bytes += utf8.encode('Name: $ticketname\n');

      bytes += utf8.encode('\n\n\n\n');
      bytes += [0x1D, 0x56, 0x00];

      await printTicket(bytes);

      return 1;
    } catch(e) {
      return 0;
    }
  }

  printTicket(List<int> bytes) async {
    await printerManager.send(type: PrinterType.usb, bytes: bytes);
  }
}