import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:path/path.dart' as path;
import 'package:refugerecovery/data/chime.dart';
import 'package:refugerecovery/data/reading.dart';
import 'package:refugerecovery/data/sit.dart';
import 'package:refugerecovery/globals.dart' as globals;

Chime parseUserChime(String responseBody) {
  final parsed = json.decode(responseBody);
  Chime chime = Chime.fromJson(parsed);
  return chime;
}

List<Chime> parseChimes(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Chime>((json) => Chime.fromJson(json)).toList();
}

class SilentMeditationPlayerScreen extends StatefulWidget {
  SilentMeditationPlayerScreen();

  @override
  _SilentMeditationPlayerScreenState createState() =>
      _SilentMeditationPlayerScreenState();
}

class _SilentMeditationPlayerScreenState
    extends State<SilentMeditationPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Refuge Recovery",
                style: TextStyle(
                    fontFamily: "Metropolis",
                    color: Color.fromRGBO(0, 0, 0, 1))),
            backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
        body: Center(child: SilentPlayer()));
  }
}

class SilentPlayer extends StatefulWidget {
  SilentPlayer();

  @override
  _SilentPlayerState createState() => _SilentPlayerState();
}

class _SilentPlayerState extends State<SilentPlayer> {
  static FlutterFFmpeg ffmpeg = new FlutterFFmpeg();

  final postUrl = 'https://refugerecoverydata.azure-api.net/api/sits';
  Sit sit;
  Reading reading;
  File file;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Duration sitDuration = Duration.zero;
  int meditationMinutes = 20;
  AudioCache cache;
  AudioPlayer samplePlayer;
  AudioPlayer player;
  Chime chime;
  static TextStyle chimeNameStyle =
      TextStyle(fontSize: 24.0, fontFamily: 'Metropolis');
  Text chimeNameText = Text("");
  Timer timer;
  int prevTick = 0;

  bool _isStarted = false;
  bool _isPlaying = false;
  bool _isCounting = false;
  bool _isLoading = true;

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

  Future<Chime> getUserChime(http.Client client) async {
    final response = await client.get(
        'https://refugerecoverydata.azure-api.net/api/chimes/' +
            globals.currentUser.userId,
        headers: {
          "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
        });
    Chime chime = await compute(parseUserChime, response.body);
    return chime;
  }

  Future<Chime> setUserChime(http.Client client, String chimeId) async {
    final response = await client.get(
        'https://refugerecoverydata.azure-api.net/api/chimes/' +
            globals.currentUser.userId +
            "/" +
            chimeId,
        headers: {
          "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
        });
    Chime chime = await compute(parseUserChime, response.body);
    return chime;
  }

  Future<Chime> updateUserChime(String chimeId) async {
    return await setUserChime(http.Client(), chimeId);
  }

  Future<List<Chime>> getChimes(http.Client client) async {
    final response = await client
        .get('https://refugerecoverydata.azure-api.net/api/chimes', headers: {
      "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
    });
    return compute(parseChimes, response.body);
  }

  void _initSit() {
    sit = Sit(
        sitId: '00000000-0000-0000-0000-000000000000',
        seq: 0,
        startTime: DateTime.now(),
        endTime: DateTime.parse('0001-01-01'),
        length: Duration(milliseconds: 0),
        date: DateTime.now(),
        meditationId: 'DF38A4AB-614B-485F-B572-25E164A8E078',
        userId: globals.currentUser.userId);
  }

  void _initSilentReading() {
    reading = Reading(
        readingId: 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF',
        meditationId: 'DF38A4AB-614B-485F-B572-25E164A8E078',
        meditationName: 'Silent Meditation',
        folderName: 'silent',
        reader: null,
        isLocal: true,
        fileName: 'silent.mp3',
        logoFileName: '',
        language: 'en-us');
  }

  Future<void> getSoundFile(
      bool isLocal, String pathSrc, String pathDst) async {
    File fileDst = File(pathDst);
    if (!fileDst.existsSync()) {
      if (isLocal) {
        final bytes = await rootBundle.load(pathSrc);
        ByteBuffer buf = bytes.buffer;
        fileDst.writeAsBytesSync(
            buf.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      } else {
        _isLoading = true;
        Dio dio = new Dio();
        await dio.download(pathSrc, pathDst);
        _isLoading = false;
      }
    }
  }

  Future<void> createChimedReading() async {
    Util util = Util(chime, reading);

    Directory dirChimedReadingDst = Directory(util.pathChimedReadingDirDst);

    if (!dirChimedReadingDst.existsSync()) {
      dirChimedReadingDst.createSync();
    }

    String pathOutput = path.join(
        util.dstMeditationPath,
        chime.chimeId +
            '-' +
            reading.readingId +
            '-' +
            meditationMinutes.toString() +
            '.mp3');

    if (!File(pathOutput).existsSync()) {
      await getSoundFile(chime.isLocal, util.pathChimeSrc, util.pathChimeDst);

      await getSoundFile(
          true,
          path.join(util.srcMeditationPath, 'silent-100.mp3'),
          path.join(util.dstMeditationPath, 'silent-100.mp3'));

      await getSoundFile(
          true,
          path.join(util.srcMeditationPath, 'silent-10.mp3'),
          path.join(util.dstMeditationPath, 'silent-10.mp3'));

      await getSoundFile(
          true,
          path.join(util.srcMeditationPath, 'silent-1.mp3'),
          path.join(util.dstMeditationPath, 'silent-1.mp3'));

      await getSoundFile(
          chime.isLocal, util.pathEndChimeSrc, util.pathEndChimeDst);

      File chimedReading = File(util.pathChimedReadingDst);
      if (chimedReading.existsSync()) {
        chimedReading.deleteSync();
      }

      String pathFileInput =
          path.join(util.pathChimedReadingDirDst, 'list.txt');
      File fileInput = File(pathFileInput);
      if (fileInput.existsSync()) {
        fileInput.deleteSync();
      }

      String pathChime = util.pathChimeDst;
      String pathEndChime = util.pathEndChimeDst;

      String input = "file '$pathChime'\n";

      int minutesCalc = meditationMinutes;
      for (int i = 2; i >= 0; i--) {
        int pow10 = pow(10, i);
        int adds = (minutesCalc / pow10).floor();
        for (int i = 0; i < adds; i++) {
          String pathReading = path.join(
              util.dstMeditationPath, 'silent-' + pow10.toString() + '.mp3');
          input += "file '$pathReading'\n";
        }
        minutesCalc = minutesCalc % pow10;
      }

      input += "file '$pathEndChime'\n";

      fileInput.writeAsStringSync(input);

      await ffmpeg.execute(
          '-y -f concat -safe 0 -i "$pathFileInput" -c copy "$pathOutput" -loglevel warning');
    }

    // update user interface with new chimed reading duration
    // (play/pause, then seek again to begin)
    await startSetChimedReadingDuration(pathOutput);
  }

  Future<void> startSetChimedReadingDuration(
      String pathDstChimedReadingFile) async {
    await player.play(pathDstChimedReadingFile,
        isLocal: true, respectSilence: true);
    Timer(Duration(milliseconds: 100), completeSetChimedReadingDuration);
  }

  void completeSetChimedReadingDuration() async {
    await player.pause();
    await player.seek(Duration(milliseconds: 0));
    if (this.mounted) {
      setState(() {
        position = Duration(milliseconds: 0);
        _isLoading = false;
      });
    }
  }

  void createChimedReadingDir() {
    Directory dirDstChimedReading =
        Directory(Util(chime, reading).pathChimedReadingDirDst);
    if (!dirDstChimedReading.existsSync()) {
      dirDstChimedReading.create();
    }
  }

  Future<void> getChimeInfo() async {
    chime = await getUserChime(http.Client());
    setState(() {
      chimeNameText = Text(chime.chimeName, style: chimeNameStyle);
    });
    createChimedReadingDir();
    await createChimedReading();
  }

  void _startPlayer() {
    player.resume();

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

  void _togglePlay() async {
    setState(() {
      if (!_isStarted) {
        _startPlayer();
        _initSit();
        return;
      }

      if (_isPlaying) {
        player.pause();
        _isPlaying = false;
      } else {
        player.resume();
        _isPlaying = true;
      }
    });
  }

  String formatDuration(Duration d) {
    String s = (new Duration(seconds: d.inSeconds)).toString();
    s = s.substring(0, s.indexOf('.'));
    return s;
  }

  @override
  void dispose() {
    if (this.mounted) {
      player.stop();
      player.release();
    }
    _isPlaying = false;
    super.dispose();
  }

  @override
  void initState() {
    _initSilentReading();

    getChimeInfo();
    player = new AudioPlayer();
    samplePlayer = new AudioPlayer();
    cache = new AudioCache(fixedPlayer: samplePlayer);

    player.onAudioPositionChanged.listen((Duration p) {
      if (this.mounted) {
        setState(() {
          position = p;
          progress = position >= duration
              ? 1.0
              : position.inSeconds / duration.inSeconds;
        });
      }
    });

    player.onDurationChanged.listen((Duration d) {
      if (this.mounted) {
        setState(() {
          duration = d;
        });
      }
    });

    player.onPlayerCompletion.listen((event) {
      if (this.mounted) {
        setState(() {
          _isPlaying = false;
          _isStarted = false;
          position = duration;
        });
      }
    });

    super.initState();
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
                            fontFamily: 'Metropolis', fontSize: 18.0)))
              ],
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Visibility(
                  visible: _isCounting,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: getSaveIcon())
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Text(formatDuration(sitDuration),
                  style: TextStyle(fontFamily: 'Metropolis', fontSize: 36.0))
            ]),
          ])),
      Container(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
          child: Text(reading.meditationName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Metropolis",
                fontSize: 24.0,
              ))),
      Container(
          height: 150.0,
          margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          alignment: Alignment.center,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: 100.0,
                    height: 150.0,
                    alignment: Alignment.center,
                    child: Text("Minutes:",
                        style: TextStyle(
                            fontFamily: 'Metropolis', fontSize: 16.0))),
                Container(
                    width: 100.0,
                    height: 150.0,
                    margin:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
                    child: new NumberPicker.integer(
                        initialValue: meditationMinutes,
                        minValue: 1,
                        maxValue: 120,
                        onChanged: (value) {
                          meditationMinutes = value;
                        })),
                Container(
                  width: 100.0,
                  height: 150.0,
                  margin:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            alignment: Alignment.center,
                            icon: Icon(Icons.timer),
                            iconSize: 50.0,
                            color: Color.fromRGBO(165, 132, 41, 1),
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              player.release();
                              _isPlaying = false;
                              await createChimedReading();
                              setState(() {
                                _isLoading = false;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Set',
                              style: TextStyle(
                                fontFamily: "Metropolis",
                                fontSize: 16.0,
                              ))
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Duration',
                              style: TextStyle(
                                fontFamily: "Metropolis",
                                fontSize: 16.0,
                              ))
                        ],
                      )
                    ],
                  ),
                )
              ])),
      Container(
          child: Center(
              child: Text('Chime',
                  style: TextStyle(fontSize: 16.0, fontFamily: 'Metropolis')))),
      SizedBox(height: 5.0),
      Container(child: Center(child: chimeNameText)),
      Container(child: getChimeIcon()),
      Container(
          child: Center(
              child: Text('Select Chime',
                  style: TextStyle(fontSize: 16.0, fontFamily: 'Metropolis')))),
      SizedBox(height: 25.0),
      Center(
        child: Text(formatDuration(position) + '/' + formatDuration((duration)),
            style: TextStyle(fontFamily: 'Metropolis')),
      ),
      Visibility(
          visible: reading.fileName != null,
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
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _isLoading
            ? SpinKitPouringHourglass(
                color: Color.fromRGBO(165, 132, 41, 1), size: 50.0)
            : IconButton(
                padding: EdgeInsets.all(0.0),
                iconSize: 50.0,
                icon: _isPlaying ? Icon(Icons.stop) : Icon(Icons.play_arrow),
                color:
                    _isPlaying ? Colors.grey : Color.fromRGBO(165, 132, 41, 1),
                onPressed: _togglePlay),
      ]),
      Container(
          alignment: Alignment.center,
          child: Text(
              _isLoading ? 'Building...' : _isPlaying ? 'Pause' : 'Play',
              style: TextStyle(fontFamily: 'Metropolis', fontSize: 18.0))),
      SizedBox(height: 5.0)
    ]);
  }

  Widget getSaveIcon() {
    return IconButton(
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
          player.pause();

          var doUpdate = await showDialog(
              context: context,
              child: AlertDialog(
                  content:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
                    child: Text(globals.currentUser.displayName,
                        style: TextStyle(
                            fontFamily: 'Metropolis',
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0))),
                Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
                    child: Text(dayFormat.format(sit.date),
                        style: TextStyle(
                            fontFamily: 'Metropolis',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0))),
                SizedBox(height: 10.0),
                Container(
                    alignment: Alignment.topLeft,
                    padding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
                    child: Text('Meditation',
                        style: TextStyle(
                            fontFamily: 'Metropolis',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0))),
                Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                    child: Text(reading.meditationName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Metropolis', fontSize: 24.0))),
                Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                    child: Text('',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Metropolis', fontSize: 24.0))),
                Container(
                    alignment: Alignment(-1.0, 0.0),
                    padding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
                    child: Text('Duration',
                        style: TextStyle(
                            fontFamily: 'Metropolis',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0))),
                Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                    child: Text(formatDuration(sit.length),
                        style: TextStyle(
                            fontFamily: 'Metropolis', fontSize: 24.0))),
                Container(
                    alignment: Alignment(-1.0, 0.0),
                    padding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
                    child: Text('Start Time',
                        style: TextStyle(
                            fontFamily: 'Metropolis',
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0))),
                Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                    child: Text(timeFormat.format(sit.startTime).toLowerCase(),
                        style: TextStyle(
                            fontFamily: 'Metropolis', fontSize: 24.0))),
                SizedBox(height: 5.0),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new FlatButton(
                          child: Text("Save and End"),
                          color: Color.fromRGBO(165, 132, 41, 1),
                          onPressed: () async {
                            Navigator.pop(context, true);
                          }),
                      new Container(
                        width: 10.0,
                      ),
                      new FlatButton(
                          child: Text("Resume"),
                          color: Color.fromRGBO(165, 132, 41, 1),
                          onPressed: () async {
                            Navigator.pop(context, false);
                          }),
                    ])
              ])));

          if (doUpdate == null || !doUpdate) {
            _isCounting = true;
            if (wasPlaying) {
              _isPlaying = true;
              player.resume();
            }
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
          } else {
            postSit();
            Navigator.pop(context);
          }
        });
  }

  Widget getChimeIcon() {
    return IconButton(
        padding: EdgeInsets.all(0.0),
        iconSize: 50.0,
        icon: Icon(Icons.queue_music),
        color: Color.fromRGBO(165, 132, 41, 1),
        onPressed: () async {
          player.pause();
          _isPlaying = false;

          List<Chime> chimes = await getChimes(http.Client());
          int _current = 0;

          var updateChime = await showDialog(
              context: context,
              child: ListView(children: [
                CarouselSlider(
                  items: chimes.map((chime) {
                    return Builder(builder: (BuildContext context) {
                      return Container(
                          width: 300.0,
                          color: Color.fromRGBO(238, 236, 230, 1),
                          child: Container(
                              margin: EdgeInsets.all(15.0),
                              child: ListView(children: [
                                Text(chime.chimeName,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 24.0,
                                        fontFamily: 'Metropolitan',
                                        fontWeight: FontWeight.normal,
                                        color: Color.fromRGBO(35, 40, 35, 1),
                                        decoration: TextDecoration.none)),
                                SizedBox(height: 10.0),
                                Image.asset(
                                    'assets/chime_photos/' + chime.logoFileName,
                                    width: 265.0,
                                    height: 325.0),
                                SizedBox(height: 10.0),
                                Text(chime.description,
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontFamily: 'Metropolitan',
                                        fontWeight: FontWeight.normal,
                                        color: Color.fromRGBO(35, 40, 35, 1),
                                        decoration: TextDecoration.none)),
                                SizedBox(height: 10.0),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 100.0),
                                  child: Card(
                                    child: IconButton(
                                        icon: Icon(Icons.play_arrow),
                                        iconSize: 35.0,
                                        onPressed: () async {
                                          await cache.play(
                                              'meditation_audio/_chimes/' +
                                                  chime.fileName);
                                        }),
                                  ),
                                )
                              ])));
                    });
                  }).toList(),
                  options: CarouselOptions(
                      autoPlay: false,
                      aspectRatio: 3 / 5,
                      height: 500.0,
                      enlargeCenterPage: false,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _current = index;
                        });
                      }),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new FlatButton(
                            child: Text("Select"),
                            color: Color.fromRGBO(165, 132, 41, 1),
                            onPressed: () async {
                              Navigator.pop(context, true);
                            }),
                        new Container(
                          width: 10.0,
                        ),
                        new FlatButton(
                            child: Text("Cancel"),
                            color: Color.fromRGBO(165, 132, 41, 1),
                            onPressed: () async {
                              Navigator.pop(context, false);
                            }),
                      ])
                ])
              ]));

          if (!(updateChime == null || !updateChime)) {
            setState(() {
              if (chime.chimeId != chimes.elementAt(_current).chimeId) {
                _isLoading = true;
                player.release();
                chime = chimes.elementAt(_current);
                chimeNameText = Text(chime.chimeName, style: chimeNameStyle);
                updateUserChime(chime.chimeId);
                createChimedReading();
              }
            });
          }
          samplePlayer.stop();
          samplePlayer.release();
        });
  }
}

class Util {
  final Chime chime;
  final Reading reading;
  Util(this.chime, this.reading);

  static String get srcChimesPath {
    return 'assets/meditation_audio/_chimes';
  }

  static String get srcMeditationsPath {
    return 'assets/meditation_audio';
  }

  String get srcMeditationPath {
    return path.join(srcMeditationsPath, reading.folderName);
  }

  static String get dstMeditationsPath {
    return path.join(globals.appDocsDirectory.path, 'Meditations');
  }

  String get dstMeditationPath {
    return path.join(dstMeditationsPath, reading.folderName);
  }

  String getDstReadingPath() {
    return dstMeditationPath;
  }

  String get filenameReadingSrc {
    return reading.isLocal
        ? reading.fileName
        : reading.fileName.split("/").last;
  }

  String get pathReadingSrc {
    return reading.isLocal
        ? path.join(srcMeditationPath, filenameReadingSrc)
        : reading.fileName;
  }

  String get pathChimeSrc {
    return chime.isLocal
        ? path.join(srcChimesPath, chime.fileName)
        : chime.fileName;
  }

  String get pathEndChimeSrc {
    return chime.isLocal
        ? path.join(srcChimesPath, 'end-' + chime.fileName)
        : 'end-' + chime.fileName;
  }

  String get foldernameChimedReadingDst {
    return filenameReadingSrc.split(".").first;
  }

  String get pathChimedReadingDirDst {
    return dstMeditationPath;
  }

  String get filenameChimeDst {
    return chime.chimeId + '.mp3';
  }

  String get filenameEndChimeDst {
    return 'end-' + chime.chimeId + '.mp3';
  }

  String get filenameReadingDst {
    return reading.readingId + '.mp3';
  }

  String get filenameChimedReadingDst {
    return chime.chimeId + '-' + reading.readingId + '.mp3';
  }

  String get pathChimeDst {
    return path.join(pathChimedReadingDirDst, filenameChimeDst);
  }

  String get pathEndChimeDst {
    return path.join(pathChimedReadingDirDst, filenameEndChimeDst);
  }

  String get pathReadingDst {
    return path.join(pathChimedReadingDirDst, filenameReadingDst);
  }

  String get pathChimedReadingDst {
    return path.join(pathChimedReadingDirDst, filenameChimedReadingDst);
  }
}
