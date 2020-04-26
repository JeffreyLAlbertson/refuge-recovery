import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/stats.dart';
import 'package:refugerecovery/globals.dart' as globals;
import 'package:intl/intl.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

Future<Stats> fetchResults(http.Client client) async {
  final response = await client.get(
      'https://refugerecoverydata.azure-api.net/api/sits/stats/' +
          globals.currentUser.userId.toUpperCase(),
      headers: {
        "Ocp-Apim-Subscription-Key": "570fd8d1df544dc4b3fe4dcb16f631ac"
      });
  return compute(parseResults, response.body);
}

Stats parseResults(String responseBody) {
  return Stats.fromJson(json.decode(responseBody));
}

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool isLoaded = false;
  Stats _stats = new Stats();
  var _containers = <Widget>[];

  final DateFormat dayFormat = new DateFormat("MMMM d, yyyy");
  final DateFormat timeFormat = new DateFormat("h:mm:ss aa");

  Future<void> getData() async {
    _stats = await fetchResults(http.Client());
    if (!isLoaded) {
      setState(() {
        _setContainer();
        isLoaded = true;
      });
    }
  }

  String formatDuration(Duration d) {
    String s = (new Duration(seconds: d.inSeconds)).toString();
    s = s.substring(0, s.indexOf('.'));
    return s;
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  List<TableRow> _getTableRows(List<SitRun> srs) {
    List<TableRow> _tableRows = <TableRow>[];
    _tableRows.add(TableRow(children: [
      Column(children: [
        Text('Consecutive Days',
            style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 16.0))
      ]),
      Column(children: [
        Text('End Date',
            style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 16.0))
      ])
    ]));

    srs.forEach((sr) {
      _tableRows.add(TableRow(children: [
        Column(children: [
          Text(sr.length.toString(),
              style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0))
        ]),
        Column(children: [
          Text(dayFormat.format(sr.endDate),
              style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0))
        ])
      ]));
    });
    return _tableRows;
  }

  void _setContainer() {
    _containers = <Widget>[
      SizedBox(height: 10.0),
      Container(
          height: 30.0,
          child: Text(globals.currentUser.displayName,
              style: TextStyle(
                  fontFamily: 'HelveticaNeue',
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0))),
      SizedBox(height: 25.0),
      Container(
          height: 25.0,
          child: Text('Consecutive Days',
              style: TextStyle(
                  fontFamily: 'HelveticaNeue',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0))),
      Container(
          height: 45.0,
          child: Text(_stats.currentRun.length.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 36.0))),
      Container(
          height: 24.0,
          child: Text('as of',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 16.0))),
      Container(
          height: 36.0,
          child: Text(dayFormat.format(_stats.currentRun.endDate),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0))),
      SizedBox(height: 25.0),
      Container(
          child: Text('Average Length',
              style: TextStyle(
                  fontFamily: 'HelveticaNeue',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0))),
      Container(
          height: 45.0,
          //padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
          child: Text(formatDuration(_stats.averageLength),
              style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 36.0))),
      SizedBox(height: 25.0),
      Container(
          height: 25.0,
          child: Text('Longest Runs',
              style: TextStyle(
                  fontFamily: 'HelveticaNeue',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0))),
      SizedBox(height: 5.0),
      Container(
          margin: EdgeInsets.symmetric(horizontal: 25.0, vertical: 0.0),
          child: Table(children: _getTableRows(_stats.sitRuns))),
      SizedBox(height: 25.0),
      Container(
          child: Text('Days with at Least One Sit',
              style: TextStyle(
                  fontFamily: 'HelveticaNeue',
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0))),
      Container(
          height: 45.0,
          child: Text(_stats.daysWithOneSession.toString(),
              style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 36.0))),
      Container(
          height: 40.0,
          child: Text('since ' + dayFormat.format(_stats.firstSitDate),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 16.0))),
      SizedBox(height: 10.0)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: ListView(
            shrinkWrap: true, children: [Column(children: _containers)]));
  }
}
