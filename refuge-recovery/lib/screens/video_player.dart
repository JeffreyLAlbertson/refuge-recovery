import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:refugerecovery/data/video.dart';
import 'package:video_player/video_player.dart';

class VideosPlayerScreen extends StatefulWidget {
  final Video v;
  VideosPlayerScreen(this.v);

  @override
  _VideosPlayerScreenState createState() => _VideosPlayerScreenState();
}

class _VideosPlayerScreenState extends State<VideosPlayerScreen> {
  VideoPlayerController _controller;

  double _progress = 0.0;
  bool _buttonVisible = false;
  Timer _timer;
  bool _hideButton = false;

  final DateFormat dayFormat = new DateFormat("MMMM d, yyyy");
  final DateFormat timeFormat = new DateFormat("h:mm:ss aa");

  String formatDuration(Duration d) {
    String s = (new Duration(seconds: d.inSeconds)).toString();
    s = s.substring(0, s.indexOf('.'));
    return s;
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 3);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          _buttonVisible = false;
          timer.cancel();
        },
      ),
    );
  }

  bool _seekingToZero = false;

  void _listener() {
    setState(() {
      int pos = _controller.value.position.inMilliseconds;
      int dur = _controller.value.duration.inMilliseconds;
      double progress = pos / dur;
      if (pos < dur) {
        _seekingToZero = false;
        _progress = progress;
      } else {
        if (!_seekingToZero) {
          _seekingToZero = true;
          _controller.seekTo(Duration(microseconds: 0));
          _controller.pause();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.v.fileName)
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Refuge Recovery",
              style: TextStyle(
                  fontFamily: "Helvetica", color: Color.fromRGBO(0, 0, 0, 1))),
          backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
      body: Center(
        child: Flex(
            direction: MediaQuery.of(context).size.height >=
                    MediaQuery.of(context).size.width
                ? Axis.vertical
                : Axis.horizontal,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _buttonVisible = true;
                    startTimer();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(children: [
                      VideoPlayer(
                        _controller,
                      ),
                      Visibility(
                        visible: _buttonVisible,
                        child: Center(
                          child: IconButton(
                              icon: Icon(_controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow),
                              iconSize: 250.0,
                              color: Colors.blue,
                              onPressed: () {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                                _buttonVisible = false;
                                _timer.cancel();
                              }),
                        ),
                      ),
                      Container(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 24.0,
                            alignment: Alignment.topCenter,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 8.0,
                              ),
                              child: Slider(
                                value: _progress,
                                inactiveColor: Colors.red,
                                onChanged: (double value) {
                                  setState(() {
                                    _progress = value;
                                    if (_progress > 0) {
                                      _controller.seekTo(Duration(
                                          milliseconds: (value *
                                                  _controller.value.duration
                                                      .inMilliseconds)
                                              .toInt()));
                                    }
                                  });
                                },
                              ),
                            ),
                          )),
                    ]),
                  ),
                ),
              ),
              Flexible(
                  fit: FlexFit.loose,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                        color: Colors.grey,
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ListView(children: [
                            Text(widget.v.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'HelveticaNeue')),
                            SizedBox(height: 10.0),
                            Text("Date",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'HelveticaNeue')),
                            Text(dayFormat.format(widget.v.date),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontFamily: 'HelveticaNeue')),
                            SizedBox(height: 10.0),
                            Text("Length",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'HelveticaNeue')),
                            Text(formatDuration(widget.v.length),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontFamily: 'HelveticaNeue')),
                            SizedBox(height: 10.0),
                            Text("Description",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'HelveticaNeue')),
                            Text(widget.v.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontFamily: 'HelveticaNeue'))
                          ]),
                        )),
                  ))
            ]),
      ),
    );
  }
}
