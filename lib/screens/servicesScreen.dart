import 'dart:async';
import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:queueing/globals.dart';
import 'package:queueing/models/bluetoothprint/usbprint.dart';
import 'package:queueing/models/services/service.dart';
import 'package:queueing/models/services/serviceGroup.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/node.dart';
import '../models/bluetoothprint/bluetoothprint.dart';
import '../models/controls.dart';
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
  BluetoothPrinter printer = BluetoothPrinter();

  Usbprint? usb;

  Timer? timer;
  Timer? activeServiceTimer;

  List<dynamic> services = [];

  @override
  void dispose() {
    timer?.cancel();
    activeServiceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    NodeSocketService().connect(context: context);

    NodeSocketService().stream.listen((onData) async {
      final result = jsonDecode(onData);
      final type = result['type'];
      final data = result['data'];

      if (type == 'stationPing') {
        NodeSocketService().sendMessage('getActiveServices', {});
      }

      if (type == 'getActiveServices') {
        List<String> newServices = [];

        for (int i = 0; i <data.length; i++ ) {
          newServices.add(data[i].toString().trim());
        }

        print(services);
        print(newServices);

        if (newServices != services) {
          if (services != data) {
            services = newServices;
          }
        }

      }
    });


    _resetTimer();
    _getActiveServices();

    if (!kIsWeb) {
      if (Platform.isAndroid) {
        usb = Usbprint();
      }
    }

    super.initState();
  }

  _getActiveServices() {

    activeServiceTimer = Timer.periodic(Duration(seconds: 5), (callback) {
      NodeSocketService().sendMessage('getActiveServices', {});
    });
  }

  _resetTimer() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 60), () {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => ServicesScreenSaver()));
    });
  }

  bool printVisible = false;
  final printKey = GlobalKey();

  // Fallback ticket-number display (for when the printer fails)
  final List<Map<String, String>> recentTickets = []; // most recent first

  String _formatTime12h(DateTime dt) {
    final hour24 = dt.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = hour24 < 12 ? 'AM' : 'PM';
    return "$hour12:$minute $ampm";
  }

  void _addRecentTicket(String codeAndNumber, {required bool printed}) {
    recentTickets.insert(0, {
      "number": codeAndNumber,
      "time": _formatTime12h(DateTime.now()),
      "printed": printed ? "1" : "0",
    });
    if (recentTickets.length > 20) recentTickets.removeLast();
  }

  void _showCurrentTicketDialog() {
    final latest = recentTickets.isNotEmpty ? recentTickets.first : null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Current Ticket"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (latest == null)
                Text("No tickets generated yet.")
              else ...[
                Text(
                  latest["number"] ?? "",
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text("Generated at ${latest["time"]}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Dismiss"),
            )
          ],
        ),
      ),
    );
  }

  void _showTicketNumberDialog(String codeAndNumber, {required bool printed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Your Ticket Number"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              codeAndNumber,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (!printed) ...[
              SizedBox(height: 8),
              Text(
                "Printer unavailable — this ticket was not saved to the queue. Please inform staff.",
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Dismiss"),
          )
        ],
      ),
    );
  }

  void _showRecentTicketsDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Recent Tickets"),
          content: Container(
            width: 350,
            height: 400,
            child: recentTickets.isEmpty
                ? Center(child: Text("No tickets yet."))
                : ListView.separated(
              itemCount: recentTickets.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, i) {
                final t = recentTickets[i];
                final printed = t["printed"] == "1";
                return ListTile(
                  title: Text(t["number"] ?? "",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: Text(t["time"] ?? ""),
                  trailing: Icon(
                    printed ? Icons.check_circle : Icons.error_outline,
                    color: printed ? Colors.green : Colors.orange,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            )
          ],
        ),
      ),
    );
  }

  int toCut = 0;



  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool, value) async => false,
      child: Scaffold(
          floatingActionButton: StatefulBuilder(
              key: printKey,
              builder: (context, setStateFAB) {
                return printVisible == true ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 5,
                  children: [
                    FloatingActionButton(
                        heroTag: "recentTickets",
                        tooltip: "Recent Tickets",
                        child: Icon(Icons.receipt_long),
                        onPressed: _showRecentTicketsDialog),
                    FloatingActionButton(
                        heroTag: "currentTicket",
                        tooltip: "Show Current Ticket",
                        child: Icon(Icons.confirmation_number),
                        onPressed: _showCurrentTicketDialog),
                    FloatingActionButton(
                        child: Icon(Icons.refresh),
                        onPressed: () async {
                          await clearCache();
                          this.setState((){});
                        }),
                    /*
              FloatingActionButton(
                  child: Icon(Icons.wifi),
                  onPressed: () async {
                    TextEditingController ipcont = TextEditingController();
                    final getIp = await getIP();
                    ipcont.text = getIp ?? "";
                    showDialog(context: context, builder: (_) => AlertDialog(
                      title: Text("Set IP"),
                      content: Container(
                        height: 50,
                        width: 200,
                        child: Column(
                          children: [
                            TextField(
                              controller: ipcont,
                              decoration: InputDecoration(
                                labelText: 'IP Address'
                              ),
                            )
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () async {
                          await saveIP(ipcont.text);
                          Navigator.pop(context);
                          setState(() {});
                        }, child: Text("Set IP"))
                      ],
                    ));
                  }),

               */

                    FloatingActionButton(
                        child: Icon(Icons.print),
                        onPressed: () async {
                          await settingSecurity();
                        }),

                    FloatingActionButton(
                        child: Icon(Icons.lock_open),
                        onPressed: () async {
                          await settingSecurityPin();
                        })
                  ],
                ) : SizedBox();
              }),
          body: GestureDetector(
            onLongPress: () {
              printVisible = !printVisible;
              printKey.currentState!.setState(() {});
            },
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _resetTimer(),
              child: Stack(
                children: [
                  getBackgroundVideoOverlay(),
                  logoBackground(context, 300),
                  getRainbowOverlay(),
                  Builder(
                      builder: (context) {

                        final gridKey = GlobalKey();

                        return Container(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          child: StatefulBuilder(
                            key: gridKey,
                            builder: (context, setStateList) {
                              final size = MediaQuery.of(context).size;
                              final itemWidth = size.width / 4;
                              final itemHeight = (size.height / 3) - 10;
                              final aspectRatio = itemWidth / itemHeight;

                              return FutureBuilder(
                                future: getServiceGroups(assignedGroup),
                                builder: (BuildContext context,
                                    AsyncSnapshot<List<Map<String, dynamic>>>
                                    snapshotQuery) {
                                  return Column(
                                    children: [
                                      lastAssigned.isNotEmpty
                                          ? IconButton(
                                          onPressed: () {
                                            assignedGroup = lastAssigned.last;
                                            lastAssigned.removeLast();
                                            setStateList(() {});
                                          },
                                          icon: Icon(Icons.chevron_left))
                                          : Container(),
                                      snapshotQuery.connectionState == ConnectionState.done
                                          ? Container(
                                        height: MediaQuery.of(context).size.height,
                                        child: Builder(
                                            builder: (context) {
                                              List<Map<String, dynamic>> getSnapshot = snapshotQuery.data!;
                                              final List<Map<String, dynamic>> snapshot = getSortedSnapshot(getSnapshot);

                                              return GridView.builder(
                                                  padding: EdgeInsets.all(10),
                                                  gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                      childAspectRatio: aspectRatio,
                                                      crossAxisCount: MediaQuery
                                                          .of(context)
                                                          .size
                                                          .width >
                                                          1200
                                                          ? 4
                                                          : MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                          800
                                                          ? 2
                                                          : 1),
                                                  itemCount: snapshot.length,
                                                  itemBuilder: (context, i) {
                                                    return snapshot[i]['nextPage'] == null ?
                                                    snapshot[i]['serviceType'] !=
                                                        null
                                                        ? Builder(builder: (context) {
                                                      final Service service = Service.fromJson(snapshot[i]);
                                                      return Padding(
                                                        padding:
                                                        EdgeInsets.all(3),
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            final List<dynamic>
                                                            result =
                                                            await getSettings(
                                                                context);
                                                            int priority = int.parse(result
                                                                .where((e) =>
                                                            e['controlName'] ==
                                                                'Priority Option')
                                                                .toList()[0]['value']);
                                                            int name = int.parse(result
                                                                .where((e) =>
                                                            e['controlName'] ==
                                                                'Ticket Name Option')
                                                                .toList()[0]['value']);
                                                            int gender = int.parse(result
                                                                .where((e) =>
                                                            e['controlName'] ==
                                                                'Gender Option')
                                                                .toList()[0]['value']);

                                                            // name, gender

                                                            if (services.contains(service.serviceType!)) {
                                                              await addTicketDialog(priority, name, gender, service);
                                                            } else {
                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("This service is currently closed.")));
                                                            }

                                                          },
                                                          child: Opacity(
                                                            opacity: 0.75,
                                                            child: Card(
                                                              child: InkWell(
                                                                splashColor: Theme.of(context).splashColor,
                                                                highlightColor: Theme.of(context).highlightColor,
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                                  children: [
                                                                    Padding(
                                                                      padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          15.0),
                                                                      child: Text(
                                                                        service
                                                                            .serviceType!,
                                                                        style: TextStyle(
                                                                            fontSize: 30,
                                                                            fontWeight:
                                                                            FontWeight.w700),
                                                                        textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                        maxLines: 4,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    })
                                                        : Builder(builder: (context) {
                                                      final group =
                                                      ServiceGroup.fromJson(
                                                          snapshot
                                                          [i]);
                                                      return Opacity(
                                                        opacity: 0.75,
                                                        child: Card(
                                                          child: Padding(
                                                            padding:
                                                            EdgeInsets.all(15),
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                lastAssigned.add(
                                                                    assignedGroup);
                                                                assignedGroup =
                                                                group.name!;
                                                                setStateList(() {});
                                                              },
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                                children: [
                                                                  Text(
                                                                    group.name!,
                                                                    style: TextStyle(
                                                                        fontSize: 30,
                                                                        fontWeight:
                                                                        FontWeight.w700),  textAlign:
                                                                  TextAlign
                                                                      .center,
                                                                    maxLines: 3,
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }) :
                                                    nextPageHandler(context, snapshot[i]['nextPage'], gridKey);
                                                  });
                                            }
                                        ),
                                      )
                                          : SizedBox()
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        );
                      }
                  )
                ],
              ),
            ),
          )),
    );
  }

  addTicketDialog(int priorityOption, int nameOption, int genderOption, Service service) async {
    String? priority = "";
    String? name = "";
    String? gender = "";

    if (priorityOption == 1) priority = await priorityDialog();
    if (nameOption == 1 && priority != null) name = await nameDialog();
    if (genderOption == 1 && priority != null && name != null) gender = await genderDialog();

    if (priority != null && name != null && gender != null) {
      await addTicketSQL(
        service.serviceType!,
        service.serviceCode!,
        priority, name, gender,
      );
    }
  }


  List<Map<String, dynamic>> getSortedSnapshot(List<Map<String, dynamic>> snapshot) {
    int toAdd = snapshot.length ~/ 12;
    int excess = snapshot.length % 12;
    int toFill = snapshot.length < 12 ? 12 - snapshot.length : 12 - excess;

    List<Map<String, dynamic>> getSnapshot = snapshot;

    if (snapshot.length < 12) {
      for (int y = 0; y < toFill; y++) {
        getSnapshot.add({
          'nextPage' : 4
        });
      }
    }

    for (int i = 0; i < toAdd; i++) {

      if (i == 0) {
        getSnapshot.insert(11*(i+1)+i, {
          'nextPage' : 1
        });
      }


      if (i > 0) {
        if (i != toAdd-1) {
          getSnapshot.insert(11*(i+1)+(1*i), {
            'nextPage' : 2
          });

        } else {
          getSnapshot.insert(11*(i+1)+(1*i), {
            'nextPage' : 2
          });

          for (int y = 0; y < toFill; y++) {
            getSnapshot.add({
              'nextPage' : 4
            });
          }

          getSnapshot.insert(11*(i+2)+(i+1), {
            'nextPage' : 3
          });
        }
      } else {
        if (i == toAdd - 1) {
          for (int y = 0; y < toFill; y++) {
            getSnapshot.add({
              'nextPage' : 4
            });
          }
          getSnapshot.insert(11*(i+2)+(i+1), {
            'nextPage' : 3
          });
        }
      }

    }

    getSnapshot = getSnapshot.sublist(toCut, (getSnapshot.length > 12+toCut ? 12+toCut : getSnapshot.length));

    return getSnapshot;
  }


  nextPageHandler(BuildContext context, int i, GlobalKey gridKey) {
    void updateGrid() {
      gridKey.currentState!.setState((){});
    }

    if (i == 1) {
      return Builder(
          builder: (context) {
            return GestureDetector(
              child: Opacity(
                opacity: 0.75,
                child: Card(
                  child: InkWell(
                    splashColor: Theme.of(context).splashColor,
                    highlightColor: Theme.of(context).highlightColor,
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Padding(
                          padding:
                          const EdgeInsets
                              .all(
                              15.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chevron_right, size: 150),
                              SizedBox(width: 10),
                              Text("Next Page", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              onTap: () {
                toCut += 12;
                updateGrid();
              },
            );
          }
      );
    }
    if (i == 2) {
      return Builder(
          builder: (context) {
            return Opacity(
              opacity: 0.75,
              child: Card(
                child: InkWell(
                  splashColor: Theme.of(context).splashColor,
                  highlightColor: Theme.of(context).highlightColor,
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets
                            .all(
                            15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              child: SizedBox(
                                child: Column(
                                  children: [
                                    Icon(Icons.chevron_left, size: 125),
                                    SizedBox(height: 10),
                                    Text("Previous", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700))
                                  ],
                                ),
                              ),
                              onTap: () {
                                toCut -= 12;
                                updateGrid();
                              },
                            ),
                            SizedBox(width: 10),
                            SizedBox(height: 200, child: VerticalDivider()),
                            SizedBox(width: 10),
                            GestureDetector(
                              child: SizedBox(
                                child: Column(
                                  children: [
                                    Icon(Icons.chevron_right, size: 125),
                                    SizedBox(height: 10),
                                    Text("Next", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700))
                                  ],
                                ),
                              ),
                              onTap: () {
                                toCut += 12;
                                updateGrid();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
      );
    }
    if (i == 3) {
      return Builder(
          builder: (context) {
            return GestureDetector(
              child: Opacity(
                opacity: 0.75,
                child: Card(
                  child: InkWell(
                    splashColor: Theme.of(context).splashColor,
                    highlightColor: Theme.of(context).highlightColor,
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Padding(
                          padding:
                          const EdgeInsets
                              .all(
                              15.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chevron_left, size: 150),
                              SizedBox(height: 10),
                              Text("Previous Page", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              onTap: () {
                toCut -= 12;
                updateGrid();
              },
            );
          }
      );
    }
    if (i == 4) {
      return Builder(
          builder: (context) {
            return Opacity(
              opacity: 0.75,
              child: Card(
                child: InkWell(
                  splashColor: Theme.of(context).splashColor,
                  highlightColor: Theme.of(context).highlightColor,
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets
                            .all(
                            15.0),
                        child: SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
      );
    }
  }

  dialogText(String text) {
    return AutoSizeText(text,
        style: TextStyle(
            fontSize: 30,
            fontWeight:
            FontWeight.w700),
        textAlign: TextAlign.center,
        maxLines: 2);
  }

  genderDialog() async {


    final result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Gender"),
        content: Container(
            height: 400,
            width: 400,
            child: GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.pop(context, "Male");
                    },
                    child: Card(
                      child: Center(child: dialogText("Male")),
                    )),
                GestureDetector(
                    onTap: () {
                      Navigator.pop(context, "Female");
                    },
                    child: Card(
                      child: Center(child: dialogText("Female")),
                    )),
                GestureDetector(
                    onTap: () {
                      Navigator.pop(context, "Other");
                    },
                    child: Card(
                      child: Center(child: dialogText("Other")),
                    ))
              ],
            )),

      ),
    );

    return result;
  }

  nameDialog() {
    TextEditingController name = TextEditingController();

    final result = showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Enter Name"),
        content: Container(
            height: 60,
            width: 200,
            child: TextField(
                controller: name,
                decoration: InputDecoration(labelText: "Name"))),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context, name.text);
              },
              child: Text(""
                  "Submit"))
        ],
      ),
    );

    return result;
  }

  priorityDialog() async {
    final result = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Select Priorities (If Applicable)"),
          content: FutureBuilder(
            future: getPriority(),
            builder: (BuildContext context,
                AsyncSnapshot<List<dynamic>> snapshot) {

              return snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!.isNotEmpty
                  ? Container(
                height: 400,
                width: 400,
                child: GridView.builder(
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, i) {
                      final priority =
                      Priority.fromJson(snapshot.data![i]);
                      return Padding(
                        padding: EdgeInsets.all(10),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context, priority.priorityName!);
                          },
                          child: Card(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                AutoSizeText(priority.priorityName!,
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight:
                                        FontWeight.w700),
                                    textAlign: TextAlign.center,
                                    maxLines: 2)
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              )
                  : Container(
                height: 300,
                child: Center(
                  child: Text(
                    "No Priorites added.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
                  : Container(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ));
    return result;
  }

  getTicketSQLPrint(String serviceCode) async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php?today=true');

      final result = await http.get(uri).timeout(const Duration(seconds: 8));

      if (result.statusCode != 200) {
        throw Exception("Failed to retrieve today's tickets.");
      }

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response
          .where((e) => e['serviceCode'] == serviceCode)
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

  getTicketSQL(String serviceCode) async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri).timeout(const Duration(seconds: 8));

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response
          .where((e) =>
      toDateTime(DateTime.parse(e['timeCreated'])) ==
          toDateTime(DateTime.now()) &&
          e['serviceCode'] == serviceCode)
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

  bool _creatingTicket = false;

  addTicketSQL(String serviceType, String serviceCode, [String? priorityType, String? ticketName, String? gender]) async {
    if (_creatingTicket == true)  {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ticket currently being generated")));
      return;
    };

    _creatingTicket = true;


    try {
      final String timestamp = DateTime.now().toString();

      final List<Ticket> tickets = await getTicketSQLPrint(serviceCode);
      final thisDay = tickets.where((e) {
        final eDate = toDateTime(e.timeCreatedAsDate!).toString();
        final today = toDateTime(DateTime.now()).toString();
        return eDate == today;
      }).toList();

      final number = thisDay.length + 1;
      final numberParsed = number.toString().padLeft(3, '0');

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
        "log": "$timestamp: ticketGenerated $serviceType",
        "priority": priorityType == "" || priorityType == "Regular" ? 0 : 1,
        "priorityType": priorityType == "" ? "Regular" : priorityType,
        "printStatus": 1,
        "callCheck": 0,
        "ticketName": ticketName ?? "",
        "blinker": 0,
        "gender": gender
      };

      if (usb?.selectedDevice == null) await _handlePrinter();

      int value = 0; // debug

      if (usb?.selectedDevice == null) {
        int? valueBlue = await printer.ticket("$serviceCode$numberParsed",
            "$timestamp", "$priorityType", "$ticketName");
        value = valueBlue ?? 0;
      } else {
        try {
          final valueUSB = await usb!.buildTicketQueue("$serviceCode$numberParsed", "$timestamp", "$priorityType", "$ticketName");
          value = valueUSB ?? 0;
        } catch(e) {
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
        }
      }


      // value == 0 to generate Tickets without printer.

      final codeAndNumber = "$serviceCode$numberParsed";

      if (value == 1) {
        final result = await http.post(uri, body: jsonEncode(body)).timeout(const Duration(seconds: 8));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ticket Created Successfully")));

        NodeSocketService().sendMessage('createTicket', {});

        _addRecentTicket(codeAndNumber, printed: true);
        _showTicketNumberDialog(codeAndNumber, printed: true);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No Printer Connected.")));

        _addRecentTicket(codeAndNumber, printed: false);
        _showTicketNumberDialog(codeAndNumber, printed: false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));

      print(e);


    }

    finally {
      _creatingTicket = false;
    }
  }

  bool _handlingPrinter = false;

  _handlePrinter() async {
    if (kIsWeb || usb == null) return;
    if (_handlingPrinter) return;
    _handlingPrinter = true;

    try {
      final dynamic saved = await getPrinter();

      // Saved as Bluetooth: leave USB alone
      if (saved == 'BT') {
        usb!.selectedDevice = null;
        return;
      }

      // 1. Try the saved USB printer
      if (saved != null && saved != "") {
        final parts = saved.toString().split("_");
        if (parts.length >= 3) {
          final vendorId = parts.last;
          final productId = parts[parts.length - 2];
          final name = parts.sublist(0, parts.length - 2).join("_");
          if (await usb!.connectDevice(
              PrinterDevice(name: name, productId: productId, vendorId: vendorId))) {
            return;
          }
        }
      }

      // 2. Saved one missing/stale: auto-detect the first USB printer
      final found = await usb!.scanUsb();
      if (found.isNotEmpty) {
        final d = found.first;
        if (await usb!.connectDevice(d)) {
          await savePrinter("${d.name}_${d.productId}_${d.vendorId}");
          return;
        }
      }

      // 3. No USB printer: Bluetooth path. Saved value is not erased.
      usb!.selectedDevice = null;
    } catch (e) {
      print(e);
    } finally {
      _handlingPrinter = false;
    }
  }

  getServiceGroups(String assignedGroup) async {
    try {

      _handlePrinter();

      final uriGroup = Uri.parse('http://$site/queueing_api/api_serviceGroup.php');
      final resultGroup = await http.get(uriGroup).timeout(const Duration(seconds: 8));
      List<dynamic> responseGroup = jsonDecode(resultGroup.body);

      final uriService = Uri.parse('http://$site/queueing_api/api_service.php');
      final resultService = await http.get(uriService).timeout(const Duration(seconds: 8));
      List<dynamic> responseService = jsonDecode(resultService.body);

      List<dynamic> resultsToReturn = [];

      for (int i = 0; i < responseGroup.length; i++) {
        if (responseGroup[i]['assignedGroup'] == assignedGroup){
          resultsToReturn.add(responseGroup[i]);
        }
      }

      for (int i = 0; i < responseService.length; i++) {
        if (responseService[i]['assignedGroup'] == assignedGroup){
          resultsToReturn.add(responseService[i]);
        }
      }

      resultsToReturn.sort((a, b) {
        int aIndex = int.tryParse(a['displayIndex'].toString()) ?? 0;
        int bIndex = int.tryParse(b['displayIndex'].toString()) ?? 0;
        return aIndex.compareTo(bIndex);
      });


      return resultsToReturn;


    } catch(e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }

  List<dynamic>? _priorityCache;
  DateTime? _priorityCacheTime;

  getPriority() async {
    // reuse the last result for 5 minutes
    if (_priorityCache != null &&
        _priorityCacheTime != null &&
        DateTime.now().difference(_priorityCacheTime!).inMinutes < 5) {
      return _priorityCache;
    }

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_priorities.php');
      final result = await http.get(uri).timeout(const Duration(seconds: 8));
      List<dynamic> response = jsonDecode(result.body);
      response.add({"priorityName": "Regular", "id": 9999.toString()});

      _priorityCache = response;
      _priorityCacheTime = DateTime.now();
      return response;
    } catch (e) {
      // server slow or down: use the last good list if there is one
      if (_priorityCache != null) return _priorityCache;
      rethrow;
    }
  }

  Future<void> initPlatformState() async {
    var statusLocation = Permission.location;
    if (await statusLocation.isGranted != true) {
      await Permission.location.request();
    }
    if (await statusLocation.isGranted) {
    } else {}
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {}

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          _connected = true;
          usb?.selectedDevice = null;
          savePrinter('BT');
          setState(() {
            print("bluetooth device state: connected");
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          _connected = false;
          setState(() {
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
        device.name == "ILITEK-TP" ? () {}  : items.add(DropdownMenuItem(
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
            _connected = false;
          });
          savePrinter('BT');
          usb?.selectedDevice = null;
          _connected = true;
        }
      });
    } else {
      show('No device selected.');
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    _connected = false;
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

  getKioskControl() async {
    try {
      final List<dynamic> controls = await getSettings(context);
      final result = controls.where((e) => e['controlName'] == "Kiosk Password").toList()[0];
      final Control kioskControl = Control.fromJson(result);
      return kioskControl;
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("For security, server connection required.")));
      print(e);
    }

  }

  printerSettingDialog() {
    return
      showDialog(
          context: context,
          builder: (_) => FutureBuilder(
            future: initPlatformState(),
            builder: (BuildContext context,
                AsyncSnapshot<void> snapshot) {



              return AlertDialog(
                  title: Text('Printer Set-up'),
                  content: Container(
                    height: 140,
                    width: 300,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          child: Row(
                            children: [
                              Text("Wired Printer", style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
                              SizedBox(width: 5),
                              Icon(Icons.usb)
                            ],
                          ),
                          onPressed: () {
                            try {
                              if (!kIsWeb) {
                                showDialog(
                                    context: context,
                                    builder: (_) =>
                                        usb?.interface());
                              } else {
                                ScaffoldMessenger.of(
                                    context)
                                    .showSnackBar(SnackBar(
                                    content: Text(
                                        "Android Device Support Only.")));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(
                                  context)
                                  .showSnackBar(SnackBar(
                                  content:
                                  Text("Android Device Support Only.")));
                            }
                          },
                        ),
                        TextButton(
                            child: Row(
                              children: [
                                Text("Bluetooth", style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
                                SizedBox(width: 5),
                                Icon(Icons.bluetooth)
                              ],
                            ),
                            onPressed: () {
                              try {
                                if (!kIsWeb) {
                                  showDialog(
                                      context: context,
                                      builder: (_) =>
                                          StatefulBuilder(
                                            builder: (BuildContext context, void Function(void Function()) setStateDialog) {
                                              return AlertDialog(
                                                  content:
                                                  Padding(
                                                    padding:
                                                    const EdgeInsets
                                                        .all(
                                                        8.0),
                                                    child:
                                                    Container(
                                                      height: 200,
                                                      width: 400,
                                                      child:
                                                      ListView(
                                                        children: <Widget>[
                                                          Row(
                                                            crossAxisAlignment:
                                                            CrossAxisAlignment.center,
                                                            mainAxisAlignment:
                                                            MainAxisAlignment.start,
                                                            children: <Widget>[
                                                              const SizedBox(
                                                                  width: 10),
                                                              const Text(
                                                                'Device:',
                                                                style:
                                                                TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 30),
                                                              Expanded(
                                                                child:
                                                                DropdownButton(
                                                                  items: _getDeviceItems(),
                                                                  onChanged: (BluetoothDevice? value) {
                                                                    _device = value;
                                                                    _connect;

                                                                    setStateDialog((){});
                                                                    setState(() {});
                                                                  },
                                                                  value: _device,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height:
                                                              10),
                                                          Row(
                                                            crossAxisAlignment:
                                                            CrossAxisAlignment.center,
                                                            mainAxisAlignment:
                                                            MainAxisAlignment.end,
                                                            children: <Widget>[
                                                              ElevatedButton(
                                                                style:
                                                                ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                                                                onPressed:
                                                                    () async {
                                                                  await initPlatformState();
                                                                },
                                                                child:
                                                                const Text(
                                                                  'Refresh',
                                                                  style: TextStyle(color: Colors.white),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  width: 20),
                                                              ElevatedButton(
                                                                style:
                                                                ElevatedButton.styleFrom(backgroundColor: _connected ? Colors.red : Colors.green),
                                                                onPressed: () {
                                                                  if (_connected == false) {
                                                                    _connect();
                                                                    setState(() {});
                                                                    setStateDialog((){});
                                                                  } else {
                                                                    _disconnect();
                                                                    setState(() {});
                                                                    setStateDialog((){});
                                                                  }
                                                                },
                                                                child:
                                                                Text(
                                                                  _connected ? 'Disconnect' : 'Connect',
                                                                  style: TextStyle(color: Colors.white),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets
                                                                .only(
                                                                left:
                                                                10.0,
                                                                right:
                                                                10.0,
                                                                top:
                                                                50),
                                                            child:
                                                            ElevatedButton(
                                                              style:
                                                              ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                                                              onPressed:
                                                                  () {
                                                                printer.sample();
                                                              },
                                                              child: const Text(
                                                                  'PRINT TEST',
                                                                  style: TextStyle(color: Colors.white)),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ));
                                            },
                                          ));
                                } else {
                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(SnackBar(
                                      content: Text(
                                          "Android Device Support Only.")));
                                }
                              } catch(e) {
                                ScaffoldMessenger.of(
                                    context)
                                    .showSnackBar(SnackBar(
                                    content: Text(
                                        "Android Device Support Only.")));
                              }
                            }),
                      ],
                    ),
                  ));
            },
          ));
  }

  settingSecurity() async {

    final Control kioskControl = await getKioskControl();
    TextEditingController pass = TextEditingController();
    bool obscure = true;


    if (kioskControl.value! == 1) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text("Printer Settings"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 120,
              child: Column(
                children: [
                  TextField(
                    onSubmitted: (value) {
                      if (pass.text == kioskControl.other!) {
                        Navigator.pop(context);
                        printerSettingDialog();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password Incorrect")));
                      }
                    },
                    controller: pass,
                    obscureText: obscure,
                    decoration: InputDecoration(
                        labelText: 'Kiosk Password'
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        IconButton(onPressed: () {
                          obscure = !obscure;
                          setState((){});
                        }, icon: obscure == true ? Icon(Icons.remove_red_eye_outlined) : Icon(Icons.remove_red_eye)),
                        TextButton(onPressed: () {
                          if (pass.text == kioskControl.other!) {
                            Navigator.pop(context);
                            printerSettingDialog();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password Incorrect")));
                          }
                        }, child: Text("Access")),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ));
    } else {
      printerSettingDialog();
    }
  }


  settingSecurityPin() async {

    final Control kioskControl = await getKioskControl();
    TextEditingController pass = TextEditingController();
    bool obscure = true;

    if (kioskControl.value! == 1) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text("Unlock Pin"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 120,
              child: Column(
                children: [
                  TextField(
                    onSubmitted: (value) {
                      if (pass.text == kioskControl.other!) {
                        final intent = AndroidIntent(
                          action: 'android.settings.HOME_SETTINGS',
                          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                        );
                        intent.launch();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password Incorrect")));
                      }
                    },
                    controller: pass,
                    obscureText: obscure,
                    decoration: InputDecoration(
                        labelText: 'Kiosk Password'
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        IconButton(onPressed: () {
                          obscure = !obscure;
                          setState((){});
                        }, icon: obscure == true ? Icon(Icons.remove_red_eye_outlined) : Icon(Icons.remove_red_eye)),
                        TextButton(onPressed: () {
                          if (pass.text == kioskControl.other!) {
                            final intent = AndroidIntent(
                              action: 'android.settings.HOME_SETTINGS',
                              flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password Incorrect")));
                          }
                        }, child: Text("Access")),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ));
    } else {
      final intent = AndroidIntent(
        action: 'android.settings.HOME_SETTINGS',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      intent.launch();
    }
  }

  getRainbowOverlay() {
    return FutureBuilder(
        future: getSettings(context, 'RGB Screen (Kiosk)', 1),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          return snapshot.connectionState == ConnectionState.done ?
          int.parse(snapshot.data!['value']) != null ?
          Builder(
              builder: (context) {
                int visible = int.parse(snapshot.data!['other'].toString().split(":")[0]);
                final invisible = int.parse(snapshot.data!['other'].toString().split(":")[1]);
                final opacity = double.parse(snapshot.data!['other'].toString().split(":")[2]);
                final always = int.parse(snapshot.data!['other'].toString().split(":")[3]) == 1 ? true : false;

                return RainbowOverlay(visible: visible, invisible: invisible, always: always);
              }
          ) :
          SizedBox() : SizedBox();
        });
  }

  getBackgroundVideoOverlay() {
    return FutureBuilder(
        future: getSettings(context, 'BG Video (Kiosk)'),
        builder: (context, snapshot) {
          return snapshot.connectionState == ConnectionState.done ?
          snapshot.data! == 1 ?
          FutureBuilder(
            future: getMediabg(context),
            builder: (context, AsyncSnapshot<List<dynamic>> snapshotMedia) {
              return snapshotMedia.connectionState == ConnectionState.done ?
              Builder(
                  builder: (context) {
                    final List<dynamic> mediabg = snapshotMedia.data!;
                    List<String> links = [];

                    for (int i = 0; i < mediabg.length; i++) {
                      try {
                        links.add("http://$site/queueing_api/bgvideos/${mediabg[i]['link']}");
                      } catch(e) {
                        print('file not found, has record on server');
                      }
                    }

                    return links.isEmpty ? SizedBox() : WebVideoPlayer(videoAssets: links, display: 0);
                  }
              ) :
              SizedBox();
            },
          ) :
          graphicBackground(context) : SizedBox();
        });
  }


}

class ServicesScreenSaver extends StatefulWidget {
  const ServicesScreenSaver({super.key});

  @override
  State<ServicesScreenSaver> createState() => _ServicesScreenSaverState();
}

class _ServicesScreenSaverState extends State<ServicesScreenSaver> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              imageBackground(context),
              logoBackground(context, 500, null, 1),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 50),
                      child: Text(
                        "Tap to Start",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w700),
                      ))),
              RainbowOverlay(always: true)
            ],
          ),
        ),
      ),
    );
  }
}