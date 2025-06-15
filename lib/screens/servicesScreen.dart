import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:queueing/globals.dart';
import 'package:queueing/models/services/service.dart';
import 'package:queueing/models/services/serviceGroup.dart';
import 'package:http/http.dart' as http;
import '../models/priority.dart';
import '../models/ticket.dart';

import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}


class _ServicesScreenState extends State<ServicesScreen> {

  List<String> lastAssigned = [];
  String assignedGroup = "_MAIN_";

  PrinterBluetoothManager printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];

  @override
  void initState() {
    if (Platform.isAndroid) {
      printerManager.scanResults.listen((devices) async {
        setState(() {
          _devices = devices;
        });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        logoBackground(context),
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
    ));
  }

  nameDialog(Service service, String priorityType) {
    TextEditingController name = TextEditingController();

    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(""),
      content: Container(
        height: 100,
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
                            Text(priority.priorityName!)
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
    final number = tickets.length + 1;
    final numberParsed = number.toString().padLeft(4, '0');

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

      final ticket = Ticket().printTicket(context);

      // final result = await http.post(uri, body: jsonEncode(body));
     //  print(result.body);



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


  void _startScanDevices() {
    setState(() {
      _devices = [];
    });
    printerManager.startScan(Duration(seconds: 4));
  }

  void _stopScanDevices() {
    printerManager.stopScan();
  }

  Future<List<int>> demoReceipt(
      PaperSize paper, CapabilityProfile profile) async {
    final Generator ticket = Generator(paper, profile);
    List<int> bytes = [];

    // Print image
    // final ByteData data = await rootBundle.load('assets/rabbit_black.jpg');
    // final Uint8List imageBytes = data.buffer.asUint8List();
    // final Image? image = decodeImage(imageBytes);
    // bytes += ticket.image(image);

    bytes += ticket.text('GROCERYLY',
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
        linesAfter: 1);

    ticket.feed(2);
    ticket.cut();
    return bytes;
  }

  void _testPrint(PrinterBluetooth printer) async {
    printerManager.selectPrinter(printer);


    const PaperSize paper = PaperSize.mm80;
    final profile = await CapabilityProfile.load();

    // TEST PRINT
    // final PosPrintResult res =
    // await printerManager.printTicket(await testTicket(paper));

    // DEMO RECEIPT
    final PosPrintResult res =
    await printerManager.printTicket((await demoReceipt(paper, profile)));

  }
}
