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
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/station.dart';
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

  ValueNotifier<List<Station>> stationStream = ValueNotifier([]);


  late WebSocketChannel channel;
  Timer? reconnectTimer;
  bool isConnected = false;


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
  void initState() {

    listenNode();
    super.initState();
  }

  @override
  void dispose() {
    channel?.sink.close();
    reconnectTimer?.cancel();
    super.dispose();
  }

  void tryReconnect() {
    if (reconnectTimer?.isActive ?? false) return;
    reconnectTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (!isConnected) {
        print("🔁 Reconnecting...");
        listenNode();
      } else {
        print("✅ Reconnected");
        reconnectTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reconnected to server.")));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    containerColor = Theme.of(context).cardTheme.color;
    return PopScope(
      onPopInvokedWithResult: (bool, value) async => false,
      child: Scaffold(
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
                                   // timerInit();

                                    return vqd.data == 1
                                        ? videoDisplayWidget()
                                        : noVideoDisplayWidget();
                                  },
                                ),
                              ],
                            )),

                            vqd.data != 1
                                ? Container(
                              height: 200,
                              decoration: BoxDecoration(
                            color: hexBlue.withAlpha(150)),
                            child: Padding(
                                padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                                child: slidingTextWidget(),
                            )
                            ) : SizedBox(),
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


  listenNode() {
    final url = 'ws://${site.toString().split(":")[0]}:3000';
    if (kIsWeb) {
      channel = WebSocketChannel.connect(Uri.parse(url));
    } else {
      channel = IOWebSocketChannel.connect(url);
    }

    channel.stream.listen((message) async {
      isConnected = true;
      if (message.toString().trim() == 'sink') {
        print('Received sink. Updating...');
        await updateDisplay();
      } else {
        print('Ignored message: $message');
      }
    },
      onDone: () {
        isConnected = false;
        print("❌ Disconnected");
        tryReconnect();
      },
      onError: (err) {
        isConnected = false;
        print("⚠️ Error: $err");
        tryReconnect();
      },
      cancelOnError: true,
    );

    channel.sink.add('sink');

  }

  updateDisplay() async {
    final List<Ticket> retrieved = await getTicketSQL();
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

              await updateStations();
            }

            ticketsLength = retrieved.length;
            await updateStations();

          } else {

            Ticket? ticket;

            final List<Ticket> toUpdate = retrieved.where((e) => e.callCheck == 0).toList();
            if (toUpdate.isNotEmpty) {
              for (int i = 0; i < toUpdate.length; i++) {
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

              await updateStations();

            }
          }
  }

  timerInit() {
    return timer = Timer.periodic(
        Duration(seconds: 3, milliseconds: 0),
            (value) async {
          final List<Ticket> retrieved = await getTicketSQL();
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

              await updateStations();
            }

            ticketsLength = retrieved.length;
            await updateStations();

          } else {

            Ticket? ticket;

            final List<Ticket> toUpdate = retrieved.where((e) => e.callCheck == 0).toList();
            if (toUpdate.isNotEmpty) {
              for (int i = 0; i < toUpdate.length; i++) {
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

              await updateStations();

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
            height: MediaQuery.of(context).size.height,
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
      padding: EdgeInsets.fromLTRB(30.0, 5, 20, 0),
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

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
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
                    SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                          height: MediaQuery.of(
                              context)
                              .size
                              .height -
                              320,
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
                    ),
                    SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                          height: 130,
                          width: MediaQuery.of(
                    context)
                        .size
                        .width -
                    600,
                          decoration: BoxDecoration(
                              color: hexBlue.withAlpha(150)),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                            child: slidingTextWidget(),
                          )
                      ),
                    )
                  ],
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
                    320,
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
                    320,
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
          StatefulBuilder(
            builder: (context, setState) {
              return FutureBuilder(
                future: updateStations(),
                  builder: (context, AsyncSnapshot<List<Station>> stationSnap) {
                    final size = MediaQuery.of(context).size;
                    final itemWidth = (size.width / 2);
                    final itemHeight = (size.height / 5) + 190;
                    final aspectRatio = itemWidth / itemHeight;

                    return Container(
                      width: 500,
                      height: MediaQuery.of(context).size.height - 60,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: [
                              logoBackground(
                                  context,
                                  250,
                                  300),

                              ValueListenableBuilder<List<Station>>(
                                valueListenable: stationStream,
                                builder: (BuildContext context, List<Station> value, Widget? child) {
                                  return GridView.builder(
                                      gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
                                          childAspectRatio: aspectRatio,
                                          crossAxisCount: 2),
                                      itemCount: value.length,
                                      itemBuilder: (context, i) {
                                        Station station = value[i];

                                        return station.ticketServing != "" || station.ticketServing != null ?
                                        FutureBuilder(
                                          future: getTicketSQL(station.ticketServing),
                                          builder: (BuildContext context, AsyncSnapshot<List<Ticket>> snapshot) {
                                            return snapshot.connectionState == ConnectionState.done ? snapshot.data!.isNotEmpty ?
                                            Builder(builder: (context) {

                                              Ticket ticket = snapshot.data![0];

                                              bool show = true;

                                              return ticket.blinker == 0 ?
                                              TweenAnimationBuilder<Color?>(
                                                  tween: ColorTween(
                                                      begin: Colors.red,
                                                      end: Theme.of(context).cardColor.withAlpha(200)
                                                  ),
                                                  duration: Duration(seconds: 180),
                                                  builder: (BuildContext context, color, Widget? child) {
                                                    updateBlinker(ticket);
                                                    return Padding(
                                                      padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
                                                      child: Opacity(
                                                        opacity: 0.8,
                                                        child: Card(
                                                          color: color,
                                                          clipBehavior: Clip.antiAlias,
                                                          child: Column(
                                                            children: [
                                                              Expanded(
                                                                flex: 45,
                                                                child: Container(
                                                                    padding: EdgeInsets.only(top: 10),
                                                                    color: hexBlue.withAlpha(200),
                                                                    child: Center(child: AutoSizeText("${station.stationName}${station.stationNumber != 0 ? " ${station.stationNumber}" : ""}" ,style: TextStyle(height: 1 ,color: Colors.white ,fontFamily: 'BebasNeue', fontSize: 85)))
                                                                ),
                                                              ),
                                                              Expanded(
                                                                flex: 55,
                                                                child: Center(child: StatefulBuilder(builder: (BuildContext context, setStateText) {

                                                                  final noBlink = AutoSizeText(station.ticketServing!, style: TextStyle(height: 1.25 ,fontWeight: FontWeight.w700, fontSize: 85));
                                                                  final blink = Blink(AutoSizeText(station.ticketServing!, style: TextStyle(height: 1.25 ,fontWeight: FontWeight.w700, fontSize: 85)));

                                                                  if (show == true) {
                                                                    Timer.periodic(Duration(seconds: 10), (callback) {
                                                                      show = false;
                                                                      setStateText((){});
                                                                    });
                                                                  }

                                                                  return show == true ? blink : noBlink;
                                                                })),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }) :
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
                                                child: Opacity(
                                                  opacity: 0.8,
                                                  child: Card(
                                                    color: Theme.of(context).cardColor.withAlpha(200),
                                                    clipBehavior: Clip.antiAlias,
                                                    child: Column(
                                                      children: [
                                                        Expanded(
                                                          flex: 45,
                                                          child: Container(
                                                              padding: EdgeInsets.only(top: 10),
                                                              color: hexBlue.withAlpha(200),
                                                              child: Center(child: AutoSizeText("${station.stationName}${station.stationNumber != 0 ? " ${station.stationNumber}" : ""}" ,style: TextStyle(height: 1 ,color: Colors.white ,fontFamily: 'BebasNeue', fontSize: 85)))
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 55,
                                                          child: Center(child: AutoSizeText(ticket.codeAndNumber!, style: TextStyle(height: 1.25 ,fontWeight: FontWeight.w700, fontSize: 85))),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }) :
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
                                              child: Opacity(
                                                opacity: 0.8,
                                                child: Card(
                                                  color: Theme.of(context).cardColor.withAlpha(200),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        flex: 45,
                                                        child: Container(
                                                            padding: EdgeInsets.only(top: 10),
                                                            color: hexBlue.withAlpha(200),
                                                            child: Center(child: AutoSizeText("${station.stationName}${station.stationNumber != 0 ? " ${station.stationNumber}" : ""}" ,style: TextStyle(height: 1 ,color: Colors.white ,fontFamily: 'BebasNeue', fontSize: 85)))
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 55,
                                                        child: Center(child: AutoSizeText("", style: TextStyle(height: 1.25 ,fontWeight: FontWeight.w700, fontSize: 85))),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ) :
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
                                              child: Opacity(
                                                opacity: 0.8,
                                                child: Card(
                                                  color: Theme.of(context).cardColor.withAlpha(200),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        flex: 45,
                                                        child: Container(
                                                            padding: EdgeInsets.only(top: 10),
                                                            color: hexBlue.withAlpha(200),
                                                            child: Center(child: AutoSizeText("${station.stationName}${station.stationNumber != 0 ? " ${station.stationNumber}" : ""}" ,style: TextStyle(height: 1 ,color: Colors.white ,fontFamily: 'BebasNeue', fontSize: 85)))
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 55,
                                                        child: Center(child: AutoSizeText("", style: TextStyle(height: 1.25 ,fontWeight: FontWeight.w700, fontSize: 85))),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ) :
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(5, 2, 5, 0),
                                          child: Opacity(
                                            opacity: 0.8,
                                            child: Card(
                                              color: Theme.of(context).cardColor.withAlpha(200),
                                              clipBehavior: Clip.antiAlias,
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                    flex: 45,
                                                    child: Container(
                                                        padding: EdgeInsets.only(top: 10),
                                                        color: hexBlue.withAlpha(200),
                                                        child: Center(child: AutoSizeText("${station.stationName}${station.stationNumber != 0 ? " ${station.stationNumber}" : ""}" ,style: TextStyle(height: 1 ,color: Colors.white ,fontFamily: 'BebasNeue', fontSize: 85)))
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 55,
                                                    child: Center(child: AutoSizeText("", style: TextStyle(height: 1.25 ,fontWeight: FontWeight.w700, fontSize: 85))),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      });
                                },
                              ),

                            ],
                          )
                      ),
                    );
                  }
              );
            },
          )
        ],
      ),
    );
  }

  updateStations() async {
    List<Station> stations = await getStationSQL();
    stationStream.value = stations;
    return stations;
  }



  noVideoDisplayWidget() {
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return FutureBuilder(
          future: updateStations(),
            builder: (context, AsyncSnapshot<List<Station>> stationsSnap) {

              var size = MediaQuery.of(context).size;
              var itemWidth = (size.width / 4);
              var itemHeight = ((size.height - 100) / 2);
              var aspectRatio = itemWidth / itemHeight;

              return Container(
                height: MediaQuery.of(context)
                    .size
                    .height -
                    200,
                width: MediaQuery.of(context)
                    .size
                    .width,
                padding:
                EdgeInsets.all(
                    20),
                child: ValueListenableBuilder<List<Station>>(
                  valueListenable: stationStream,
                  builder: (BuildContext context, List<Station> value, Widget? child) {
                    return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: aspectRatio,
                            crossAxisCount: 5),
                        itemCount: value.length,
                        itemBuilder: (context, i) {
                          final Station station = value[i];

                          return station.ticketServing != ""  || station.ticketServing != null ?
                          FutureBuilder(
                              future: getTicketSQL(station.ticketServing),
                              builder: (context, AsyncSnapshot<List<Ticket>> snapshot) {
                                return snapshot.connectionState == ConnectionState.done ?
                                snapshot.data!.isNotEmpty ?
                                Builder(
                                    builder: (context) {
                                      Ticket ticket = snapshot.data![0];
                                      bool show = true;

                                      return ticket.blinker == 0 ?
                                      TweenAnimationBuilder<Color?>(
                                        tween: ColorTween(
                                            begin: Colors.red,
                                            end: Theme.of(context).cardColor.withAlpha(200)
                                        ),
                                        duration: Duration(seconds: 180),
                                        builder: (BuildContext context, color, Widget? child) {
                                          updateBlinker(ticket);
                                          return Opacity(
                                            opacity: 0.8,
                                            child: Card(
                                              color: color,
                                              clipBehavior: Clip.antiAlias,
                                              elevation: 2,
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 4,
                                                    child: Container(
                                                        decoration: BoxDecoration(
                                                            color: hexBlue.withAlpha(250)
                                                        ),
                                                        child: Center(child: Padding(
                                                          padding: const EdgeInsets.all(3.0),
                                                          child: AutoSizeText("${station.nameAndNumber}".toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 90, fontWeight: FontWeight.w700, fontFamily: 'BebasNeue'), maxFontSize: double.infinity),
                                                        ))),
                                                  ),
                                                  Expanded(
                                                    flex: 6,
                                                    child: Center(child: Padding(
                                                      padding: const EdgeInsets.all(10.0),
                                                      child: StatefulBuilder(builder: (BuildContext context, setStateText) {

                                                        final noBlink = AutoSizeText(station.ticketServing!, style: TextStyle(height: 1.25 ,fontWeight: FontWeight.w700, fontSize: 85));
                                                        final blink = Blink(AutoSizeText(station.ticketServing!, style: TextStyle(height: 1.25 ,fontWeight: FontWeight.w700, fontSize: 85)));

                                                        if (show == true) {
                                                          Timer.periodic(Duration(seconds: 10), (callback) {
                                                            show = false;
                                                            setStateText((){});
                                                          });
                                                        }

                                                        return show == true ? blink : noBlink;
                                                      }),
                                                    )),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ) :
                                      Opacity(
                                        opacity: 0.8,
                                        child: Card(
                                          color: Theme.of(context).cardColor.withAlpha(200),
                                          clipBehavior: Clip.antiAlias,
                                          elevation: 2,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 4,
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color: hexBlue.withAlpha(250)
                                                    ),
                                                    child: Center(child: Padding(
                                                      padding: const EdgeInsets.all(3.0),
                                                      child: AutoSizeText("${station.nameAndNumber}".toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 90, fontWeight: FontWeight.w700, fontFamily: 'BebasNeue'), maxFontSize: double.infinity),
                                                    ))),
                                              ),
                                              Expanded(
                                                flex: 6,
                                                child: Center(child: Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child: AutoSizeText(station.ticketServing!, style: TextStyle(fontSize: 70, fontWeight: FontWeight.w700), maxFontSize: double.infinity),
                                                )),
                                              )
                                            ],
                                          ),
                                        ),
                                      ); }) :
                                Opacity(
                                  opacity: 0.8,
                                  child: Card(
                                    color: Theme.of(context).cardColor.withAlpha(200),
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 2,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  color: hexBlue.withAlpha(250)
                                              ),
                                              child: Center(child: Padding(
                                                padding: const EdgeInsets.all(3.0),
                                                child: AutoSizeText("${station.nameAndNumber}", style: TextStyle(color: Colors.white, fontSize: 90, fontWeight: FontWeight.w700, fontFamily: 'BebasNeue'), maxFontSize: double.infinity),
                                              ))),
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: Center(child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: AutoSizeText("", style: TextStyle(fontSize: 70, fontWeight: FontWeight.w700), maxFontSize: double.infinity),
                                          )),
                                        )
                                      ],
                                    ),
                                  ),
                                ) :
                                Opacity(
                                  opacity: 0.8,
                                  child: Card(
                                    color: Theme.of(context).cardColor.withAlpha(200),
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 2,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  color: hexBlue.withAlpha(250)
                                              ),
                                              child: Center(child: Padding(
                                                padding: const EdgeInsets.all(3.0),
                                                child: AutoSizeText("${station.nameAndNumber}".toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 90, fontWeight: FontWeight.w700, fontFamily: 'BebasNeue'), maxFontSize: double.infinity),
                                              ))),
                                        ),
                                        Expanded(
                                          flex: 6,
                                          child: Center(child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: AutoSizeText("", style: TextStyle(fontSize: 70, fontWeight: FontWeight.w700), maxFontSize: double.infinity),
                                          )),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }):
                          Opacity(
                            opacity: 0.8,
                            child: Card(
                              color: Theme.of(context).cardColor.withAlpha(200),
                              clipBehavior: Clip.antiAlias,
                              elevation: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: hexBlue.withAlpha(250)
                                        ),
                                        child: Center(child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: AutoSizeText("${station.nameAndNumber}".toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 90, fontWeight: FontWeight.w700, fontFamily: 'BebasNeue'), maxFontSize: double.infinity),
                                        ))),
                                  ),
                                  Expanded(
                                    flex: 6,
                                    child: Center(child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: AutoSizeText("", style: TextStyle(fontSize: 70, fontWeight: FontWeight.w700), maxFontSize: double.infinity),
                                    )),
                                  )
                                ],
                              ),
                            ),
                          );
                        });
                  },
                ),
              );
            }
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

  Future<List<Station>> getStationSQL() async {
    try {
      final uri = Uri.parse('http://$site/queueing_api/api_station.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);

      List<Station> stations = [];

      for (int i = 0; i < response.length; i++) {
        stations.add(Station.fromJson(response[i]));
      }

      stations.sort((a, b) => a.displayIndex!.compareTo(b.displayIndex!));
      return stations;
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
      print(e);
      return [];
    }
  }

  getTicketSQL([String? codeAndNumber]) async {
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

      if (codeAndNumber != null) {
        newTickets = newTickets.where((e) => e.codeAndNumber! == codeAndNumber).toList();
      }

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
