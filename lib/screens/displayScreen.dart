import 'dart:async';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:hive/hive.dart';
import 'package:marquee/marquee.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';
import 'package:queueing/models/media.dart';
import 'package:video_player/video_player.dart';
import '../models/ticket.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  late Timer timer;
  int ticketsLength = 0;
  Color? containerColor;

  final FlutterTts flutterTts = FlutterTts();

  final firstUpdate = GlobalKey();
  final secondUpdate = GlobalKey();


  Future<void> _speak(String code, String teller) async {
    await Future.delayed(Duration(seconds: 2, milliseconds: 250));
    await flutterTts.speak("$code, $teller");
  }

  constraint(BuildContext context, Widget widget) {
    return MediaQuery.of(context).size.height > 400 && MediaQuery.of(context).size.width > 400
        ? widget : Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Expand Window to Display Queue",
                style: TextStyle(fontSize: 50),
                textAlign: TextAlign.center),
            Text(
                "This display only supports TV Display use",
                style: TextStyle(
                    fontSize: 30, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ));

  }

  @override
  Widget build(BuildContext context) {
    containerColor = Theme.of(context).cardTheme.color;
    return Scaffold(
      body: FutureBuilder(
        future: getSettings(context, 'Video View (TV)'),
        builder: (BuildContext context, AsyncSnapshot<dynamic> vqd) {
          return vqd.connectionState == ConnectionState.done
              ? Stack(
                  children: [
                    constraint(context, getBackgroundVideoOverlay()),
                    vqd.data == 1 ?
                    Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        color: Colors.white60) : logoBackground(context),
                    constraint(context, getRainbowOverlay()),
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          constraint(context, Column(
                            children: [
                              topNowServingText(vqd.data),
                              Builder(
                                builder: (BuildContext context) {
                                  timerInit(vqd.data);

                                  return vqd.data == 1
                                      ? videoDisplayWidget()
                                      : noVideoDisplayWidget();
                                },
                              ),
                            ],
                          )),
                         //  slidingTextSpacer(vqd.data),
                          slidingTextWidget()
                        ],
                      ),
                    ),
                  ],
                )
              : Container(
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

  topNowServingText(int vqd) {
    return vqd == 0
        ? Container(
        padding:
        EdgeInsets.fromLTRB(0, 20, 0, 0),
        height: 70,
        child: Text("NOW SERVING",
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700)))
        : Container(height: 30);
  }

  timerInit(int vqd) {
    return timer = Timer.periodic(
        Duration(seconds: 3, milliseconds: 0),
            (value) async {
          final List<Ticket> retrieved =
          await getTicketSQL();
          if (retrieved.length != ticketsLength) {
            final List<Ticket> toUpdate =
            retrieved
                .where(
                    (e) => e.callCheck == 0)
                .toList();
            if (toUpdate.isNotEmpty) {

              Ticket? ticket;

              for (int i = 0;
              i < toUpdate.length;
              i++) {
                await toUpdate[i].update({
                  "id": toUpdate[i].id,
                  "callCheck": 1,
                });

                ticket = toUpdate[i];
              }
              ticketsLength = retrieved.length;
              AudioPlayer player = AudioPlayer();
              player
                  .play(AssetSource('sound.mp3'));
              if (ticket != null) {
                _speak(ticket.codeAndNumber!, "${ticket.stationName!}${ticket.stationNumber! != 0 ? ticket.stationNumber! : 0}");
              }
              if (vqd == 1) {
                secondUpdate.currentState!.setState(() {});
              } else {
                firstUpdate.currentState!.setState(() {});
              }
            }

            ticketsLength = retrieved.length;
            if (vqd == 1) {
              secondUpdate.currentState!.setState(() {});
            } else {
              firstUpdate.currentState!.setState(() {});
            }
          } else {

            Ticket? ticket;

            final List<Ticket> toUpdate =
            retrieved
                .where(
                    (e) => e.callCheck == 0)
                .toList();
            if (toUpdate.isNotEmpty) {
              for (int i = 0;
              i < toUpdate.length;
              i++) {
                await toUpdate[i].update({
                  "id": toUpdate[i].id,
                  "callCheck": 1,
                });

                ticket = toUpdate[i];
              }
              ticketsLength = retrieved.length;
              AudioPlayer player = AudioPlayer();
              player
                  .play(AssetSource('sound.mp3'));
              if (ticket != null) {
                _speak(ticket.codeAndNumber!, "${ticket.stationName!}${ticket.stationNumber! != 0 ? ticket.stationNumber! : 0}");
              }

              if (vqd == 1) {
                secondUpdate.currentState!.setState(() {});
              } else {
                firstUpdate.currentState!.setState(() {});
              }
            }
          }
        });
  }

  slidingTextSpacer(int vqd) {
    return SizedBox(height: vqd == 0 ? 120 : 100);
  }

  slidingTextWidget() {
    return Builder(builder: (context) {
      return MediaQuery.of(context).size.width > 600
          ? FutureBuilder(
        future: getSettings(context, 'Sliding Text', 1),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> slidingText) {

          return slidingText.connectionState == ConnectionState.done
              ? int.parse(slidingText.data!['value']) == 1 ? Container(
            height: 80,
            child: Marquee(
              text:
              slidingText.data!['other'].toString(),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontSize: 60),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              blankSpace: 100.0,
              velocity: 100.0,
              pauseAfterRound: Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration:
              Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          )
              : SizedBox(height: 50) : Padding(
            padding: const EdgeInsets.all(15.0),
            child: LinearProgressIndicator(),
          );
        },
      )
          : Container();
    });
  }

  videoDisplayWidget() {
    return Padding(
      padding:
      const EdgeInsets.all(15.0),
      child: Row(
        children: [
          FutureBuilder(
            future: getMedia(context),
            builder: (BuildContext
            context,
                AsyncSnapshot<
                    List<dynamic>>
                snapshotMedia) {
              return snapshotMedia
                  .connectionState ==
                  ConnectionState
                      .done
                  ? snapshotMedia.data!
                  .length !=
                  0
                  ? Builder(builder:
                  (context) {
                List<String>
                links =
                [];

                for (int i =
                0;
                i <
                    snapshotMedia
                        .data!
                        .length;
                i++) {
                  links.add("http://$site/queueing_api/videos/${snapshotMedia.data![i]['link']}");
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                      height: MediaQuery.of(
                          context)
                          .size
                          .height -
                          300,
                      width: MediaQuery.of(
                          context)
                          .size
                          .width -
                          600,
                      color: Colors
                          .black87,
                      child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: WebVideoPlayer(videoAssets: links, display: 1))),
                );
              })
                  : Container(
                color: Colors
                    .black87,
                width: MediaQuery.of(
                    context)
                    .size
                    .width -
                    600,
                height: MediaQuery.of(
                    context)
                    .size
                    .height -
                    300,
                child: Center(
                  child: Text(
                      "No videos uploaded",
                      style: TextStyle(
                          color:
                          Colors.white)),
                ),
              )
                  : Container(
                width: MediaQuery.of(
                    context)
                    .size
                    .width -
                    600,
                height: MediaQuery.of(
                    context)
                    .size
                    .height -
                    300,
                child: Center(
                  child:
                  Container(
                    height: 50,
                    width: 50,
                    child:
                    CircularProgressIndicator(),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 30),
          Column(
            children: [
              Container(
                  height: 50,
                  child: Text(
                      "NOW SERVING",
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight:
                          FontWeight
                              .w700))),
              SizedBox(height: 5),
              Builder(
                  builder: (context) {
                    return StatefulBuilder(
                      key: secondUpdate,
                      builder: (context,
                          setStateSecond) {

                        return FutureBuilder(
                          future: getTicketSQL(),
                          builder: (BuildContext
                          context,
                              AsyncSnapshot<
                                  List<
                                      Ticket>>
                              snapshot) {
                            return snapshot
                                .connectionState ==
                                ConnectionState
                                    .done
                                ? Container(
                              width:
                              500,
                              height:
                              600,
                              padding:
                              EdgeInsets.all(10),
                              child:
                              Stack(
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: logoBackground(
                                          context,
                                          250,
                                          300)
                                  ),
                                  snapshot.data!.length != 0
                                      ? ListView.builder(
                                      itemCount: snapshot.data!.length > 10 ? 10 : snapshot.data!.length,
                                      itemBuilder: (context, i) {
                                        final ticket = snapshot.data![i];
                                        return Column(
                                          children: [
                                            ticket.blinker == 0 ? Builder(
                                                builder: (context) {
                                                  ticket.update({
                                                    'blinker': 1
                                                  });

                                                  return TweenAnimationBuilder<Color?>(
                                                    tween: ColorTween(
                                                        begin: Colors.red,
                                                        end: i % 2 == 0 ? Colors.blueGrey.withAlpha(50) : Colors.transparent
                                                    ),
                                                    duration: Duration(seconds: 5),
                                                    builder: (BuildContext context, color, Widget? child) {
                                                      return Column(
                                                        children: [
                                                          Container(
                                                            color: color,
                                                            height: 80,
                                                            child: Padding(
                                                              padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Text(ticket.codeAndNumber!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 45)),
                                                                  Spacer(),
                                                                  FittedBox(child: Text("${ticket.stationName!.toUpperCase()} ${ticket.stationNumber!} ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 45))),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                            ) : Container(
                                              height: 80,
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(ticket.codeAndNumber!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 45)),
                                                    Spacer(),
                                                    FittedBox(child: Text("${ticket.stationName!.toUpperCase()} ${ticket.stationNumber!} ", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 45))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Divider()
                                          ],
                                        );
                                      })
                                      : Center(
                                    child: Text("No Tickets Pending", style: TextStyle(color: Colors.grey)),
                                  )
                                ],
                              ),
                            )
                                : Container(
                              width:
                              500,
                              height:
                              600,
                              padding:
                              EdgeInsets.all(10),
                              child:
                              Stack(
                                children: [
                                  ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: logoBackground(
                                          context,
                                          250,
                                          300)
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  }),
            ],
          )
        ],
      ),
    );
  }

  noVideoDisplayWidget() {
    return StatefulBuilder(
      key: firstUpdate,
      builder:
          (context, setStateFirst) {
        return FutureBuilder(
          future: getTicketSQL(),
          builder: (BuildContext context, AsyncSnapshot<List<Ticket>>snapshot) {
            return snapshot.connectionState == ConnectionState.done
                ? snapshot.data!
                .length !=
                0
                ? Container(
                  padding:
                  EdgeInsets.all(
                      20),
                  height: MediaQuery.of(context)
                      .size
                      .height -
                      200,
                  width: MediaQuery.of(context)
                      .size
                      .width,
                  child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: snapshot.data!.length < 9 ? 5 : 5),
                      itemCount: snapshot.data!.length < 9 ? snapshot.data!.length : 10,
                      itemBuilder: (context, i) {
                        final ticket = snapshot.data![i];
                        return ticket.blinker == 0 ?
                        Builder(
                            builder: (context) {
                              updateBlinker(ticket);
                              return TweenAnimationBuilder<Color?>(
                                tween: ColorTween(
                                    begin: Colors.red,
                                    end: Colors.transparent
                                ),
                                duration: Duration(seconds: 5),
                                builder: (BuildContext context, color, Widget? child) {
                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 2,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                            decoration: BoxDecoration(
                                                color: Colors.blueGrey.withAlpha(250)
                                            ),
                                            child: Center(child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: AutoSizeText("${ticket.stationName!}${ticket.stationNumber! == 0 || ticket.stationNumber! == null ? "" : " ${ticket.stationNumber!}"}".toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w700, fontFamily: 'BebasNeue')),
                                            ))),
                                        Center(child: AutoSizeText(ticket.codeAndNumber!, style: TextStyle(fontWeight: FontWeight.w700), maxFontSize: double.infinity))
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                        ) : Opacity(
                          opacity: 0.8,
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.withAlpha(250)
                                    ),
                                      child: Center(child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: FittedBox(child: Text("${ticket.stationName!}${ticket.stationNumber! == 0 || ticket.stationNumber! == null ? "" : " ${ticket.stationNumber!}"}".toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w700, fontFamily: 'BebasNeue'))),
                                      ))),
                                ),
                                Expanded(
                                  flex: 6,
                                  child: Center(child: FittedBox(child: Text(ticket.codeAndNumber!, style: TextStyle(fontSize: 60, fontWeight: FontWeight.w700)))),
                                )
                              ],
                            ),
                          ),
                        );


                      }),
                )
                : Container(
                height: MediaQuery.of(
                    context)
                    .size
                    .height -
                    340,
                width: MediaQuery.of(
                    context)
                    .size
                    .width *
                    3 /
                    4,
                child: Center(
                    child: Text(
                        "No Tickets Serving",
                        style:
                        TextStyle(color: Colors.grey))))
                : Container(
              height: MediaQuery.of(
                  context)
                  .size
                  .height -
                  340,
              width: MediaQuery.of(
                  context)
                  .size
                  .width,
              child: Container(
                padding:
                EdgeInsets.all(
                    20),
                height: MediaQuery.of(context)
                    .size
                    .height -
                    200,
                width: MediaQuery.of(context)
                    .size
                    .width,
                child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4),
                    itemCount: 8,
                    itemBuilder: (context, i) {
                      Opacity(
                        opacity: 0.8,
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                              ],
                            ),
                          ),
                        ),
                      );


                    }),
              ),
            );
          },
        );
      },
    );
  }

  getRainbowOverlay() {
    return FutureBuilder(
        future: getSettings(context, 'RGB Screen (TV)', 1),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          return snapshot.connectionState == ConnectionState.done ?
              int.parse(snapshot.data!['value']) == 1 ?
                  Builder(
                    builder: (context) {
                      final visible = int.parse(snapshot.data!['other'].toString().split(":")[0]);
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
        future: getSettings(context, 'Background Videos'),
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


  getTicketSQL() async {
    final dateNow = DateTime.now();

    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response.where((e) => e['status'] == "Serving").toList();
      List<Ticket> newTickets = [];

      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }


      newTickets = newTickets.where((e) => e.timeCreatedAsDate!.isAfter(toDateTime(dateNow)) && e.timeCreatedAsDate!.isBefore(toDateTime(dateNow.add(Duration(days: 1))))).toList();
      newTickets.sort((a, b) => DateTime.parse(b.timeTaken!).compareTo(DateTime.parse(a.timeTaken!)));

      return newTickets;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  Future<void> updateBlinker(Ticket ticket) async {
    ticket.update({
      'id': ticket.id!,
      'blinker': 1
    });
  }


}
