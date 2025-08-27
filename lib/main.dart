import 'dart:convert';
import 'dart:ui';
import 'package:queueing/node.dart';
import 'package:queueing/screens/displayScreen.dart';
import 'package:queueing/screens/servicesScreen.dart';
import 'package:queueing/screens/staffScreen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:queueing/hiveService.dart';
import 'globals.dart';
import 'loginScreen.dart';

import 'models/user.dart';
import 'models/station.dart';

void main() async {


  WidgetsFlutterBinding.ensureInitialized();
  await WakelockPlus.enable();
  await Hive.initFlutter();
  await clearCache();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    NodeSocketService().connect(context: context);
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      scrollBehavior: ScrollBehavior().copyWith(dragDevices: {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
      }),
      debugShowCheckedModeBanner: false,
      title: 'Ombudsman Queueing App',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey),
      ),
      home: Scaffold(
        body: autoDisplay(context, 0),
      ),
      // 0: Phone, 1: Kiosk, Display
      //
    );
  }
}

/*
FutureBuilder(future: ipHandler(), builder: (context, AsyncSnapshot<int> snapshot) {
          return snapshot.connectionState == ConnectionState.done ? snapshot.data == 1 ? autoDisplay(context, 0) : BootInterface(type: 0) :
          Stack(
            children: [
              imageBackground(context),
              imageBackground(context),
              logoBackground(context, MediaQuery.of(context).size.width < 400 ? 350 : 500, MediaQuery.of(context).size.width < 400 ? 350 : 500),
              Center(
                child: Container(
                  height: 50,
                  width: 50,
                  child: CircularProgressIndicator(),
                ),

              ),
            ],
          );
        })
 */

autoDisplay(BuildContext context, int i) {
  if (i == 0) {
    return LoginScreen(debug: 0);
  }

  if (i == 1) {
    return ServicesScreen();
  }

  if (i == 2) {
    return DisplayScreen();
  }
}

ipHandler([BuildContext? context]) async {
  try {
    final ip = await getIP();
    NodeSocketService().connect();

    print(ip);
    final List<dynamic> controls = await getSettings();
    if (controls.isEmpty) {
      return 0;
    } else {
      return 1;
    }
  } catch(e) {
    return 0;
  }
}


class BootInterface extends StatefulWidget {
  BootInterface({super.key, required this.type});

  final int type;

  @override
  State<BootInterface> createState() => _BootInterfaceState();
}

class _BootInterfaceState extends State<BootInterface> {
  TextEditingController ipcont = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        imageBackground(context),
        logoBackground(context, MediaQuery.of(context).size.width < 500 ? 300 : 500, MediaQuery.of(context).size.width < 500 ? 300 : 500),
        Center(
          child: Opacity(
            opacity: 0.7,
            child: Card(
              child: Container(
                padding: EdgeInsets.all(40),
                height: 400,
                width: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Office of the Ombudsman\nfor Mindanao", style: TextStyle(fontFamily: 'BebasNeue', fontSize: 30), textAlign: TextAlign.center),
                    Text("Queueing App ${widget.type == 0 ? "Client": widget.type == 1 ? "Kiosk" : "Display"}", style: TextStyle(fontFamily: 'Inter', fontSize: 20), textAlign: TextAlign.center),
                    // Display, Kiosk
                    SizedBox(height: 20),
                    TextField(
                      controller: ipcont,
                      decoration: InputDecoration(
                          labelText: 'IP Address: (ex: 192.168.70.80)'
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 50,
                      width: 120,
                      child: TextButton(onPressed: () async {
                        await saveIP(ipcont.text);
                        final result = await ipHandler(context);

                        if (result == 1) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => widget.type == 0 ? LoginScreen(debug: 1) : widget.type == 1 ? ServicesScreen() : DisplayScreen()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server not found.")));
                        }


                      }, child: Text("Access")),
                    )
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}







