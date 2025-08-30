import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class BatteryWidget extends StatefulWidget {
  @override
  _BatteryWidgetState createState() => _BatteryWidgetState();
}

class _BatteryWidgetState extends State<BatteryWidget> {
  static const platformBattery = MethodChannel('battery.channel');
  int? batteryLevel;

  @override
  void initState() {
    super.initState();
    fetchBatteryLevel();
  }

  Future<void> fetchBatteryLevel() async {
    try {
      final int level = await platformBattery.invokeMethod('getBatteryLevel');
      setState(() => batteryLevel = level > 0 ? level : null);
    } on PlatformException catch (_) {
      setState(() => batteryLevel = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      batteryLevel != null
          ? "Battery: $batteryLevel%"
          : "Battery info unavailable",
      style: TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}

class LauncherButtonWidget extends StatelessWidget {
  final bool isDefaultLauncher;

  const LauncherButtonWidget({Key? key, required this.isDefaultLauncher})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final intent = AndroidIntent(
          action: 'android.settings.HOME_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        intent.launch();
      },
      child: Text(
        isDefaultLauncher ? 'Remove as Default Launcher' : 'Set as Default Launcher',
      ),
    );
  }
}
