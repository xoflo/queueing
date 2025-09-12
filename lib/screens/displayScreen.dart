import 'dart:async';
import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:marquee/marquee.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/globals.dart';
import 'package:queueing/node.dart';
import '../models/controls.dart';
import '../models/station.dart';
import '../models/ticket.dart';
import 'package:flutter_tts/flutter_tts.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  int ticketsLength = 0;
  Color? containerColor;

  final FlutterTts flutterTts = FlutterTts();

  ValueNotifier<List<Station>> stationStream = ValueNotifier([]);
  List<Ticket> displayTicketList = [];

  Timer? _debounceTimer;

  Timer? clearCacheTimer;

  List<Ticket> ticketsToCall = [];


  bool isPlaying = false;

  Timer? update;
  bool _isProcessing = false;


  Map<int, DateTime> lastQueuedAt = {};
  Duration requeueCooldown = const Duration(seconds: 2);

  Future<void> _speak(String code, String teller) async {
    await Future.delayed(Duration(milliseconds: 500));
    flutterTts.setVolume(1);
    await flutterTts.speak("$code, $teller");
  }

  void _enqueueTicket(Ticket ticket) {
    ticketsToCall.add(ticket);
    if (!_isProcessing) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    _isProcessing = true;

    flutterTts.setCompletionHandler(() {
      isPlaying = false;
    });

    while (ticketsToCall.isNotEmpty) {
      final Ticket ticket = ticketsToCall.removeAt(0);

      // ding
      AudioPlayer player = AudioPlayer();
      player.setVolume(0.7);
      await player.play(AssetSource('sound.mp3'));

      if (ticket.callCheck == 0) {
        isPlaying = true;

        // speak
        await _speak(
          ticket.codeAndNumber!,
          "${ticket.stationName!}${ticket.stationNumber != 0 ? ticket.stationNumber! : 0}",
        );

        // wait until TTS finishes
        while (isPlaying) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

      }

      // small gap before next ticket
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isProcessing = false;
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


  initUpdate() {
    update = Timer.periodic(Duration(seconds: 5), (value) {
      NodeSocketService().sendMessage('checkStationSessions', {});
    });

    clearCacheTimer = Timer.periodic(Duration(minutes: 5), (value) async {
      NodeSocketService().sendMessage('refresh', {});
    });
  }

  @override
  void dispose() {
    clearCacheTimer!.cancel();
    update!.cancel();
    super.dispose();
  }


  void _resetAppState() {
    // Clear in-memory lists
    displayTicketList = [];
    ticketsToCall = [];
    stationStream.value = [];

    // Cancel and restart timers
    _debounceTimer?.cancel();
    _debounceTimer = null;

    clearCacheTimer?.cancel();
    clearCacheTimer = null;

    update?.cancel();
    update = null;

    // Restart timers fresh
    initUpdate();

    // Reconnect WebSocket
    NodeSocketService().dispose();
    NodeSocketService().connect(context: context);

    // Request fresh data
    NodeSocketService().sendMessage('updateDisplay', {});

    // Trigger rebuild
    if (mounted) {
      this.setState(() {});
    }

  }


  @override
  void initState() {
    initUpdate();

    NodeSocketService().stream.listen((message) async {
      final json = jsonDecode(message);
      final type = json['type'];
      final data = json['data'];

      if (type == 'updateDisplay') {
        if (_debounceTimer != null) {
          _debounceTimer!.cancel();
        }

        _debounceTimer = Timer(Duration(milliseconds: 1000), () async {
          await updateDisplayNode(data);
        });
      }

    },

      cancelOnError: false,
    );

    super.initState();
  }

  final refreshKey = GlobalKey();
  bool showRefresh = false;


  updateDisplayNode(List<dynamic> data) async {

    final List<dynamic> stations = data[0];
    final List<dynamic> tickets = data[1];

    List<Ticket> ticketList = [];
    List<Station> stationList = [];

    for (dynamic ticket in tickets) {
      ticketList.add(Ticket.fromJson(ticket));
    }

    for (dynamic station in stations) {
      stationList.add(Station.fromJson(station));
    }


    List<Ticket> toUpdate = ticketList
        .where((e) => e.callCheck! == 0)
        .toList();

    for (Ticket ticket in toUpdate) {
      try {
        await ticket.updateOnly({'id': ticket.id, 'callCheck': 1});
      } catch (e) {
        print(e);
      }
      _enqueueTicket(ticket);
    }

    displayTicketList = ticketList;
    stationStream.value = stationList;
  }

  void _playNextTicket() async {

    while (ticketsToCall.isNotEmpty) {

      final Ticket ticket = ticketsToCall[0];
      AudioPlayer player = AudioPlayer();
      player.setVolume(0.7);
      await player.play(AssetSource('sound.mp3'));

      if (ticket.callCheck == 0) {
        await _speak(ticket.codeAndNumber!,
            "${ticket.stationName!}${ticket.stationNumber != 0 ? ticket.stationNumber! : 0}");
        try {
          await ticket.updateOnly({'id': ticket.id, 'callCheck': 1});
        } catch(e) {
          print(e);
        }
      }

      ticketsToCall.removeAt(0);
      await Future.delayed(Duration(milliseconds: 500));
    }

  }



  @override
  Widget build(BuildContext context) {
    containerColor = Theme.of(context).cardTheme.color;
    return PopScope(
      onPopInvokedWithResult: (bool, value) async => false,
      child: Scaffold(
        floatingActionButton: StatefulBuilder(
            key: refreshKey,
            builder: (context, setStateRefresh) {
          return showRefresh == true ?  Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 5,
            children: [
              FloatingActionButton(
                  child: Icon(Icons.refresh),
                  onPressed: () async {
                    await clearCache();
                    _resetAppState();
              }),
              FloatingActionButton(
                  child: Icon(Icons.lock_open),
                  onPressed: () async {
                    await settingSecurityPin();
                  })
            ],
          ): SizedBox();
        }),
        body: GestureDetector(
          onLongPress: () {
            showRefresh = !showRefresh;
            refreshKey.currentState!.setState(() {});
          },
          child: FutureBuilder(
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
      ),
    );
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


  updateDisplay() async {
    final retrieved = await getTicketSQL();

    final List<Ticket> toUpdate =
    retrieved
        .where(
            (e) => e.callCheck == 0)
        .toList();



    if (toUpdate.isNotEmpty) {

      for (int i = 0; i < toUpdate.length; i++) {
        ticketsToCall.add(toUpdate[i]);
      }

      for (int i = 0; i < ticketsToCall.length; i++) {

        AudioPlayer player = AudioPlayer();
        player
            .play(AssetSource('sound.mp3'));
        _speak(ticketsToCall[i].codeAndNumber!, "${ticketsToCall[i].stationName!}${ticketsToCall[i].stationNumber! != 0 ? ticketsToCall[i].stationNumber! : 0}");
      }
    }

    await updateStations();

    return;
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
                  links.add("http://192.168.110.100:8080/queueing_api/videos/${snapshotMedia.data![i]['link']}");
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
                              child: WebVideoPlayer(
                                  videoAssets: links, display: 1))),
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

                                        print(value.length);
                                        Station station = value[i];
                                        print(station.ticketServingId);

                                        return station.ticketServingId != null && station.inSession == 1 ?
                                        FutureBuilder(
                                          future: getTicketSaved(station.ticketServingId),
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
                                                  duration: Duration(seconds: 10),
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
                                                                    final timer = Timer(Duration(seconds: 10), () {
                                                                      show = false;
                                                                      if (mounted) {
                                                                        setStateText((){});
                                                                      }
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
    print(stations.length);
    for (int i =0; i < stations.length; i++) {
      print(stations[i].ticketServingId);
    }
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
                          final Station? station = value[i];

                          return (station!.ticketServingId != null ) && station.inSession == 1 ?
                          FutureBuilder(
                              future: getTicketSaved(station.ticketServingId),
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
                                        duration: Duration(seconds: 10),
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
                                                          final timer = Timer(Duration(seconds: 10), () {
                                                            show = false;
                                                            if (mounted) {
                                                              setStateText((){});
                                                            }
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
                        links.add("http://192.168.110.100:8080/queueing_api/bgvideos/${mediabg[i]['link']}");
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

  Future<List<Ticket>> getTicketSaved([int? ticketServingId]) async {
    try {
      List<Ticket> newTickets = [];

      newTickets = displayTicketList;
      newTickets.sort((a, b) => DateTime.parse(b.timeTaken!).compareTo(DateTime.parse(a.timeTaken!)));

      if (ticketServingId != null) {
        newTickets = newTickets.where((e) => e.id == ticketServingId).toList();
      }

      return newTickets;
    } catch(e) {
      print(e);
      return [];
    }
  }

  getTicketSQL([int? ticketServingId]) async {

    try {

      final uri = Uri.parse('http://$site/queueing_api/api_ticket.php');
      final result = await http.get(uri);
      final List<dynamic> response = jsonDecode(result.body);

      final sorted = response.where((e) => e['status'] == "Serving").toList();
      List<Ticket> newTickets = [];

      for (int i = 0; i < sorted.length; i++) {
        newTickets.add(Ticket.fromJson(sorted[i]));
      }

      if (ticketServingId != null) {
        newTickets = newTickets.where((e) => e.id == ticketServingId).toList();
      } else {
        newTickets.sort((a, b) => DateTime.parse(b.timeTaken!).compareTo(DateTime.parse(a.timeTaken!)));
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
    try {
      await ticket.updateOnly({
        'id': ticket.id!,
        'blinker': 1,
      });
    } catch(e) {
      print(e);
    }
  }


}
