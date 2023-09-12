import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  late DateTime startTime, currTime;
  bool active = false;

  // now this will start only when it is called
  late final periodicTimer = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
      setState(() {
        currTime = DateTime.now();
      });
    },
  );

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setupInitial();
    super.initState();
  }

  @override
  void dispose() {
    periodicTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async{
    switch (state) {
      case AppLifecycleState.resumed:
        // when the app is resumed
        setupInitial();
        break;
      case AppLifecycleState.paused:
        // handles any uncertainty which leads to closure of app
        // set the shared prefs
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt("startTimeStamp",startTime.millisecondsSinceEpoch);
        break;
      default:
    }
  }

  Future setupInitial() async {
    // setting up default values
    startTime = DateTime.now();
    currTime = DateTime.now();
    // shared prefs
    final prefs = await SharedPreferences.getInstance();
    int? startTimeStamp = prefs.getInt('startTimeStamp');
    if (startTimeStamp != null) {
      // the app lifecycle was closed so getting the previous start time
      startTime = DateTime.fromMillisecondsSinceEpoch(startTimeStamp);
      active = true;
      // remove the prefs
      prefs.remove("startTimeStamp");
    }
    setState(() {});
    // start the timer by default
    if (active) periodicTimer;
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // timer
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Card(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                child: Text(printDuration(currTime.difference(startTime)),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (!active) {
              // get the initial time
              startTime = DateTime.now();
              currTime = DateTime.now();
              // starting timer
              periodicTimer;
            } else {
              // stop the timer
              periodicTimer.cancel();
              startTime = currTime;
            }
            active = !active;
            setState(() {});
          },
          child: Text(!active ? "Start" : "Stop"),
        ),
      ],
    );
  }
}

// utils
String printDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}
