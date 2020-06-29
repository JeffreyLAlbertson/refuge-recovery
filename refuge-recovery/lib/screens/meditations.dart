import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/meditation.dart';
import 'package:refugerecovery/screens/readings.dart';

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
  List<Widget> _meditationFlatImageButtons = <Widget>[];

  Future<List<Meditation>> getMeditations() async {
    return await fetchResults(http.Client());
  }

  void _setMeditationButtons(BuildContext context) {
    setState(() {
      _meditations.where((Meditation m) {
        return m.logoFileName != null;
      }).forEach((Meditation m) {
        _meditationFlatImageButtons.add(FlatButton(
          padding: EdgeInsets.all(5),
          onPressed: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ReadingsScreen(m)));
          },
          child: Column(
            children: <Widget>[
              Image(
                image: AssetImage('assets/meditation_icons/' + m.logoFileName),
                width: 80.0,
              ),
              SizedBox(
                  width: 100.0,
                  child: Text(m.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Metropolis',
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
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
    getMeditations().then((meditations) {
      _meditations = meditations;
      _setMeditationButtons(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ListView(children: [
      Container(
          margin: EdgeInsets.symmetric(horizontal: 5),
          color: Color.fromRGBO(238, 236, 230, 1),
          child: Wrap(
              alignment: WrapAlignment.center,
              children: _meditationFlatImageButtons))
    ]));
  }
}
