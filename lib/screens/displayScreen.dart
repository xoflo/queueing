import 'dart:async';
import 'dart:convert';
import 'package:marquee/marquee.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';
import 'package:video_player/video_player.dart';
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
  void dispose() {
    timer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    containerColor = Theme.of(context).cardTheme.color;
    return Scaffold(
      body: FutureBuilder(
        future: getSettings(context, 'Video in Queue Display'),
        builder: (BuildContext context, AsyncSnapshot<dynamic> vqd) {
          return vqd.connectionState == ConnectionState.done ? Stack(
            children: [
              vqd.data == 1 ? Container() : logoBackground(context),
              Column(
                children: [
                  MediaQuery.of(context).size.width > 1500 ? Column(
                    children: [
                      vqd.data == 0 ? Container(
                          padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                          height: 70,
                          child: Text("Now Serving", style: TextStyle(fontSize: 60, fontWeight: FontWeight.w700))) : Container(
                        height: 30
                      ),
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
                                setStateHere((){});
                              }

                              ticketsLength = retrieved.length;
                              setStateHere((){});
                            } else {
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
                                setStateHere((){});
                              }
                            }
                          });

                          return FutureBuilder(
                            future: getTicketSQL(),
                            builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshot) {
                              return snapshot.connectionState == ConnectionState.done ? vqd.data == 1 ?
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  children: [
                                    FutureBuilder(
                                      future: getMedia(context),
                                      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                                        return snapshot.connectionState == ConnectionState.done ?  Builder(
                                          builder: (context) {

                                            List<String> links = stringToList(snapshot.data.toString());
                                            int videoCounter = 0;

                                            return StatefulBuilder(
                                              builder: (BuildContext context, void Function(void Function()) setStatePlayer) {

                                                VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse('http://$site/videos/${links[videoCounter]}'))..initialize().then((value) {
                                                  setStatePlayer((){});
                                                });

                                                controller.play();
                                                controller.addListener(() {
                                                  if (controller.value.position >= controller.value.duration &&
                                                      !controller.value.isPlaying) {
                                                    if (videoCounter == links.length) {
                                                      videoCounter = 0;
                                                      setStatePlayer((){});
                                                    } else {
                                                      videoCounter++;
                                                      setStatePlayer((){});
                                                    }
                                                  }
                                                });

                                                return Container(
                                                    child: VideoPlayer(controller),
                                                    width: MediaQuery.of(context).size.width - 600,
                                                    height: MediaQuery.of(context).size.height - 300
                                                );
                                              },
                                            );
                                          }
                                        ) : Center(
                                          child: Container(
                                            height: 50,
                                            width: 50,
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 30),
                                    Column(
                                      children: [
                                        Container(
                                            height: 40,
                                            child: Text("Now Serving", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700))),
                                        SizedBox(height: 10),
                                        Container(
                                          width: 500,
                                          height: 600,
                                          padding: EdgeInsets.all(10),
                                          child: Stack(
                                            children: [
                                              logoBackground(context, 250, 300),
                                              snapshot.data!.length != 0 ? ListView.builder(
                                                  itemCount: snapshot.data!.length,
                                                  itemBuilder: (context, i) {
                                                    final ticket = snapshot.data![i];
                                                    return Container(
                                                      height: 80,
                                                      child: Padding(
                                                        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Text("${ticket.stationName!} ${ticket.stationNumber!} ", style: TextStyle(fontSize: 40)),
                                                            Spacer(),
                                                            Text(ticket.codeAndNumber!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 40)),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }) : Center(
                                                child: Text("No Tickets Pending", style: TextStyle(color: Colors.grey)),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ) : snapshot.data!.length != 0 ?
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    height: MediaQuery.of(context).size.height - 340,
                                    width: MediaQuery.of(context).size.width * 3/4,
                                    child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                                        itemCount: snapshot.data!.length,
                                        itemBuilder: (context, i) {
                                        final ticket = snapshot.data![i];

                                          return Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Card(
                                              child: Padding(
                                                padding: const EdgeInsets.all(30.0),
                                                child: Column(
                                                  children: [
                                                    Text(ticket.serviceType!, style: TextStyle(fontSize: 30)),
                                                    Text(ticket.codeAndNumber!, style: TextStyle(fontSize: 30)),
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
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Text("${snapshot.data!.last.serviceType}", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
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
                              )
                                  : Container(
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
                  SizedBox(height: 100),
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
          ) : Container(
            height: MediaQuery.of(context).size.height,
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
