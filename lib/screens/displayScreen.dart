import 'dart:async';
import 'dart:convert';
import 'package:flutter/rendering.dart';
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
  int updateSecond = 1;
  int updateFirst = 1;


  final FlutterTts flutterTts = FlutterTts();

  Future<void> _speak(String code, String teller) async {
    await Future.delayed(Duration(seconds: 2, milliseconds: 250));
    await flutterTts.speak("$code, $teller");
  }

  constraint(BuildContext context, Widget widget) {
    return MediaQuery.of(context).size.height > 600 && MediaQuery.of(context).size.width > 700
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
                    constraint(context, graphicBackground(context)),
                    constraint(context, getBackgroundVideoOverlay()),
                    vqd.data == 1 ? Container(
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
                          slidingTextSpacer(vqd.data),
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
                updateSecond = 0;
              } else {
                updateFirst = 0;
              }
            }

            ticketsLength = retrieved.length;
            if (vqd == 1) {
              updateSecond = 0;
            } else {
              updateFirst = 0;
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
                updateSecond = 0;
              } else {
                updateFirst = 0;
              }
            }
          }
        });
  }

  slidingTextSpacer(int vqd) {
    return SizedBox(height: vqd == 0 ? 120 - (MediaQuery.of(context).size.height < 850 ? 120 : 0) : 100 - (MediaQuery.of(context).size.height < 850 ? 100 : 0));
  }

  slidingTextWidget() {
    return Builder(builder: (context) {
      return MediaQuery.of(context).size.width > 1500
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
                  links.add(snapshotMedia
                      .data![i]
                  [
                  'link']);
                }

                Timer?
                newTimer;
                int videoCounter =
                0;
                VideoPlayerController?
                controller;
                int update =
                0;

                return StatefulBuilder(
                  builder:
                      (context,
                      setStatePlayer) {
                    newTimer = Timer.periodic(
                        Duration(
                            seconds: 2),
                            (_) async {
                          if (update ==
                              0) {
                            final vid =
                            Uri.parse('http://$site/queueing_api/videos/${links[videoCounter]}');
                            controller = await VideoPlayerController.networkUrl(
                                vid)
                              ..initialize().then((_) {
                                controller!.setVolume(0);
                                controller!.play();
                              });
                            newTimer!
                                .cancel();
                            update =
                            1;
                            setStatePlayer(
                                    () {});
                          } else {
                            final position = controller!
                                .value
                                .position;
                            final duration = controller!
                                .value
                                .duration;
                            if (position.toString() == duration.toString() &&
                                position.toString() != "0:00:00.000000") {

                              if (videoCounter <
                                  links.length - 1) {

                                videoCounter = videoCounter + 1;
                                update = 0;
                              } else {

                                videoCounter = 0;
                                update = 0;
                              }
                            }
                          }
                        });

                    return SizedBox(
                        width: MediaQuery.of(context).size.width -
                            600,
                        height:
                        MediaQuery.of(context).size.height - 300,
                        child: controller == null
                            ? Center(
                          child: Container(height: 50, width: 50, child: CircularProgressIndicator()),
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            color: Colors.black,
                            height: MediaQuery.of(context).size.height - 300,
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: VideoPlayer(
                                  controller!),
                            ),
                          ),
                        ));
                  },
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
                    Timer? secondTimer;
                    return StatefulBuilder(
                      builder: (context,
                          setStateSecond) {
                        Future<List<Ticket>>
                        tickets =
                        getTicketSQL();
                        secondTimer =
                            Timer.periodic(
                                Duration(
                                    seconds:
                                    1),
                                    (value) async {
                                  if (updateSecond ==
                                      0) {
                                    secondTimer!
                                        .cancel();
                                    setStateSecond(
                                            () {});
                                    updateSecond =
                                    1;
                                  }
                                });

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
                                                        end: Colors.transparent
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
                                                                  Text("${ticket.stationName!.toUpperCase()} ${ticket.stationNumber!} ", style: TextStyle(fontSize: 40)),
                                                                  Spacer(),
                                                                  Text(ticket.codeAndNumber!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 40)),
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
                                                    Text("${ticket.stationName!.toUpperCase()} ${ticket.stationNumber!} ", style: TextStyle(fontSize: 50)),
                                                    Spacer(),
                                                    Text(ticket.codeAndNumber!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 50)),
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
                                : Center(
                              child:
                              Container(
                                height:
                                50,
                                width:
                                50,
                                child:
                                CircularProgressIndicator(),
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
    return Builder(builder: (context) {
      Timer? firstTimer;
      return StatefulBuilder(
        builder:
            (context, setStateFirst) {
          Future<List<Ticket>> tickets =
          getTicketSQL();
          firstTimer = Timer.periodic(
              Duration(seconds: 2),
                  (value) async {
                if (updateFirst == 0) {
                  firstTimer!.cancel();
                  updateFirst = 1;
                  setStateFirst(() {});
                }
              });

          return FutureBuilder(
            future: tickets,
            builder: (BuildContext
            context,
                AsyncSnapshot<
                    List<Ticket>>
                snapshot) {
              return snapshot
                  .connectionState ==
                  ConnectionState
                      .done
                  ? snapshot.data!
                  .length !=
                  0
                  ? Row(
                children: [
                  Container(
                    padding:
                    EdgeInsets.all(
                        20),
                    height: MediaQuery.of(context)
                        .size
                        .height -
                        340,
                    width: MediaQuery.of(context)
                        .size
                        .width *
                        3 /
                        4,
                    child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                        itemCount: snapshot.data!.length > 10 ? 10 : snapshot.data!.length,
                        itemBuilder: (context, i) {
                          final ticket = snapshot.data![i];
                          return ticket.blinker == 0 ?
                          Builder(
                              builder: (context) {
                                updateBlinker(ticket);

                                return Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: TweenAnimationBuilder<Color?>(
                                    tween: ColorTween(
                                        begin: Colors.red,
                                        end: Theme.of(context).cardColor
                                    ),
                                    duration: Duration(seconds: 5),
                                    builder: (BuildContext context, color, Widget? child) {
                                      return Opacity(
                                        opacity: 0.75,
                                        child: Card(
                                          elevation: 2,
                                          color: color,
                                          clipBehavior: Clip.antiAlias,
                                          child: Padding(
                                            padding: const EdgeInsets.all(30.0),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text("${ticket.stationName!}${ticket.stationNumber! == 0 || ticket.stationNumber! == null ? "" : " ${ticket.stationNumber!}"}", style: TextStyle(fontSize: 30)),
                                                Text(ticket.codeAndNumber!, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
                                                Text(ticket.serviceType!, style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }
                          ) : Opacity(
                            opacity: 0.75,
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("${ticket.stationName!}${ticket.stationNumber! == 0 || ticket.stationNumber! == null ? "" : " ${ticket.stationNumber!}"}", style: TextStyle(fontSize: 30)),
                                    Text(ticket.codeAndNumber!, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700)),
                                    Text(ticket.serviceType!, style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          );


                        }),
                  ),

                  StatefulBuilder(
                    builder: (BuildContext
                    context,
                        void Function(void Function())
                        setStateCard) {
                      return Container(
                        height:
                        400,
                        width:
                        MediaQuery.of(context).size.width * 1 / 4 - 100,
                        child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: TweenAnimationBuilder<Color?>(
                              tween: ColorTween(
                                begin: snapshot.data!.first.blinker == 0 ? Colors.red : Colors.white70,
                                end: Colors.white70,
                              ),
                              duration: Duration(seconds: 5),
                              builder: (context, color, child) {
                                updateBlinker(snapshot.data!.first);

                                return Opacity(
                                  opacity: 0.75,
                                  child: Card(
                                    elevation: 2,
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
                                            Text("${snapshot.data!.first.stationName} ${snapshot.data!.first.stationNumber}", style: TextStyle(fontSize: 30)),
                                            Text("${snapshot.data!.first.codeAndNumber}", style: TextStyle(fontSize: 60, fontWeight: FontWeight.w700)),
                                            Text("${snapshot.data!.first.serviceType}", style: TextStyle(fontSize: 30), textAlign: TextAlign.center),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )),
                      );
                    },
                  )
                ],
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
                    .width *
                    3 /
                    4,
                child: Center(
                    child: Container(
                        height:
                        50,
                        width: 50,
                        child:
                        CircularProgressIndicator())),
              );
            },
          );
        },
      );
    });
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
        future: getSettings(context, 'BG Video (TV)'),
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
                      links.add(mediabg[i]['link']);
                    }

                    return BackgroundVideoPlayer(videoAssets: links);
                  }
                ) :
                    SizedBox();
              },
          ) :
          SizedBox() : SizedBox();
        });
  }


  Future<List<Ticket>> getTicketSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');

      final result = await http.get(uri);

      final List<dynamic> response = jsonDecode(result.body);
      final sorted = response.where((e) => e['status'] == "Serving").toList();
      List<Ticket> newTickets = [];

      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      newTickets.sort((a, b) =>
          DateTime.parse(b.timeTaken!).compareTo(DateTime.parse(a.timeTaken!)));

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
