import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/video.dart';
import 'package:refugerecovery/screens/video_player.dart';

Future<List<Video>> fetchResults(http.Client client) async {
  final response = await client
      .get('https://refugerecoverydata.azure-api.net/api/videos', headers: {
    "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
  });
  return compute(parseResults, response.body);
}

List<Video> parseResults(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Video>((json) => Video.fromJson(json)).toList();
}

class VideosScreen extends StatefulWidget {
  @override
  _VideosScreensState createState() => _VideosScreensState();
}

class _VideosScreensState extends State<VideosScreen> {
  bool isLoaded = false;
  var _videos = <Video>[];
  List<Widget> _videoFlatImageButtons = <Widget>[];

  Future<List<Video>> getVideos() async {
    return await fetchResults(http.Client());
  }

  void setVideoLinks(BuildContext context) {
    setState(() {
      int index = 0;
      _videos.forEach((Video v) {
        _videoFlatImageButtons.add(FlatButton(
          padding: EdgeInsets.all(5),
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => VideosPlayerScreen(v)));
          },
          child: Column(
            children: <Widget>[
              Image(
                image: AssetImage('assets/meditation_icons/' +
                    ((index++ % 4) + 1).toString() +
                    '.png'),
                width: 80.0,
              ),
              SizedBox(
                  width: 100.0,
                  child: Text(v.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Metropolis',
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(35, 40, 45, 1),
                      )))
            ],
          ),
        ));
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getVideos().then((videos) {
      _videos = videos;
      setVideoLinks(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ListView(children: [
      Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: Wrap(
              alignment: WrapAlignment.center,
              children: _videoFlatImageButtons))
    ]));
  }
}
