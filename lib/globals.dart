import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'models/media.dart';
import 'dart:math' as math;

final site = "127.0.0.1:8080";

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
              Text("Office of the Ombudsman", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700), textAlign: TextAlign.center)
            ],
          )),
        )
        : Container(),
      Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: showColor == null ? Colors.white60 : null,
      ),
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

getSettings(BuildContext context, [String? controlName, int? getControl]) async {
  try {
    final uri = Uri.parse('http://$site/queueing_api/api_controls.php');
    final result = await http.get(uri);
    final response = jsonDecode(result.body);

    if (controlName != null) {
      final result = response.where((e) => e['controlName'] == controlName).toList()[0];
      final vqd = int.parse(result['value'].toString());

      if (getControl != null) {
        return result;
      } else {
        return vqd;
      }
    } else {
      return response;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Cannot connect to the server. Please try again.")));
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

class RainbowOverlay extends StatefulWidget {
  const RainbowOverlay({super.key});

  @override
  State<RainbowOverlay> createState() => _RainbowOverlayState();
}

class _RainbowOverlayState extends State<RainbowOverlay>
    with SingleTickerProviderStateMixin {
  // 🎛 Adjustable
  final int visibleSeconds = 5;
  final int invisibleSeconds = 25;
  final double fadeSeconds = 1.0; // how long fade in/out takes

  late final AnimationController _controller;
  late final int totalCycleSeconds;

  @override
  void initState() {
    super.initState();
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

            double opacity = 0;
            if (cyclePos < fadeSeconds) {
              // fade in
              opacity = cyclePos / fadeSeconds;
            } else if (cyclePos < visibleSeconds - fadeSeconds) {
              // fully visible
              opacity = 0.8;
            } else if (cyclePos < visibleSeconds) {
              // fade out
              opacity = (visibleSeconds - cyclePos) / fadeSeconds;
            } else {
              // invisible part
              opacity = 0;
            }

            // scroll value loops within visibleSeconds
            final scrollValue = (cyclePos / visibleSeconds) % 1;
            final dx = -screenWidth * scrollValue;

            return AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 200), // short duration for smooth update
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