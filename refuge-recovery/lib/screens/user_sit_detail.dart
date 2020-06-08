import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:refugerecovery/args/usersitdetails.dart';
import 'package:refugerecovery/data/meditation.dart';
import 'package:refugerecovery/data/sit.dart';
import 'package:refugerecovery/globals.dart' as globals;
import 'package:refugerecovery/screens/home.dart';

class UserSitDetailsScreen extends StatefulWidget {
  static const routeName = '/user_sit_detail';

  @override
  _UserSitDetailsScreenState createState() => _UserSitDetailsScreenState();
}

Future<List<Meditation>> fetchMeditations(http.Client client) async {
  final response = await client.get(
      'https://refugerecoverydata.azure-api.net/api/meditations',
      headers: {
        "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
      });
  return compute(parseMeditations, response.body);
}

List<Meditation> parseMeditations(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Meditation>((json) => Meditation.fromJson(json)).toList();
}

class _UserSitDetailsScreenState extends State<UserSitDetailsScreen> {
  var _meditations = <Meditation>[];

  final DateFormat dayFormat = new DateFormat("MMMM d, yyyy");
  final DateFormat timeFormat = new DateFormat("h:mm:ss aa");

  String formatDuration(Duration d) {
    String s = (new Duration(seconds: d.inSeconds)).toString();
    s = s.substring(0, s.indexOf('.'));
    return s;
  }

  TextStyle _textStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0);

  final String sitsUrl = 'https://refugerecoverydata.azure-api.net/api/sits';

  void putSit(Sit currentSit) {
    http
        .put(sitsUrl + '/' + currentSit.sitId,
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded",
              "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
            },
            body: currentSit.toJson())
        .then((response) {
      Navigator.pop(context);
      Navigator.popAndPushNamed(context, HomeScreen.routeNameHistory);
    });
  }

  void postSit(Sit currentSit) {
    print(currentSit.toJson());
    http
        .post(sitsUrl,
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded",
              "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
            },
            body: currentSit.toJson())
        .then((response) {
      Navigator.pop(context);
      Navigator.popAndPushNamed(context, HomeScreen.routeNameHistory);
    });
  }

  bool _isLoaded = false;
  bool _isNew = false;

  static DateTime now = DateTime.now();

  Sit _currentSit = Sit(
      sitId: '00000000-0000-0000-0000-000000000000',
      seq: 0,
      startTime: now,
      length: Duration.zero,
      date: DateTime(now.year, now.month, now.day),
      meditationId: 'df38a4ab-614b-485f-b572-25e164a8e078'.toUpperCase(),
      userId: globals.currentUser.userId);

  Future getData(UserSitDetailsArgs args) async {
    if (!_isLoaded) {
      _isLoaded = true;

      var result = await fetchMeditations(http.Client());

      setState(() {
        _meditations = result;
        _meditations.sort((a, b) {
          return a.name.compareTo(b.name);
        });

        _isNew = args.sitId == '00000000-0000-0000-0000-000000000000';

        _currentSit = Sit(
            sitId: args.sitId,
            seq: 0,
            startTime: args.startTime,
            length: args.length,
            date: DateTime(
                args.startTime.year, args.startTime.month, args.startTime.day),
            meditationId: args.meditationId,
            userId: globals.currentUser.userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    UserSitDetailsArgs args = ModalRoute.of(context).settings.arguments;

    getData(args);

    return Scaffold(
        appBar: AppBar(
            title: Text("Refuge Recovery",
                style: TextStyle(fontFamily: "Helvetica", color: Colors.black)),
            backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
        body: Center(
          child: ListView(shrinkWrap: true, children: <Widget>[
            Container(
                alignment: Alignment(-1.0, 0.0),
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                child: Text('Day',
                    style: TextStyle(
                        fontFamily: 'HelveticaNeue',
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0))),
            Visibility(
                visible: _isNew,
                child: Container(
                    height: 85.0,
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 60.0),
                    child: CupertinoDatePicker(
                        initialDateTime: DateTime.now(),
                        onDateTimeChanged: (DateTime newDate) {
                          _currentSit.date = DateTime(
                              newDate.year, newDate.month, newDate.day);
                          _currentSit.startTime = DateTime(
                              _currentSit.date.year,
                              _currentSit.date.month,
                              _currentSit.date.day,
                              _currentSit.startTime.hour,
                              _currentSit.startTime.minute,
                              _currentSit.startTime.second);
                        },
                        use24hFormat: false,
                        maximumDate: new DateTime(2100, 12, 31),
                        minimumYear: 2020,
                        maximumYear: 2100,
                        mode: CupertinoDatePickerMode.date))),
            Visibility(
                visible: !_isNew,
                child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                    child: Text(dayFormat.format(args.startTime),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'HelveticaNeue', fontSize: 28.0)))),
            Container(
                alignment: Alignment(-1.0, 0.0),
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                child: Text('Start Time',
                    style: TextStyle(
                        fontFamily: 'HelveticaNeue',
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0))),
            Visibility(
                visible: !_isNew,
                child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                    child: Text(timeFormat.format(args.startTime),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'HelveticaNeue', fontSize: 28.0)))),
            Visibility(
                visible: _isNew,
                child: Container(
                    height: 85.0,
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 60.0),
                    child: CupertinoDatePicker(
                        initialDateTime: DateTime.now(),
                        onDateTimeChanged: (DateTime newDate) {
                          _currentSit.startTime = DateTime(
                              _currentSit.date.year,
                              _currentSit.date.month,
                              _currentSit.date.day,
                              newDate.hour,
                              newDate.minute,
                              newDate.second);
                        },
                        use24hFormat: false,
                        maximumDate: new DateTime(2100, 12, 31),
                        minimumYear: 2020,
                        maximumYear: 2100,
                        mode: CupertinoDatePickerMode.time))),
            Container(
                alignment: Alignment(-1.0, 0.0),
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                child: Text('Duration',
                    style: TextStyle(
                        fontFamily: 'HelveticaNeue',
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0))),
            Container(
                height: 85.0,
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 60.0),
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  minuteInterval: 1,
                  secondInterval: 1,
                  initialTimerDuration: args.length,
                  onTimerDurationChanged: (Duration newLength) {
                    _currentSit.length = newLength;
                    _currentSit.endTime = _currentSit.startTime.add(newLength);
                  },
                )),
            Container(
                alignment: Alignment(-1.0, 0.0),
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                child: Text('Meditation',
                    style: TextStyle(
                        fontFamily: 'HelveticaNeue',
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0))),
            Visibility(
                visible: _isNew,
                child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
                    child: DropdownButton<String>(
                      onChanged: (String newValue) {
                        setState(() {
                          _currentSit.meditationId = newValue;
                        });
                      },
                      items: _meditations
                          .map<DropdownMenuItem<String>>((Meditation m) {
                        return DropdownMenuItem<String>(
                            child: Text(m.name, style: _textStyle),
                            value: m.meditationId.toUpperCase());
                      }).toList(),
                      value: _currentSit.meditationId,
                    ))),
            Visibility(
                visible: !_isNew,
                child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                    child: Text(args.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'HelveticaNeue', fontSize: 28.0)))),
            SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlatButton(
                    child: Text('Delete'),
                    color: Color.fromRGBO(165, 132, 41, 1),
                    onPressed: () async {
                      var doDelete = await showDialog(
                          context: context,
                          child: AlertDialog(
                              content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                Container(
                                    alignment: Alignment.center,
                                    padding: EdgeInsets.symmetric(
                                        vertical: 10.0, horizontal: 10.0),
                                    child: Text('Really delete?',
                                        style: TextStyle(
                                            fontFamily: 'HelveticaNeue',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0))),
                                Container(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                      new FlatButton(
                                          child: Text("Delete"),
                                          color:
                                              Color.fromRGBO(165, 132, 41, 1),
                                          onPressed: () async {
                                            Navigator.pop(context, true);
                                          }),
                                      new Container(
                                        width: 10.0,
                                      ),
                                      new FlatButton(
                                          child: Text("Cancel"),
                                          color:
                                              Color.fromRGBO(165, 132, 41, 1),
                                          onPressed: () async {
                                            Navigator.pop(context, false);
                                          }),
                                    ]))
                              ])));

                      if (doDelete != null && doDelete) {
                        http.delete(sitsUrl + '/' + args.sitId.toUpperCase(),
                            headers: {
                              "Ocp-Apim-Subscription-Key":
                                  "ccc40bb65a5d41808eaadcdeab79a3ba"
                            }).then((response) {
                          Navigator.pop(context);
                          Navigator.popAndPushNamed(
                              context, HomeScreen.routeNameHistory);
                        });
                      }
                    }),
                SizedBox(width: 10.0),
                FlatButton(
                    child: Text('Cancel'),
                    color: Color.fromRGBO(165, 132, 41, 1),
                    onPressed: () async {
                      Navigator.pop(context, false);
                    }),
                SizedBox(width: 10.0),
                FlatButton(
                    child: Text('Submit'),
                    color: Color.fromRGBO(165, 132, 41, 1),
                    onPressed: () {
                      print(_currentSit.startTime);
                      if (_isNew) {
                        postSit(_currentSit);
                      } else {
                        putSit(_currentSit);
                      }
                    })
              ],
            ),
            SizedBox(height: 5.0)
          ]),
        ));
  }
}
