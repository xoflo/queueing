import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:queueing/hiveService.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'models/media.dart';
import 'dart:math' as math;
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

String? version = "v1.0.5";
String? site = '192.168.110.100:8080';
String? printer;
String? size;

Color hexBlue = Color(0xFF216cb8);

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();



updateIP(String ip) {
  site = ip;
}

updatePrinter(String printer) {
  printer = printer;
}

updateSize(String size) {
  size = size;
}

getIP() async {
  await HiveService.saveIP(site!);
  final String? ip = await HiveService.getIP();
  updateIP(ip ?? "");
  return site;
}

saveIP(String ip) async {
  await HiveService.saveIP(ip);
  updateIP(ip);
}

getPrinter() async {
  final dynamic printer = await HiveService.getPrinter();
  updatePrinter(printer ?? "");
  return printer;
}

savePrinter(String printer) async {
  await HiveService.savePrinter(printer);
  updatePrinter(printer);
}

getSize() async {
  final String? size = await HiveService.getSize();
  updateSize(size ?? "");
  return size;
}

saveSize(String size) async {
  await HiveService.saveSize(size);
  updateSize(size);
}

stringToList(String text) {
  if (text != "") {
    String trimmed = text.substring(1, text.length - 1);
    List<String> parts = trimmed.split(',');
    List<String> result = parts.map((s) => s.trim().replaceAll('"', '')).toList();

    return result;
  } else {
    return [];
  }
}


logoBackground(BuildContext context, [int? width, int? height, int? showColor]) {
  return Stack(
    children: [MediaQuery.of(context).size.width > (width != null ? width : 1500)
        ? Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              height != null ? Container(
                  height: height.toDouble(),
                  child: Image.asset('images/logo.png')) : Image.asset('images/logo.png'),
              SizedBox(height: 20),
              Text("OFFICE OF THE OMBUDSMAN", style: TextStyle(fontFamily: 'BebasNeue' ,fontSize: 30, fontWeight: FontWeight.w700), textAlign: TextAlign.center)
            ],
          )),
        )
        : Container(),
      Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: showColor == null ? Colors.white70 : null,
      )
    ],
  );
}

graphicBackground(BuildContext context) {
  return Stack(
    children: [
      Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fill,
              image:
              Image.asset('images/bluebackground.jpg').image),
        )),

    ],
  );
}

imageBackground(BuildContext context) {
  return Container(
    height: MediaQuery.of(context).size.height,
    decoration: BoxDecoration(
      image: DecorationImage(
          fit: BoxFit.fill,
          image:
          Image.asset('images/background.jpg').image),
    ));
}

getSettings([BuildContext? context, String? controlName, int? getControl]) async {
  try {
    final uri = Uri.parse('http://$site/queueing_api/api_controls.php');
    final result = await http.get(uri);
    final response = jsonDecode(result.body);

    if (controlName != null) {
      final result = response.where((e) => e['controlName'] == controlName).toList()[0];
      final value = int.parse(result['value'].toString());

      if (getControl != null) {
        return result;
      } else {
        return value;
      }
    } else {
      return response;
    }
  } catch (e) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Cannot connect to the server. Please try again.")));
    }
    print(e);
    return [];
  }
}

getMedia(BuildContext context) async {
  try {
    final uri = Uri.parse('http://$site/queueing_api/api_media.php');
    final result = await http.get(uri);
    List<dynamic> response = jsonDecode(result.body);

    return response;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Cannot connect to the server. Please try again.")));
    print(e);
    return null;
  }
}

getMediabg(BuildContext context) async {
  try {
    final uri = Uri.parse('http://$site/queueing_api/api_mediabg.php');
    final result = await http.get(uri);
    List<dynamic> response = jsonDecode(result.body);

    return response;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Cannot connect to the server. Please try again.")));
    print(e);
    return [];
  }
}

getServiceSQL() async {
  try {
    final uri = Uri.parse('http://$site/queueing_api/api_service.php');
    final result = await http.get(uri);
    final response = jsonDecode(result.body);
    response.sort((a, b) => int.parse(a['id'].toString()).compareTo(int.parse(b['id'].toString())));

    return response;
  } catch(e){
    print(e);
    return [];
  }
}

getServiceGroupSQL() async {
  try {
    final uri = Uri.parse('http://$site/queueing_api/api_serviceGroup.php');
    final result = await http.get(uri);
    final response = jsonDecode(result.body);
    response.sort((a, b) => int.parse(a['id'].toString())
        .compareTo(int.parse(b['id'].toString())));
    return response;
  } catch (e) {
    print(e);
    return [];
  }
}

DateTime toDateTime(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}




class RainbowOverlay extends StatefulWidget {
  RainbowOverlay({super.key, this.control, this.visible, this.invisible, this.opacity, this.always});

  int? control;

  int? visible;
  int? invisible;
  double? opacity;
  bool? always;

  @override
  State<RainbowOverlay> createState() => _RainbowOverlayState();
}

class _RainbowOverlayState extends State<RainbowOverlay>
    with SingleTickerProviderStateMixin {

  // 🎛 Adjustable
  int visibleSeconds = 5;
  int invisibleSeconds = 25;
  final double fadeSeconds = 1.0;
  double opacity = 0.7;
  bool alwaysVisible = false; // set this to true for constant rainbow

  late final AnimationController _controller;
  late final int totalCycleSeconds;

  @override
  void initState() {
    super.initState();
    if (widget.visible != null) visibleSeconds = widget.visible!;
    if (widget.invisible != null) invisibleSeconds = widget.invisible!;
    if (widget.opacity != null) opacity = widget.opacity!;
    if (widget.always != null) alwaysVisible = widget.always!;

    totalCycleSeconds = visibleSeconds + invisibleSeconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalCycleSeconds),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final value = _controller.value;
            final cyclePos = value * totalCycleSeconds;
            double opacityConst = opacity;

            if (!alwaysVisible) {
              if (cyclePos < fadeSeconds) {
                opacityConst = cyclePos / fadeSeconds;
              } else if (cyclePos < visibleSeconds - fadeSeconds) {
                opacityConst = opacity;
              } else if (cyclePos < visibleSeconds) {
                opacityConst = (visibleSeconds - cyclePos) / fadeSeconds;
              } else {
                opacity = 0;
              }
            }

            // scroll value loops within visibleSeconds
            final scrollValue = (cyclePos / visibleSeconds) % 1;
            final dx = -screenWidth * scrollValue;

            return AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 200),
              child: ClipRect(
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: Row(
                      children: [
                        _rainbowStrip(screenWidth),
                        _rainbowStrip(screenWidth),
                        _rainbowStrip(screenWidth),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _rainbowStrip(double width) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.indigo,
            Colors.purple,
            Colors.red,
          ],
        ),
      ),
    );
  }
}




class WebVideoPlayer extends StatefulWidget {
  final List<String> videoAssets;
  final int display;

  const WebVideoPlayer({
    Key? key,
    required this.videoAssets, required this.display,
  }) : super(key: key);

  @override
  State<WebVideoPlayer> createState() => WebVideoPlayerState();
}

class WebVideoPlayerState extends State<WebVideoPlayer> {
  late VideoPlayerController _controller;
  int _currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAndPlay(widget.videoAssets[_currentVideoIndex]);
  }

  Future<void> _initializeAndPlay(String asset) async {


    _controller = VideoPlayerController.networkUrl(

        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
        ),
        Uri.parse(widget.videoAssets[_currentVideoIndex]))
      ..initialize().then((_) {
        setState(() {}); // refresh after init
        _controller
          ..setLooping(false) // we'll manually handle looping across videos
          ..setVolume(0)
          ..play();
      });

    _controller.addListener(_checkVideoEnd);
  }

  void _checkVideoEnd() {
    if (_controller.value.position >= _controller.value.duration &&
        !_controller.value.isPlaying) {
      _playNextVideo();
    }
  }

  play() {
    _controller.play();
  }

  Future<void> _playNextVideo() async {
    _controller.removeListener(_checkVideoEnd);
    await _controller.dispose();

    setState(() {
      _currentVideoIndex =
          (_currentVideoIndex + 1) % widget.videoAssets.length;
    });

    _initializeAndPlay(widget.videoAssets[_currentVideoIndex]);
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoEnd);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Container(
      height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: FittedBox(
            fit: widget.display == 1 ? BoxFit.fitHeight : BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        ) : const SizedBox.shrink();
  }
}

class Blink extends StatefulWidget {
  final Widget _target;
  const Blink(this._target, {Key? key}) : super(key: key);
  @override
  _BlinkState createState() => _BlinkState();
}

class _BlinkState extends State<Blink> {
  bool _show = true;
  Timer? _timer;

  @override
  void initState() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() => _show = !_show);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _show ?
    Visibility(
        visible: true,
        child: widget._target) :
  Visibility(
      visible: false,
      child: widget._target);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}



Future<void> clearCache() async {

  await DefaultCacheManager().emptyCache();

  try {

    await DefaultCacheManager().emptyCache();

    final tempDir = await getTemporaryDirectory();

    if (tempDir.existsSync()) {
      for (var file in tempDir.listSync()) {
        try {
          file.deleteSync(recursive: true);
        } catch (_) {}
      }
    }

    return;
  } catch (e) {
    return;
  }
}





/*

                                    IconButton(onPressed: () {
                                      showDialog(context: context, builder: (_) => StatefulBuilder(
                                        key: dialogKey,
                                        builder: (BuildContext context, setStateDialog) {
                                          return AlertDialog(
                                            title: Text("Select Services (3 Max)"),
                                            content: Container(
                                              height: 400,
                                              width: 400,
                                              child: FutureBuilder(
                                                future: thisUser(),
                                                builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
                                                  return StatefulBuilder(
                                                    builder: (BuildContext context, void Function(void Function()) setStateList) {
                                                      return snapshot.connectionState == ConnectionState.done ? ListView.builder(
                                                          itemCount: snapshot.data!.serviceType!.length,
                                                          itemBuilder: (context, i) {
                                                            return CheckboxListTile(
                                                                title: Text(snapshot.data!.serviceType![i]),
                                                                value: servicesSet.contains(snapshot.data!.serviceType![i].toString()), onChanged: (value) {
                                                              if (value == true) {
                                                                if (servicesSet.length == 3) {
                                                                  servicesSet.removeAt(0);
                                                                }
                                                                servicesSet.add(snapshot.data!.serviceType![i].toString());
                                                                setStateList((){});
                                                              } else {
                                                                servicesSet.remove(snapshot.data!.serviceType![i].toString());
                                                                setStateList((){});
                                                              }

                                                              print(servicesSet);
                                                            });
                                                          }) : Center(
                                                        child: Container(
                                                          height: 50,
                                                          width: 50,
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                            actions: [
                                              TextButton(onPressed: () {

                                                try {
                                                  snapshot.data!.update({
                                                    "servicesSet": servicesSet.toString()
                                                  });

                                                  Navigator.pop(context);
                                                  setState((){});

                                                } catch(e) {
                                                  print(e);
                                                }

                                              }, child: Text("Confirm"))
                                            ],
                                          );
                                        },
                                      )
                                      );
                                    }, icon: Icon(Icons.settings))
                                     */


/*

                                              if (servingStream.value != null) {
                                                showDialog(
                                                    context: context,
                                                    builder:
                                                        (_) => AlertDialog(
                                                              title: Text(
                                                                  "Confirm Done?"),
                                                              content: Container(
                                                                  child: Text(
                                                                      "'Done' to complete and 'Call Next' to serve next ticket."),
                                                                  height: 40),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed: () async {
                                                                      try {
                                                                        await servingStream.value!.update({
                                                                          "status": "Done",
                                                                          "timeDone": timestamp,
                                                                          "log": "${servingStream.value!.log}, $timestamp: Ticket Session Finished"});

                                                                        await widget.station.update({'ticketServing': ""});




                                                                        Navigator.pop(
                                                                            context);
                                                                        resetRinger();



                                                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                            content:
                                                                            Text("Ticket complete.")));
                                                                      } catch(e) {
                                                                        print(e);
                                                                        print("Done in Dialog");
                                                                      }
                                                                    },
                                                                    child: Text(
                                                                        "Done")),
                                                                TextButton(
                                                                    onPressed:
                                                                        () async {

                                                                      try {

                                                                        final timestamp =
                                                                        DateTime.now().toString();

                                                                        await servingStream.value!.update({
                                                                          "status": "Done",
                                                                          "timeDone": timestamp,
                                                                          "log": "${servingStream.value!.log}, $timestamp: Ticket Session Finished"
                                                                        });

                                                                        if (ticketStream.value.isNotEmpty) {
                                                                          if (ticketStream.value[0].serviceType! == callBy || callBy == 'Time Order') {
                                                                            await ticketStream.value[0].update({
                                                                              "userAssigned": widget.user.username,
                                                                              "status": "Serving",
                                                                              "stationName": widget.station.stationName,
                                                                              "stationNumber": widget.station.stationNumber,
                                                                              "log": "${ticketStream.value[0].log}, $timestamp: serving on ${widget.station.stationName}${widget.station.stationNumber} by ${widget.user.username}",
                                                                              "timeTaken": timestamp,
                                                                            });


                                                                            await widget.station.update({'ticketServing': "${ticketStream.value[0].codeAndNumber}"});
                                                                            await updateServingTicketStream();
                                                                            await updateTicketStream(1);

                                                                            Navigator.pop(context);
                                                                          }
                                                                        } else {
                                                                          await widget
                                                                              .station
                                                                              .update({
                                                                            'ticketServing':
                                                                            ""
                                                                          });

                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(SnackBar(content: Text("No pending tickets to serve at the moment.")));
                                                                        }
                                                                      } catch(e) {
                                                                        print(e);
                                                                        print('Call Next in Dialog');
                                                                      }

                                                                    },
                                                                    child: Text(
                                                                        "Call Next"))
                                                              ],
                                                            ));
                                              } else {}
                                               */