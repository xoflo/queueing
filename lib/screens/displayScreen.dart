import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/ticket.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {


  late Timer timer;

  int ticketsLength = 0;

  @override
  void initState() {
    timer = Timer.periodic(Duration(seconds: 2, milliseconds: 500), (value) async {
      final List<Ticket> retrieved = await getTicketSQL();


      if (ticketsLength == retrieved.length) {
        print("noSound");
      } else {

        retrieved.forEach((e) {
          print("id: ${e.id}, callcheck:${e.callCheck}");
        });

        final List<Ticket> toUpdate = retrieved.where((e) => e.callCheck == 0).toList();
        print("toUpdateLength: ${toUpdate.length}");

        if (toUpdate.isNotEmpty) {
          print("toUpdateLength: ${toUpdate.length}");

          for (int i = 0; i < toUpdate.length; i++) {
            await toUpdate[i].update({
              "id": toUpdate[i].id,
              "callCheck": 1
            });
            print("updated$i");
          }

          ticketsLength = retrieved.length;
          AudioPlayer player = AudioPlayer();
          player.play(AssetSource('sound.mp3'));
          print("Sound");
          setState(() {});
        } else {
          ticketsLength = retrieved.length;
          setState(() {

          });
        }

      }

    });

    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: [
          MediaQuery.of(context).size.width > 1500 ? Row(
            children: [
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      height: 70,
                      child: Text("Now Serving", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700))),
                  FutureBuilder(
                    future: getTicketSQL(),
                    builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshot) {
                      return Container(
                        padding: EdgeInsets.all(20),
                        height: MediaQuery.of(context).size.height - 340,
                        width: MediaQuery.of(context).size.width * 3/4,
                        child: snapshot.connectionState == ConnectionState.done ? snapshot.data!.length != 0 ? GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, i) {
                              return Padding(
                                padding: const EdgeInsets.all(5),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(30.0),
                                    child: Column(
                                      children: [
                                        Text("${snapshot.data![i].serviceType}", style: TextStyle(fontSize: 30)),
                                        Text("${snapshot.data![i].serviceCode}${snapshot.data![i].number}", style: TextStyle(fontSize: 30)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }) : Center(child: Text("No Tickets Pending", style: TextStyle(color: Colors.grey))) : Container(),
                      );
                    },
                  ),
                ],
              ),

              Container(
                width: MediaQuery.of(context).size.width * 1/4,
                child: Center(child: Text("Ombudsman")),
              ),
            ],
          ) : Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Expand Window to Display Queue", style: TextStyle(fontSize: 50), textAlign: TextAlign.center),
                  Text("This display only supports TV Display use", style: TextStyle(fontSize: 30, color: Colors.grey), textAlign: TextAlign.center),
                ],
              ))
        ],
      ),
    );
  }

  Future<List<Ticket>> getTicketSQL() async {
    int port = 80;

    try {
      final uri = Uri.parse('http://localhost:$port/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response.where((e) => e['status'] == "Serving").toList();
      List<Ticket> newTickets = [];

      for (int i = 0; i< sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a,b) => DateTime.parse(a.timeCreated!).compareTo(DateTime.parse(b.timeCreated!)));

      return newTickets;

    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }
}
