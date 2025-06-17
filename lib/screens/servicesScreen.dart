import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:queueing/globals.dart';
import 'package:queueing/models/services/service.dart';
import 'package:queueing/models/services/serviceGroup.dart';
import 'package:http/http.dart' as http;
import '../models/bluetoothprint/testprint.dart';
import '../models/priority.dart';
import '../models/ticket.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}


class _ServicesScreenState extends State<ServicesScreen> {

  List<String> lastAssigned = [];
  String assignedGroup = "_MAIN_";

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  TestPrint testPrint = TestPrint();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            logoBackground(context),
            Column(
              children: [

                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(onPressed: () {
                    showDialog(context: context, builder: (_) => StatefulBuilder(
                      builder: (BuildContext context, void Function(void Function()) setStateDialog) {
                        return FutureBuilder(
                          future: initPlatformState(),
                          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                            return AlertDialog(
                                content: Container(
                                  height: 400,
                                  width: 400,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ListView(
                                      children: <Widget>[
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: <Widget>[
                                            const SizedBox(width: 10),
                                            const Text(
                                              'Device:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 30),
                                            Expanded(
                                              child: DropdownButton(
                                                items: _getDeviceItems(),
                                                onChanged: (BluetoothDevice? value) =>
                                                    setStateDialog(() => _device = value),
                                                value: _device,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: <Widget>[
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                                              onPressed: () async {
                                                await initPlatformState();
                                              },
                                              child: const Text(
                                                'Refresh',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: _connected ? Colors.red : Colors.green),
                                              onPressed: _connected ? _disconnect : _connect,
                                              child: Text(
                                                _connected ? 'Disconnect' : 'Connect',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                                            onPressed: () {
                                              testPrint.sample();
                                            },
                                            child: const Text('PRINT TEST',
                                                style: TextStyle(color: Colors.white)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ));
                          },
                        );
                      },
                    ));
                  }, icon: Icon(Icons.settings)),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Select Service to Queue", style: TextStyle(fontSize: 30)),
                    StatefulBuilder(
                      builder: (BuildContext context,
                          void Function(void Function()) setStateList) {
                        return FutureBuilder(
                          future: getServiceGroups(assignedGroup),
                          builder: (BuildContext context,
                              AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                            return Column(
                              children: [
                                lastAssigned.isNotEmpty
                                    ? IconButton(
                                    onPressed: () {
                                      assignedGroup = lastAssigned.last;
                                      lastAssigned.removeLast();
                                      setStateList((){});
                                    },
                                    icon: Icon(Icons.chevron_left))
                                    : Container(),
                                snapshot.connectionState == ConnectionState.done
                                    ? Container(
                                  height: MediaQuery.of(context).size.height - 100,
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: GridView.builder(
                                        gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 5 : 3),
                                        itemCount: snapshot.data!.length,
                                        itemBuilder: (context, i) {
                                          return snapshot.data![i]['serviceType'] !=
                                              null
                                              ? Builder(builder: (context) {
                                            final service = Service.fromJson(
                                                snapshot.data![i]);
                                            return Padding(
                                              padding: EdgeInsets.all(10),
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final List<dynamic> result = await getSettings(context);
                                                  int priority = int.parse(result.where((e) => e['controlName'] == 'Priority Option').toList()[0]['value']);
                                                  int ticketname = int.parse(result.where((e) => e['controlName'] == 'Ticket Name Option').toList()[0]['value']);

                                                  if (priority == 1) {
                                                    priorityDialog(service, ticketname);
                                                  } else {
                                                    if (ticketname == 1) {
                                                      nameDialog(service, "None");
                                                    } else {
                                                      addTicketSQL(service.serviceType!, service.serviceCode!, "None");
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket Created Successfully")));

                                                    }
                                                  }
                                                },
                                                child: Card(
                                                  child:
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(service.serviceType!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          })
                                              : Builder(builder: (context) {
                                            final group = ServiceGroup.fromJson(
                                                snapshot.data![i]);
                                            return Padding(
                                              padding: EdgeInsets.all(10),
                                              child: GestureDetector(
                                                onTap: () {
                                                  lastAssigned.add(assignedGroup);
                                                  assignedGroup = group.name!;
                                                  setStateList((){});
                                                },
                                                child: Card(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(group.name!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                        }),
                                  ),
                                )
                                    : Center(
                                  child: Container(
                                    height: 100,
                                    width: 100,
                                    child: CircularProgressIndicator(
                                      color: Colors.blue,
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ));
  }

  nameDialog(Service service, String priorityType) {
    TextEditingController name = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text("Name (Optional)"),
      content: Container(
        height: 60,
        width: 100,
        child: TextField(
          controller: name,
          decoration: InputDecoration(
            labelText: "Name")
          )
        ),
      actions: [
        TextButton(onPressed: () {
          addTicketSQL(service.serviceType!, service.serviceCode!, priorityType, name.text);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket Created Successfully")));
          Navigator.pop(context);
        }, child: Text(""
            "Submit"))
      ],
      ),
    );

  }

  priorityDialog(Service service, [int? ticketname]) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text("Select priorities (if applicable)"),
      content: FutureBuilder(
        future: getPriority(),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ? Container(
            height: 400,
            width: 400,
            child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, i) {
                  final priority = Priority.fromJson(snapshot.data![i]);
                  return Padding(
                    padding: EdgeInsets.all(10),
                    child: GestureDetector(
                      onTap: () {
                        if (ticketname == 1) {
                          Navigator.pop(context);
                          nameDialog(service, priority.priorityName!);
                        } else {
                          addTicketSQL(service.serviceType!,service.serviceCode!, priority.priorityName!);
                    
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket Created Successfully")));
                          Navigator.pop(context);
                        }
                      },
                      child: Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(priority.priorityName!, style: TextStyle(fontSize: 15))
                          ],
                        ),
                      ),
                    ),
                  );

            }),
          ) : Container(
            height: 300,
            child: Center(
              child: Text(
                "No Priorites added.",style: TextStyle(color: Colors.grey),
              ),
            ),
          ) : Container(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    ));
  }


  toDateTime(DateTime date) {
    DateTime(date.year, date.month, date.day);
  }

  getTicketSQL(String serviceType) async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response
          .where((e) =>
              e['status'] == "Pending" &&
              toDateTime(DateTime.parse(e['timeCreated'])) ==
                  toDateTime(DateTime.now()) &&
              e['serviceType'] == serviceType)
          .toList();
      List<Ticket> newTickets = [];

      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a, b) => DateTime.parse(a.timeCreated!)
          .compareTo(DateTime.parse(b.timeCreated!)));

      return newTickets;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  addTicketSQL(String serviceType, String serviceCode, String priorityType, [String? ticketName]) async {
    final String timestamp = DateTime.now().toString();

    final List<Ticket> tickets = await getTicketSQL(serviceType);
    final thisDay = tickets.where((e) => DateTime.parse(e.timeCreated!).day == DateTime.now().day && DateTime.parse(e.timeCreated!).month == DateTime.now().month && DateTime.parse(e.timeCreated!).day == DateTime.now().day).toList();
    final number = thisDay.length + 1;
    final numberParsed = number.toString().padLeft(3, '0');

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');
      final body = {
        "timeCreated": timestamp,
        "number": numberParsed,
        "serviceCode": serviceCode,
        "serviceType": serviceType,
        "userAssigned": "",
        "stationName": "",
        "stationNumber": "",
        "timeTaken": "",
        "timeDone": "",
        "status": "Pending",
        "log": "$timestamp: ticketGenerated",
        "priority": priorityType != "None" ? 1 : 0,
        "priorityType": "$priorityType",
        "printStatus": 1,
        "callCheck": 0,
        "ticketName": ticketName ?? ""
      };

      // testPrint.ticket("${serviceCode}${numberParsed}", "$timestamp", "$priorityType", "$ticketName");
      // final result = await http.post(uri, body: jsonEncode(body));
      // print(result.body);

      final result = await http.post(uri, body: jsonEncode(body));
      print(result.body);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));

      print(e);
    }
  }

  getServiceGroups(String assignedGroup) async {
    try {
      final uriGroup =
          Uri.parse('http://$site/queueing_api/api_serviceGroup.php');
      final resultGroup = await http.get(uriGroup);
      List<dynamic> responseGroup = jsonDecode(resultGroup.body);

      final uriService = Uri.parse('http://$site/queueing_api/api_service.php');
      final resultService = await http.get(uriService);
      List<dynamic> responseService = jsonDecode(resultService.body);
      List<dynamic> resultsToReturn = [];

      for (int i = 0; i < responseGroup.length; i++) {
        if (responseGroup[i]['assignedGroup'] == assignedGroup) {
          resultsToReturn.add(responseGroup[i]);
        }
      }

      for (int i = 0; i < responseService.length; i++) {
        if (responseService[i]['assignedGroup'] == assignedGroup) {
          resultsToReturn.add(responseService[i]);
        }
      }


      return resultsToReturn;
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  getPriority() async {
    final uri = Uri.parse('http://$site/queueing_api/api_priorities.php');
    final result = await http.get(uri);
    List<dynamic> response = jsonDecode(result.body);
    response.add({"priorityName": "None", "id": 999.toString()});
    return response;
  }

// print

  Future<void> initPlatformState() async {

     var statusLocation = Permission.location;
     if (await statusLocation.isGranted != true) {
       await Permission.location.request();
     }
     if (await statusLocation.isGranted) {} else {}
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {}

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            print("bluetooth device state: connected");
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            print("bluetooth device state: disconnected");
          });
          break;
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
          setState(() {
            _connected = false;
            print("bluetooth device state: disconnect requested");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth turning off");
          });
          break;
        case BlueThermalPrinter.STATE_OFF:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth off");
          });
          break;
        case BlueThermalPrinter.STATE_ON:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth on");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_ON:
          setState(() {
            _connected = false;
            print("bluetooth device state: bluetooth turning on");
          });
          break;
        case BlueThermalPrinter.ERROR:
          setState(() {
            _connected = false;
            print("bluetooth device state: error");
          });
          break;
        default:
          print(state);
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
    });

    if (isConnected == true) {
      setState(() {
        _connected = true;
      });
    }
  }


  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devices.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name ?? ""),
          value: device,
        ));
      });
    }
    return items;
  }

  void _connect() {
    if (_device != null) {
      bluetooth.isConnected.then((isConnected) {
        if (isConnected == false) {
          bluetooth.connect(_device!).catchError((error) {
            setState(() => _connected = false);
          });
          setState(() => _connected = true);
        }
      });
    } else {
      show('No device selected.');
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  Future show(
      String message, {
        Duration duration = const Duration(seconds: 3),
      }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: duration,
      ),
    );
  }

}
