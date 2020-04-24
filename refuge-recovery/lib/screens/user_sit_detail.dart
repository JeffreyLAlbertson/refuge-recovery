import 'dart:ui';

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/meditation.dart';
import 'package:intl/intl.dart';
import 'package:refugerecovery/data/sit.dart';
import 'package:refugerecovery/args/usersitdetails.dart';
import 'package:refugerecovery/screens/home.dart';
import 'package:refugerecovery/globals.dart' as globals;

import 'package:refugerecovery/locator.dart';

class UserSitDetailsScreen extends StatefulWidget {
  static const routeName = '/user_sit_detail';

  @override
  _UserSitDetailsScreenState createState() => _UserSitDetailsScreenState();
}

Future<List<Meditation>> fetchMeditations(http.Client client) async {
  final response = await client
      .get('https://refugerecoverydata.azurewebsites.net/api/meditations');
  return compute(parseMeditations, response.body);
}

List<Meditation> parseMeditations(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Meditation>((json) => Meditation.fromJson(json)).toList();
}

class _UserSitDetailsScreenState extends State<UserSitDetailsScreen> {
  var _meditations = <Meditation>[];
  UserSitDetailsArgs arguments = locator.get<UserSitDetailsArgs>();
  List<DropdownMenuItem<String>> meditations =
      <DropdownMenuItem<String>>[];

  final String sitsUrl =
      'https://refugerecoverydata.azurewebsites.net/api/sits';

  final DateFormat dayFormat = new DateFormat("MMMM d, yyyy");
  final DateFormat timeFormat = new DateFormat("h:mm:ss aa");

  String formatDuration(Duration d) {
    String s = (new Duration(seconds: d.inSeconds)).toString();
    s = s.substring(0, s.indexOf('.'));
    return s;
  }

  TextStyle _textStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0);
  TextStyle _notesStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 16.0);
  TextStyle _typeStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 18.0);
  TextStyle _headerStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 28.0);

  void putSit(Sit currentSit) {
    http
        .put(sitsUrl + '/' + currentSit.sitId,
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded"
            },
            body: currentSit.toJson())
        .then((response) {
      Navigator.pop(context);
      Navigator.popAndPushNamed(context, HomeScreen.routeNameHistory);
    });
  }

  void postSit(Sit currentSit) {
    http
        .post(sitsUrl,
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/x-www-form-urlencoded"
            },
            body: currentSit.toJson())
        .then((response) {
      Navigator.pop(context);
      Navigator.popAndPushNamed(context, HomeScreen.routeNameHistory);
    });
  }

  bool _isLoaded = false;
  bool _isNew = false;
  Sit _currentSit;
   _UserSitDetailsScreenState ()
   {
     getData().then((List<Meditation> ms) {
       
     });

   }

  Future<List<Meditation>> getData() async {

     return await fetchMeditations(http.Client());
      _meditations = await fetchMeditations(http.Client());
      _meditations.add(Meditation(
          meditationId: '00000000-0000-0000-0000-000000000000',
          name: '',
          length: Duration.zero,
          logoFileName:'',
          language: ''));

      /*
      setState(() {
        _meditations.toList().forEach((Meditation m) {
          meditations.add(new DropdownMenuItem<String>(
              value: m.meditationId,
              child: Text(m.name,
                  style: TextStyle(
                      fontFamily: 'HelveticaNeue',
                      fontWeight: FontWeight.bold))));
        });
        meditations.add(new DropdownMenuItem(value: '00000000-0000-0000-0000-000000000000', child: Text('')));
      });

       */
      _isLoaded = true;


    }
  }





  @override
  Widget build(BuildContext context) {
    //final UserSitDetailsArgs args = ModalRoute.of(context).settings.arguments;



    //getData();

    return Scaffold(
        appBar: AppBar(
            title: Text("Refuge Recovery",
                style: TextStyle(fontFamily: "Helvetica", color: Colors.black)),
            backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
        body: Center(
          child: Column(children: <Widget>[
            Expanded(
                child: Container(
                    alignment: Alignment(-1.0, 0.0),
                    padding:
                        EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
                    child: Text('Day',
                        style: TextStyle(
                            fontFamily: 'HelveticaNeue',
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0)))),
            Visibility(
                visible: _isNew,
                child: Expanded(
                    child: CupertinoDatePicker(
                        initialDateTime: DateTime.now(),
                        onDateTimeChanged: (DateTime newDate) {
                          _currentSit.date = DateTime(
                              newDate.year, newDate.month, newDate.day);
                        },
                        use24hFormat: false,
                        maximumDate: new DateTime(2100, 12, 31),
                        minimumYear: 2020,
                        maximumYear: 2100,
                        mode: CupertinoDatePickerMode.date))),
            Visibility(
                visible: !_isNew,
                child: Expanded(
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 5.0),
                        child: Text(dayFormat.format(arguments.startTime),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'HelveticaNeue',
                                fontSize: 28.0))))),
            Expanded(
                child: Container(
                    alignment: Alignment(-1.0, 0.0),
                    padding:
                        EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
                    child: Text('Start Time',
                        style: TextStyle(
                            fontFamily: 'HelveticaNeue',
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0)))),
            Visibility(
                visible: !_isNew,
                child: Expanded(
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 5.0),
                        child: Text(timeFormat.format(arguments.startTime),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'HelveticaNeue',
                                fontSize: 28.0))))),
            Visibility(
                visible: _isNew,
                child: Expanded(
                    child: CupertinoDatePicker(
                        initialDateTime: DateTime.now(),
                        onDateTimeChanged: (DateTime newDate) {
                          _currentSit.startTime = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                              newDate.hour,
                              newDate.minute,
                              newDate.second);
                        },
                        use24hFormat: false,
                        maximumDate: new DateTime(2100, 12, 31),
                        minimumYear: 2020,
                        maximumYear: 2100,
                        mode: CupertinoDatePickerMode.time))),
            Expanded(
                child: Container(
                    alignment: Alignment(-1.0, 0.0),
                    padding:
                        EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
                    child: Text('Duration',
                        style: TextStyle(
                            fontFamily: 'HelveticaNeue',
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0)))),
            Expanded(
                child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 2.5, horizontal: 60.0),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      minuteInterval: 1,
                      secondInterval: 1,
                      initialTimerDuration: arguments.length,
                      onTimerDurationChanged: (Duration newLength) {
                        _currentSit.length = newLength;
                        _currentSit.endTime =
                            _currentSit.startTime.add(newLength);
                      },
                    ))),
            Expanded(
                child: Container(
                    alignment: Alignment(-1.0, 0.0),
                    padding:
                        EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
                    child: Text('Meditation',
                        style: TextStyle(
                            fontFamily: 'HelveticaNeue',
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0)))),
            Visibility(
                visible: _isNew,
                child: Expanded(
                    child: DropdownButton<String>(
                  onChanged: (String newValue) {
                    setState(() {
                      print(_currentSit.meditationId);
                      print(newValue);
                      _currentSit.meditationId = newValue;
                      print(_currentSit.meditationId);
                    });
                  },
                  items: _meditations.map((m) =>
                      DropdownMenuItem(
                        child: Text(m.name),
                        value: m.meditationId,
                      )
                  ).toList(),
                  value: _currentSit.meditationId,
                ))),
            Visibility(
                visible: !_isNew,
                child: Expanded(
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 5.0),
                        child: Text(arguments.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'HelveticaNeue',
                                fontSize: 28.0))))),
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
                              content: Container(
                                  child: Column(children: <Widget>[
                            Expanded(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                  new FlatButton(
                                      child: Text("Delete"),
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
                                ]))
                          ]))));

                      if (doDelete != null && doDelete) {
                        http
                            .delete(sitsUrl + '/' + arguments.sitId)
                            .then((response) {
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
                    onPressed: () async {
                      if (_isNew) {
                        postSit(_currentSit);
                      } else {
                        putSit(_currentSit);
                      }
                    })
              ],
            ),
            SizedBox(height: 10.0)
          ]),
        ));
  }
}
