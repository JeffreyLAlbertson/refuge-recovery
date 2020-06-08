import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:refugerecovery/data/reading.dart';
import 'package:refugerecovery/data/sit.dart';
import 'package:refugerecovery/globals.dart' as globals;

class MeditationsPlayerScreen extends StatefulWidget {
  final Reading r;

  MeditationsPlayerScreen(this.r);

  @override
  _MeditationsPlayerScreenState createState() =>
      _MeditationsPlayerScreenState();
}

class _MeditationsPlayerScreenState extends State<MeditationsPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Refuge Recovery",
                style: TextStyle(
                    fontFamily: "Helvetica",
                    color: Color.fromRGBO(0, 0, 0, 1))),
            backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
        body: Center(child: Player(widget.r)));
  }
}

class Player extends StatefulWidget {
  final Reading r;

  Player(this.r);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final postUrl = 'https://refugerecoverydata.azure-api.net/api/sits';
  Sit sit;
  File file;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Duration sitDuration = Duration.zero;
  AudioCache cache;
  AudioPlayer player;
  Timer timer;
  int prevTick = 0;

  bool _isStarted = false;
  bool _isPlaying = false;
  bool _isCounting = false;

  bool _isSilent = false;

  double progress = 0.0;

  final DateFormat dayFormat = new DateFormat("MMMM d, yyyy");
  final DateFormat timeFormat = new DateFormat("h:mm:ss aa");

  void postSit() async {
    var response = await http.post(postUrl,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
          "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
        },
        body: sit.toJson());
    sit = Sit.fromJson(json.decode(response.body));
  }

  @override
  void dispose() {
    if (!_isSilent) {
      player.stop();
      cache.clear(widget.r.fileName);
    }
    _isPlaying = false;
    super.dispose();
  }

  @override
  void initState() {
    _isSilent = widget.r.fileName == null;
    duration = widget.r.length;
    super.initState();
  }

  void _startPlayer() {
    if (!_isSilent) {
      player = new AudioPlayer();

      if (widget.r.isLocal) {
        cache = new AudioCache(prefix: 'meditation_audio/');
        cache
            .load(widget.r.fileName)
            .then((f) => player.play(f.path, isLocal: widget.r.isLocal));
      } else {
        player.play(widget.r.fileName);
      }

      player.onAudioPositionChanged.listen((Duration p) {
        setState(() => setSliderValue(p));
      });
      player.onPlayerCompletion.listen((event) {
        setState(() {
          _isPlaying = false;
          _isStarted = false;
          position = duration;
        });
      });
    }

    if (!_isCounting) {
      timer = Timer.periodic(Duration(seconds: 1), (t) {
        if (this.mounted) {
          setState(() {
            if (_isCounting) {
              sitDuration = Duration(seconds: prevTick + timer.tick);
            } else {
              t.cancel();
            }
          });
        }
      });
    }

    _isStarted = true;
    _isPlaying = true;

    _isCounting = true;
  }

  void _initSit() {
    sit = Sit(
        sitId: '00000000-0000-0000-0000-000000000000',
        seq: 0,
        startTime: DateTime.now(),
        endTime: DateTime.parse('0001-01-01'),
        length: Duration(milliseconds: 0),
        date: DateTime.now(),
        meditationId: widget.r.meditationId,
        userId: globals.currentUser.userId);
  }

  void _togglePlay() {
    setState(() {
      if (!_isStarted) {
        _startPlayer();
        _initSit();
        return;
      }

      if (_isPlaying) {
        if (!_isSilent) {
          player.pause();
        }
        _isPlaying = false;
      } else {
        if (!_isSilent) {
          player.resume();
        }
        _isPlaying = true;
      }
    });
  }

  String formatDuration(Duration d) {
    String s = (new Duration(seconds: d.inSeconds)).toString();
    s = s.substring(0, s.indexOf('.'));
    return s;
  }

  void setSliderValue(Duration p) {
    position = p;
    progress = position.inSeconds / duration.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(shrinkWrap: true, children: [
      Container(
          padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 0.0),
          child: Column(children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Visibility(
                    visible: _isStarted,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Text('Pause/Save',
                        style: TextStyle(
                            fontFamily: 'HelveticaNeue', fontSize: 18.0)))
              ],
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Visibility(
                  visible: _isCounting,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: IconButton(
                      padding: EdgeInsets.all(0.0),
                      iconSize: 50.0,
                      icon: Icon(Icons.save),
                      color: Color.fromRGBO(165, 132, 41, 1),
                      onPressed: () async {
                        _isCounting = false;
                        prevTick = prevTick + timer.tick;
                        sit.length = Duration(seconds: prevTick);
                        sit.endTime = DateTime.now();

                        bool wasPlaying = _isPlaying;
                        _isPlaying = false;
                        if (!_isSilent) {
                          player.pause();
                        }

                        var doUpdate = await showDialog(
                            context: context,
                            child: AlertDialog(
                                content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 5.0),
                                      child: Text(
                                          globals.currentUser.displayName,
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18.0))),
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 5.0),
                                      child: Text(dayFormat.format(sit.date),
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.0))),
                                  SizedBox(height: 10.0),
                                  Container(
                                      alignment: Alignment.topLeft,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 5.0),
                                      child: Text('Meditation',
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.0))),
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 5.0, horizontal: 5.0),
                                      child: Text(widget.r.meditationName,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontSize: 24.0))),
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 5.0, horizontal: 5.0),
                                      child: Text(widget.r.reader,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontSize: 24.0))),
                                  Container(
                                      alignment: Alignment(-1.0, 0.0),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 5.0),
                                      child: Text('Duration',
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.0))),
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 5.0, horizontal: 5.0),
                                      child: Text(formatDuration(sit.length),
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontSize: 24.0))),
                                  Container(
                                      alignment: Alignment(-1.0, 0.0),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 0.0, horizontal: 5.0),
                                      child: Text('Start Time',
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16.0))),
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 5.0, horizontal: 5.0),
                                      child: Text(
                                          timeFormat
                                              .format(sit.startTime)
                                              .toLowerCase(),
                                          style: TextStyle(
                                              fontFamily: 'HelveticaNeue',
                                              fontSize: 24.0))),
                                  SizedBox(height: 5.0),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        new FlatButton(
                                            child: Text("Save and End"),
                                            color:
                                                Color.fromRGBO(165, 132, 41, 1),
                                            onPressed: () async {
                                              Navigator.pop(context, true);
                                            }),
                                        new Container(
                                          width: 10.0,
                                        ),
                                        new FlatButton(
                                            child: Text("Resume"),
                                            color:
                                                Color.fromRGBO(165, 132, 41, 1),
                                            onPressed: () async {
                                              Navigator.pop(context, false);
                                            }),
                                      ])
                                ])));

                        if (doUpdate == null || !doUpdate) {
                          _isCounting = true;
                          if (wasPlaying) {
                            _isPlaying = true;
                            if (!_isSilent) {
                              player.resume();
                            }
                          }

                          timer = Timer.periodic(Duration(seconds: 1), (t) {
                            if (this.mounted) {
                              setState(() {
                                if (_isCounting) {
                                  sitDuration =
                                      Duration(seconds: prevTick + timer.tick);
                                } else {
                                  t.cancel();
                                }
                              });
                            }
                          });
                        } else {
                          postSit();
                          Navigator.pop(context);
                        }
                      }))
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Text(formatDuration(sitDuration),
                  style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 36.0))
            ]),
          ])),
      Container(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
          child: Text(widget.r.meditationName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "HelveticaNeue",
                fontSize: 24.0,
              ))),
      Container(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
          child: Text(widget.r.reader == null ? '' : widget.r.reader,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "HelveticaNeue",
                fontSize: 24.0,
              ))),
      Visibility(
          visible: MediaQuery.of(context).size.height >
              MediaQuery.of(context).size.width,
          child: Container(
              margin: EdgeInsets.symmetric(vertical: 40.0, horizontal: 0.0),
              child: Image(
                image: AssetImage(
                    'assets/meditation_icons/' + widget.r.logoFileName),
                width: 120.0,
                height: 120.0,
              ))),
      SizedBox(height: 10.0),
      Visibility(
          visible: widget.r.fileName != null,
          child: Container(
            child: Text(
                formatDuration(position) + '/' + formatDuration((duration))),
            alignment: Alignment.center,
          )),
      Visibility(
          visible: widget.r.fileName != null,
          child: Slider(
            value: progress,
            min: 0.0,
            max: 1.0,
            divisions: 1000,
            activeColor: Color.fromRGBO(165, 132, 41, 1),
            inactiveColor: Colors.grey,
            onChanged: (double d) {
              setState(() {
                player.seek(
                    new Duration(seconds: (d * duration.inSeconds).round()));
              });
            },
          )),
      Visibility(
          visible: !_isSilent || !_isPlaying,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                    padding: EdgeInsets.all(0.0),
                    iconSize: 50.0,
                    icon:
                        _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
                    color: _isPlaying
                        ? Colors.grey
                        : Color.fromRGBO(165, 132, 41, 1),
                    onPressed: _togglePlay),
              ])),
      Visibility(
          visible: !_isSilent || !_isPlaying,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Container(
              alignment: Alignment.center,
              child: Text(_isPlaying ? 'Pause' : _isSilent ? 'Start' : 'Play',
                  style:
                      TextStyle(fontFamily: 'HelveticaNeue', fontSize: 18.0)))),
      SizedBox(height: 5.0)
    ]);
  }
}
