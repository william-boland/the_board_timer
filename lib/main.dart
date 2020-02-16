import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primaryColor: Colors.white,
        canvasColor: Colors.white,

      ),
      home: MyHomePage(title: 'The Board Timer'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _duration = 20; //duration of the count down
  int _resetDuration = 1; //duration waited before the timer is reset with a 1s animation
  int _resetDelayDuration = 3;
  int _repeatDelayDuration = 3;
  bool _repeat = false;

  AnimationController _controller;
  Animation<Color> _background;

  int _initialWarningTime = 10;
  bool _initialWarning = false;
  int _finalWarningTime = 5;
  bool _finalWarning = false;
  Future _resetDelay;
  AnimationStatus _animationStatus;

  void startTimer() {
    if (_controller.isAnimating) {
      _controller.stop(canceled: false);
      this.setState(() {});
    } else {
      _controller.forward(from: _controller.value == 1.0 ? 0.0 : _controller.value);
    }
  }

  String get timerString {
    Duration duration = _controller.duration * (1.0 - _controller.value);
    if (duration.inMilliseconds % 1000 == 0) {
      duration += new Duration(seconds: 1);
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${duration.inSeconds}';
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: _duration),
      reverseDuration: Duration(seconds: _resetDuration),
      vsync: this,
    );


    _background =
        ColorTween(begin: Colors.green, end: Colors.red).animate(_controller)
          ..addListener(colorListener)..addStatusListener(statusListener);
  }

  void reset() async {
    _controller.reverse(from: 1.0);
    _resetDelay = null;
  }

  void colorListener() async {
    Duration remaining = _controller.duration * (1.0 - _controller.value);

    if (!_initialWarning && remaining.inSeconds < _initialWarningTime && _controller.status == AnimationStatus.forward) {
      _initialWarning = true;
      if (await Vibration.hasVibrator()) {
        List<int> pattern = new List<int>();
        pattern.add(0);
        for (int i = 0; i < _initialWarningTime - _finalWarningTime; i++) {
          pattern.addAll([250, 750]);
        }

        Vibration.vibrate(pattern: pattern);
      }
    }

    if (!_finalWarning && remaining.inSeconds < _finalWarningTime && _controller.status == AnimationStatus.forward) {
      _finalWarning = true;
      if (await Vibration.hasVibrator()) {
        List<int> pattern = new List<int>();
        pattern.add(0);
        for (int i = 0; i < _finalWarningTime; i++) {
          pattern.addAll([250, 250, 250, 250]);
        }

        Vibration.vibrate(pattern: pattern);
      }
    }

    setState(() {});
  }

  void statusListener(AnimationStatus status) {
    if (_animationStatus != status) {
      if (_animationStatus == AnimationStatus.forward && status == AnimationStatus.completed && _resetDelay == null) {
        _initialWarning = false;
        _finalWarning = false;
        _resetDelay = new Future.delayed(Duration(seconds: _resetDelayDuration), reset);
      }

      _animationStatus = status;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        elevation: 0.0,
      ),
      body: Container(
          child: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: AspectRatio(
              aspectRatio: 1.0,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(),
                  ),
                  Expanded(
                    flex: 2,
                    child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                                child: CustomPaint(
                              painter: CustomTimerPainter(
                                  animation: _controller,
                                  backgroundColor: Color.fromRGBO(0, 0, 0, 0.2),
                                  color: _background.value),
                            )),
                            Center(
                              child: Text(
                                timerString,
                                style: Theme.of(context)
                                    .textTheme
                                    .display3
                                    .apply(color: _background.value),
                              ),
                            )
                          ],
                        )
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  )
                ],
              )),
        ),
      )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: startTimer,
        tooltip: 'Increment',
        icon: _controller.isAnimating
            ? Icon(Icons.pause)
            : Icon(Icons.play_arrow),
        label: Text(_controller.isAnimating ? "Pause" : "Start"),
        backgroundColor: _background.value,
        elevation: 0.0,
      ), // This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class CustomTimerPainter extends CustomPainter {
  CustomTimerPainter({
    this.animation,
    this.backgroundColor,
    this.color,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color backgroundColor, color;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color;
    double progress = (1.0 - animation.value) * 2 * math.pi;
    canvas.drawArc(Offset.zero & size, math.pi * 1.5, progress, false, paint);
  }

  @override
  bool shouldRepaint(CustomTimerPainter old) {
    return animation.value != old.animation.value ||
        color != old.color ||
        backgroundColor != old.backgroundColor;
  }
}
