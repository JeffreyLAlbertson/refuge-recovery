import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/meditation.dart';
import 'package:refugerecovery/screens/meditation_player.dart';

Future<List<Meditation>> fetchResults(http.Client client) async {
  final response = await client.get(
      'https://refugerecoverydata.azure-api.net/api/meditations',
      headers: {
        "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
      });
  return compute(parseResults, response.body);
}

List<Meditation> parseResults(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Meditation>((json) => Meditation.fromJson(json)).toList();
}

class MeditationsScreen extends StatefulWidget {
  @override
  _MeditationScreensState createState() => _MeditationScreensState();
}

class _MeditationScreensState extends State<MeditationsScreen> {
  bool isLoaded = false;
  var _meditations = <Meditation>[];
  var _flatImageButtons = <Widget>[];

  Widget _getFlatImageButton(Meditation m) {
    return FlatButton(
      padding: EdgeInsets.all(5),
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => MeditationsPlayerScreen(m)));
      },
      child: Column(
        children: <Widget>[
          Image(
            image: AssetImage('assets/meditation_icons/' + m.logoFileName),
            width: 60.0,
          ),
          SizedBox(
              width: 80.0,
              child: Text(m.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'HelveticaNeue',
                      fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  Future<void> getData() async {
    _meditations = await fetchResults(http.Client());
    if (!isLoaded) {
      setState(() {
        _meditations.where((Meditation m) {
          return (m.logoFileName != null);
        }).forEach((Meditation m) {
          _flatImageButtons.add(_getFlatImageButton(m));
        });
        isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    getData();
    return Center(
        child: ListView(children: [
      Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: Wrap(
              children: _flatImageButtons, alignment: WrapAlignment.center))
    ]));
  }
}
