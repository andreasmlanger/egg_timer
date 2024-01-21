import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock/wakelock.dart';
import 'package:egg_timer/painter/egg_overlay.dart';


final primaryColor = Colors.yellow;

enum EggType { soft, hard }
enum Size { S, M, L }


class Home extends StatefulWidget {

  const Home({super.key});
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  late int passedTime;
  late Timer? timer;
  final AudioPlayer audioPlayer = AudioPlayer();

  bool counting = false;
  bool isPlaying = false;
  bool isVibrating = false;

  late EggType eggType;
  late Size size;

  // Cook Period in seconds
  Map<EggType, Map<Size, int>> cookPeriod = {
    EggType.soft: {
      Size.S: 270,
      Size.M: 330,
      Size.L: 390,
    },
    EggType.hard: {
      Size.S: 390,
      Size.M: 450,
      Size.L: 510,
    },
  };

  late Map<EggType, bool> eggIsReady;  // keep track which alarm has started

  late Color buttonColorS;
  late Color buttonColorM;
  late Color buttonColorL;

  @override
  void initState() {
    super.initState();
    _updateEggSize('M');  // M is default
    _resetEggTimer();
    VolumeController().showSystemUI = false;
  }

  void _updateEggSize(String pressedButton) {
    const selectedColor = Colors.white;
    final nonSelectedColor = selectedColor.withOpacity(0.3);
    setState(() {
      if (pressedButton == 'S') {
        size = Size.S;
        buttonColorS = selectedColor;
        buttonColorM = nonSelectedColor;
        buttonColorL = nonSelectedColor;
      } else if (pressedButton == 'M') {
        size = Size.M;
        buttonColorS = nonSelectedColor;
        buttonColorM = selectedColor;
        buttonColorL = nonSelectedColor;
      } else if (pressedButton == 'L') {
        size = Size.L;
        buttonColorS = nonSelectedColor;
        buttonColorM = nonSelectedColor;
        buttonColorL = selectedColor;
      }
    });
  }

  _resetEggTimer() {
    setState(() {
      passedTime = 0;
      eggIsReady = { EggType.hard: false, EggType.soft: false };
    });
  }

  _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  _renderClock() {
    final duration = Duration(seconds: passedTime);
    final minutes = _twoDigits(duration.inMinutes.remainder(60));
    final seconds = _twoDigits(duration.inSeconds.remainder(60));
    return Text(
      '$minutes:$seconds', // Use \t for tab characters
      style: const TextStyle(
        color: Colors.black,
        fontSize: 40.0,
        fontFamily: 'Square',
      ),
    );
  }

  _renderPlayIcon() {
    var icon = Icons.water;
    if (isPlaying) {
      icon = Icons.volume_off;
    } else if (counting) {
      icon = Icons.stop;
    }
    return Icon(
      icon,
      size: 40.0,
      color: Colors.white,
    );
  }

  _cancelTimer() {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
    setState(() {
      counting = false;
    });
  }

  void _startAudio() async {
    VolumeController().setVolume(0.9);
    audioPlayer.play(AssetSource('alarm.mp3'));
  }

  void _stopAudio() async {
    VolumeController().setVolume(0.0);
    audioPlayer.stop();
  }

  void _startVibrations() async {
    while (isVibrating) {
      Vibrate.vibrate();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _playAlarm() {
    setState(() {
      isPlaying = true;
      isVibrating = true;
    });
    _startAudio();
    _startVibrations();
  }

  void _muteAlarm() {
    setState(() {
      isPlaying = false;
      isVibrating = false;
    });
    _stopAudio();
  }

  void _tick() {
    setState(() {
      passedTime += 1;
    });
  }

  void _pressButton() {
    if (isPlaying) {
      _muteAlarm();
    } else if (counting) {
      _cancelTimer();
      _resetEggTimer();
      Wakelock.disable();
    } else {
      _resetEggTimer();
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _tick();
      });
      setState(() {
        counting = true;
      });
      Wakelock.enable();
    }
  }

  Widget _renderEggImage(String type, Color bgColor) {
    eggType = type == 'soft' ? EggType.soft : EggType.hard;
    double percent;

    final totalTime = cookPeriod[eggType]![size]!;

    if (passedTime < totalTime) {
      percent = 1 - passedTime / totalTime;
    } else {
      percent = 0.0;
      if (!isPlaying & !eggIsReady[eggType]!) {
        _playAlarm();
      }
      eggIsReady[eggType] = true;
    }

    return CustomPaint(
      foregroundPainter: EggOverlay(bgColor: bgColor, percent: percent),
      child: CircleAvatar(
        radius: MediaQuery.of(context).size.height * 0.17,
        backgroundColor: Colors.white,
        child: Image.asset('assets/$type.png'),
      ),
    );
  }

  Widget buildEggButton(String label, double iconSize, Color buttonColor) {
    return TextButton.icon(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
        ),
      ),
      icon: Icon(Icons.egg, size: iconSize),
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(buttonColor),
      ),
      onPressed: () {
        _updateEggSize(label);
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final bgColor = primaryColor[100]!.withOpacity(1);
    final accentColor = primaryColor[900];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Select egg size:'),
        backgroundColor: accentColor,
        elevation: 0,
        actions: <Widget>[
          buildEggButton('S', 32, buttonColorS),
          buildEggButton('M', 36, buttonColorM),
          buildEggButton('L', 40, buttonColorL),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _renderEggImage('soft', bgColor),
            _renderClock(),
            _renderEggImage('hard', bgColor),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pressButton,
        backgroundColor: accentColor,
        elevation: 0,
        child: _renderPlayIcon(),
      ),
    );
  }
}
