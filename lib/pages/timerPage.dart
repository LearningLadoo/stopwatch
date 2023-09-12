import 'dart:async';
import 'dart:developer';
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
  Timer? periodicTimer;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setupInitial();
    super.initState();
  }

  @override
  void dispose() {
    periodicTimer!.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if(!active) return;
    switch (state) {
      case AppLifecycleState.resumed:
      // when the app is resumed
        setupInitial();
        break;
      case AppLifecycleState.paused:
      // handles any uncertainty which leads to closure of app
      // set the shared prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("startTimeStamp",startTime.millisecondsSinceEpoch);
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
    log("$startTimeStamp");
    if (startTimeStamp != null) {
      // the app lifecycle was closed so getting the previous start time
      startTime = DateTime.fromMillisecondsSinceEpoch(startTimeStamp);
      active = true;
      // remove the prefs
      await prefs.remove("startTimeStamp");
    }
    setState(() {});
    // start the timer by default
    if (active) startTimer();
  }

  void startTimer(){
    // Cancel the previous timer if it's running
    if (periodicTimer != null && periodicTimer!.isActive) {
      periodicTimer!.cancel();
    }
    periodicTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        setState(() {
          log(currTime.toString());
          currTime = DateTime.now();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // spacing
            const Expanded(child: Center()),
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
            const SizedBox(height: 50),
            SizedBox(
              width: MediaQuery.of(context).size.width/3,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (!active) {
                    // get the initial time
                    startTime = DateTime.now();
                    currTime = DateTime.now();
                    // starting timer
                    startTimer();
                  } else {
                    // stop the timer
                    periodicTimer!.cancel();
                    startTime = currTime;
                  }
                  active = !active;
                  setState(() {});
                },
                child: Text(!active ? "Start" : "Finish"),
              ),
            ),
            // spacing
            const Expanded(child: Center()),
          ],
        ),
      ),
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
