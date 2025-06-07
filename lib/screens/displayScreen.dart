import 'dart:async';
import 'dart:convert';
import 'package:marquee/marquee.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';
import '../models/ticket.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {

  late Timer timer;
  int ticketsLength = 0;

  Color? containerColor;

  @override
  Widget build(BuildContext context) {

    containerColor = Theme.of(context).cardTheme.color;
    return Scaffold(
      body: Stack(
        children: [
          MediaQuery.of(context).size.width > 1500 ? logoBackground(context) : Container(),
          Column(
            children: [
              MediaQuery.of(context).size.width > 1500 ? Column(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      height: 70,
                      child: Text("Now Serving", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700))),
                  StatefulBuilder(
                    builder: (BuildContext context, void Function(void Function()) setStateHere) {
          
                      timer = Timer.periodic(Duration(seconds: 3, milliseconds: 0), (value) async {
                        final List<Ticket> retrieved = await getTicketSQL();
          
                        if (retrieved.length != ticketsLength) {
                          final List<Ticket> toUpdate = retrieved.where((e) => e.callCheck == 0).toList();
                          if (toUpdate.isNotEmpty) {
                            for (int i = 0; i < toUpdate.length; i++) {
                              await toUpdate[i].update({
                                "id": toUpdate[i].id,
                                "callCheck": 1
                              });
                            }
                            ticketsLength = retrieved.length;
                            AudioPlayer player = AudioPlayer();
                            player.play(AssetSource('sound.mp3'));
                            print("Sound");
                            setStateHere((){});
                          }
          
                          ticketsLength = retrieved.length;
                          setStateHere((){});
                        } else {
                          final List<Ticket> toUpdate = retrieved.where((e) => e.callCheck == 0).toList();
                          toUpdate.forEach((value){
                            print("update id: ${value.id} call: ${value.callCheck}");
                          });
          
                          if (toUpdate.isNotEmpty) {
                            for (int i = 0; i < toUpdate.length; i++) {
                              await toUpdate[i].update({
                                "id": toUpdate[i].id,
                                "callCheck": 1
                              });
                            }
          
                            ticketsLength = retrieved.length;
                            AudioPlayer player = AudioPlayer();
                            player.play(AssetSource('sound.mp3'));
                            print("Sound");
          
                            setStateHere((){});
          
                          }
                        }
          
          
                      });
          
                      return FutureBuilder(
                        future: getTicketSQL(),
                        builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshot) {
                          return snapshot.connectionState == ConnectionState.done ? snapshot.data!.length != 0 ? Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(20),
                                height: MediaQuery.of(context).size.height - 340,
                                width: MediaQuery.of(context).size.width * 3/4,
                                child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
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
                                    }),
                              ),
                              StatefulBuilder(
                                builder: (BuildContext context, void Function(void Function()) setStateCard) {
                                  return Container(
                                    height: 400,
                                    width: MediaQuery.of(context).size.width * 1/4 - 100,
                                    child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child:
                                        TweenAnimationBuilder<Color?>(
                                          tween: ColorTween(
                                            begin: Colors.red,
                                            end: Colors.white70,
                                          ),
                                          duration: Duration(seconds: 10),
                                          builder: (context, color, child) {
                                            return Card(
                                              color: color,
                                              clipBehavior: Clip.antiAlias,
                                              child: Padding(
                                                padding: const EdgeInsets.all(30.0),
                                                child: Container(
                                                  height: 350,
                                                  width: 250,
                                                  child: Column(
                                                    children: [
                                                      Text("${snapshot.data!.last.serviceType}", style: TextStyle(fontSize: 30)),
                                                      Text("${snapshot.data!.last.serviceCode}${snapshot.data!.last.number}", style: TextStyle(fontSize: 30)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        )
          
          
                                    ),
                                  );
                                },
                              )
                            ],
                          ) : Container(
                              height: 650,
                              child: Center(child: Text("No Tickets Serving", style: TextStyle(color: Colors.grey)))) : Container(
                            height: 100,
                            width: 100,
                            child: CircularProgressIndicator(),
                          );
                        },
                      );
                    },
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
                  )),
              MediaQuery.of(context).size.width > 1500 ? Container(
                height: 50,
                child: Marquee(
                  text: '    Office of the Ombudsman, Davao City    ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 40),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  blankSpace: 20.0,
                  velocity: 100.0,
                  pauseAfterRound: Duration(seconds: 1),
                  startPadding: 10.0,
                  accelerationDuration: Duration(seconds: 1),
                  accelerationCurve: Curves.linear,
                  decelerationDuration: Duration(milliseconds: 500),
                  decelerationCurve: Curves.easeOut,
                ),
              ) : Container()
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Ticket>> getTicketSQL() async {


    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response.where((e) => e['status'] == "Serving").toList();
      List<Ticket> newTickets = [];

      for (int i = 0; i< sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a,b) => DateTime.parse(a.timeTaken!).compareTo(DateTime.parse(b.timeTaken!)));

      return newTickets;

    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }

  }
}
