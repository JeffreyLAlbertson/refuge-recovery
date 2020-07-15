import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
                    fontFamily: "Metropolis",
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
  static FlutterFFmpeg ffmpeg = new FlutterFFmpeg();

  final postUrl = 'https://refugerecoverydata.azure-api.net/api/sits';
  Sit sit;
  File file;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  Duration sitDuration = Duration.zero;
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
        meditationId: widget.r.meditationId,
        userId: globals.currentUser.userId);
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
        final response = await dio.download(pathSrc, pathDst);
        _isLoading = false;
      }
    }
  }

  Future<void> createChimedReading() async {
    Util util = Util(chime, widget.r);

    Directory dirChimedReadingDst = Directory(util.pathChimedReadingDirDst);

    if (!dirChimedReadingDst.existsSync()) {
      dirChimedReadingDst.createSync();
    }

    await getSoundFile(chime.isLocal, util.pathChimeSrc, util.pathChimeDst);

    await getSoundFile(
        widget.r.isLocal, util.pathReadingSrc, util.pathReadingDst);

    await getSoundFile(
        chime.isLocal, util.pathEndChimeSrc, util.pathEndChimeDst);

    File chimedReading = File(util.pathChimedReadingDst);
    if (!chimedReading.existsSync()) {
      String pathFileInput =
          path.join(util.pathChimedReadingDirDst, 'list.txt');

      File fileInput = File(pathFileInput);
      if (fileInput.existsSync()) {
        fileInput.deleteSync();
      }

      String pathChime = util.pathChimeDst;
      String pathReading = util.pathReadingDst;
      String pathEndChime = util.pathEndChimeDst;

      fileInput.writeAsStringSync(
          "file '$pathChime'\nfile '$pathReading'\nfile '$pathEndChime'");

      String pathOutput = util.pathChimedReadingDst;
      await ffmpeg.execute(
          '-y -f concat -safe 0 -i "$pathFileInput" -c copy "$pathOutput" -loglevel warning');
    }

    // update user interface with new chimed reading duration
    // (play/pause, then seek again to begin)
    await startSetChimedReadingDuration(util.pathChimedReadingDst);
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
        Directory(Util(chime, widget.r).pathChimedReadingDirDst);
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

  void _startPlayer() async {
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

  void _togglePlay() {
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
          child: Text(widget.r.meditationName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Metropolis",
                fontSize: 24.0,
              ))),
      Container(
          padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 5.0),
          child: Text(widget.r.reader,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Metropolis",
                fontSize: 24.0,
              ))),
      Visibility(
          visible: MediaQuery.of(context).size.height >
              MediaQuery.of(context).size.width,
          child: Image(
            image:
                AssetImage('assets/meditation_icons/' + widget.r.logoFileName),
            width: 120.0,
            height: 120.0,
          )),
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
      Slider(
        value: progress,
        min: 0.0,
        max: 1.0,
        divisions: 1000,
        activeColor: Color.fromRGBO(165, 132, 41, 1),
        inactiveColor: Colors.grey,
        onChanged: (double d) {
          setState(() {
            player
                .seek(new Duration(seconds: (d * duration.inSeconds).round()));
          });
        },
      ),
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
      SizedBox(height: 5.0),
      Container(
          alignment: Alignment.center,
          child: Text(
              _isLoading ? 'Building...' : _isPlaying ? 'Pause' : 'Play',
              style: TextStyle(fontFamily: 'Metropolis', fontSize: 16.0))),
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
                    child: Text(widget.r.meditationName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Metropolis', fontSize: 24.0))),
                Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                    child: Text(widget.r.reader,
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

  String getDstReadingPath(String readingFolderName) {
    return path.join(dstMeditationPath, readingFolderName);
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
    return getDstReadingPath(foldernameChimedReadingDst);
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
