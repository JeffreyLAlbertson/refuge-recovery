import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:refugerecovery/data/meditation.dart';
import 'package:refugerecovery/data/reading.dart';
import 'package:refugerecovery/screens/meditation_player.dart';
import 'package:refugerecovery/screens/meditations.dart';
import 'package:refugerecovery/screens/start.dart';
import 'package:refugerecovery/screens/stats.dart';
import 'package:refugerecovery/screens/user_sits.dart';
import 'package:refugerecovery/screens/videos.dart';

import 'meetings.dart';

Future<List<Reading>> fetchResults(
    http.Client client, String meditationId) async {
  final response = await client.get(
      'https://refugerecoverydata.azure-api.net/api/meditation-readings/' +
          meditationId,
      headers: {
        "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
      });
  return compute(parseResults, response.body);
}

List<Reading> parseResults(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Reading>((json) => Reading.fromJson(json)).toList();
}

class ReadingsScreen extends StatefulWidget {
  final Meditation m;
  ReadingsScreen(this.m);

  @override
  _ReadingsScreensState createState() => _ReadingsScreensState();
}

class _ReadingsScreensState extends State<ReadingsScreen> {
  int _pageIndex = 3;
  List<Reading> _readings = <Reading>[];
  Widget _screenBody;

  final List<Widget> _children = [
    StartScreen(),
    VideosScreen(),
    MeetingsScreen(),
    MeditationsScreen(),
    UserSitsScreen(),
    StatsScreen(),
  ];

  Future<List<Reading>> getReadings() async {
    return await fetchResults(http.Client(), widget.m.meditationId);
  }

  List<FlatButton> _getReadingButtons(BuildContext context) {
    List<FlatButton> readingButtons = [];
    int index = 0;
    _readings.forEach((Reading r) {
      readingButtons.add(FlatButton(
        padding: EdgeInsets.all(5),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => MeditationsPlayerScreen(r)));
        },
        child: Column(
          children: <Widget>[
            Image(
              image: AssetImage('assets/meditation_icons/' +
                  (((index++) % 4) + 1).toString() +
                  '.png'),
              width: 60.0,
            ),
            SizedBox(
                width: 80.0,
                child: Text(r.reader == null ? '' : r.reader,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Metropolis', fontWeight: FontWeight.bold)))
          ],
        ),
      ));
    });
    return readingButtons;
  }

  setScreenBody(context) {
    setState(() {
      _screenBody = Center(
          child: Container(
        color: Color.fromRGBO(238, 236, 230, 1),
        child: ListView(children: [
          SizedBox(height: 15.0),
          Text(widget.m.name,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Metropolis', fontSize: 36.0)),
          SizedBox(height: 15.0),
          Wrap(
              alignment: WrapAlignment.center,
              children: _getReadingButtons(context))
        ]),
      ));
    });
  }

  createDir() async {
    String meditationsRoot = path.join(
        (await getApplicationDocumentsDirectory()).path, "Meditations");
    String meditationDir = path.join(meditationsRoot, widget.m.folderName);
    var dir = Directory(meditationDir);
    if (!await dir.exists()) {
      dir.create();
    }
  }

  @override
  void initState() {
    super.initState();
    createDir();
    getReadings().then((readings) {
      _readings = readings;
      if (widget.m.name == 'Silent Meditation') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => MeditationsPlayerScreen(_readings[0])));
      } else {
        setScreenBody(context);
      }
    });
  }

  void onTabTapped(int index) {
    setState(() {
      _pageIndex = index;
      _screenBody = _children[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Refuge Recovery",
                style: TextStyle(
                    fontFamily: "Metropolis",
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(35, 40, 45, 1))),
            backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
        backgroundColor: Color.fromRGBO(238, 236, 230, 1),
        body: _screenBody,
        bottomNavigationBar: BottomNavigationBar(
            onTap: onTabTapped,
            currentIndex: _pageIndex,
            selectedItemColor: Color.fromRGBO(165, 132, 41, 1),
            unselectedItemColor: Color.fromRGBO(35, 40, 45, 1),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  backgroundColor: Color.fromRGBO(238, 236, 230, 1),
                  icon: Icon(Icons.home),
                  title: Text('Home')),
              BottomNavigationBarItem(
                  backgroundColor: Color.fromRGBO(238, 236, 230, 1),
                  icon: Icon(Icons.video_library),
                  title: Text('Videos')),
              BottomNavigationBarItem(
                  backgroundColor: Color.fromRGBO(238, 236, 230, 1),
                  icon: Icon(Icons.people),
                  title: Text('Meetings')),
              BottomNavigationBarItem(
                  backgroundColor: Color.fromRGBO(238, 236, 230, 1),
                  icon: Icon(Icons.audiotrack),
                  title: Text('Meditations')),
              BottomNavigationBarItem(
                  backgroundColor: Color.fromRGBO(238, 236, 230, 1),
                  icon: Icon(Icons.history),
                  title: Text('History')),
              BottomNavigationBarItem(
                  backgroundColor: Color.fromRGBO(238, 236, 230, 1),
                  icon: Icon(Icons.menu),
                  title: Text('Stats')),
            ]));
  }
}
