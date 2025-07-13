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
      home: LoginScreen(),
      //
    );
  }

}


class KioskScreenBoot extends StatefulWidget {
  const KioskScreenBoot({super.key});

  @override
  State<KioskScreenBoot> createState() => _KioskScreenBootState();
}

class _KioskScreenBootState extends State<KioskScreenBoot> {
  @override
  Widget build(BuildContext context) {
    TextEditingController ip = TextEditingController();
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            imageBackground(context),
            logoBackground(context),
            Center(
              child: TextButton(onPressed: () {
                showDialog(
                    barrierDismissible: false,
                    context: context, builder: (_) => AlertDialog(
                  title: Text("Connect to Server"),
                  content: FutureBuilder(
                    future: getIP(),
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      return snapshot.connectionState == ConnectionState.done ? Builder(
                          builder: (context) {
                            ip.text = snapshot.data ?? "";

                            return Container(
                              height: 100,
                              child: Column(
                                children: [
                                  TextField(
                                    decoration: InputDecoration(
                                        labelText: 'IP Address'
                                    ),
                                  )
                                ],
                              ),
                            );
                          }
                      ) : Container(
                        height: 100,
                        width: 100,
                        child: Center(
                          child: Container(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    },
                  ),
                  actions: [
                    TextButton(onPressed: () async {
                      await saveIP(ip.text);
                      final ipGet = await getIP();
                      print("ipGet: $ipGet");
                      if (ipGet == "") {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("IP Cannot be empty")));
                      } else {
                        final services = await getServiceSQL();
                      }
                    }, child: Text("Access"))
                  ],
                ));
              }, child: Text("Access Kiosk", style: TextStyle(fontSize: 20))),
            )
          ],
        ),
      ),
    );
  }
}


class DisplayScreenBoot extends StatefulWidget {
  const DisplayScreenBoot({super.key});

  @override
  State<DisplayScreenBoot> createState() => _DisplayScreenBootState();
}

class _DisplayScreenBootState extends State<DisplayScreenBoot> {
  @override
  Widget build(BuildContext context) {
    TextEditingController ip = TextEditingController();
    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            imageBackground(context),
            logoBackground(context),
            Center(
              child: TextButton(onPressed: () {
                showDialog(
                    barrierDismissible: false,
                    context: context, builder: (_) => AlertDialog(
                  title: Text("Connect to Server"),
                  content: FutureBuilder(
                    future: getIP(),
                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                      return snapshot.connectionState == ConnectionState.done ? Builder(
                          builder: (context) {
                            ip.text = snapshot.data ?? "";

                            return Container(
                              height: 100,
                              child: Column(
                                children: [
                                  TextField(
                                    decoration: InputDecoration(
                                        labelText: 'IP Address'
                                    ),
                                  )
                                ],
                              ),
                            );
                          }
                      ) : Container(
                        height: 100,
                        width: 100,
                        child: Center(
                          child: Container(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    },
                  ),
                  actions: [
                    TextButton(onPressed: () async {
                      await saveIP(ip.text);
                      final ipget = await getIP();
                      print("ip? $ipget");
                      final services = await getServiceSQL();


                    }, child: Text("Access"))
                  ],
                ));
              }, child: Text("Access Screen", style: TextStyle(fontSize: 20))),
            )
          ],
        ),
      ),
    );
  }
}





