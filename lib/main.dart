import 'dart:ui';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
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
      home: autoDisplay(context, 1),
      // 0: Phone, 1: Kiosk, Display
      //
    );
  }

}


autoDisplay(BuildContext context, int i) {
  return i == 1 ? FutureBuilder(
      future: ipHandler(context),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        // 0: Display, 1: Services
        return snapshot.connectionState == ConnectionState.done ? snapshot.data == 1 ? DisplayScreen() : BootInterface(type: 0) :
        Scaffold(
            body: Stack(
              children: [
                imageBackground(context),
                logoBackground(context, 500, 500),
                Center(
                  child: Container(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ));
      }) : LoginScreen(debug: 0);
}

ipHandler(BuildContext context) async {
  try {
    await getIP();
    final List<dynamic> controls = await getSettings();

    print("controls: $controls");
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
    return Scaffold(
      body: Stack(
        children: [
          imageBackground(context),
          logoBackground(context, 500, 500),
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
                      Text("Queueing App ${widget.type == 1 ? "Kiosk" : "Display"}", style: TextStyle(fontFamily: 'Inter', fontSize: 20), textAlign: TextAlign.center),
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
                              Navigator.push(context, MaterialPageRoute(builder: (_) => widget.type == 1 ? ServicesScreen() : DisplayScreen()));
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
      ),
    );
  }
}







