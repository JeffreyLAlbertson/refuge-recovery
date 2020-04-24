import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:refugerecovery/args/meetingdetails.dart';

class MeetingDetailsScreen extends StatefulWidget {
  static const routeName = '/meeting_detail';

  @override
  _MeetingDetailsScreenState createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  Map<int, String> day = {
    0: 'Sunday',
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday'
  };

  Map<String, String> type = {
    'EN': "English",
    'O': 'Open',
    'WA': 'Wheelchair Accessible',
    'BB': 'Book Study',
    'M': 'Men Only',
    'C': 'Closed',
    'W': 'Women Only'
  };

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Column _getIconColumn(url) {
    String linkText = '';
    String imageFile = '';

    if (url.toString().toLowerCase().indexOf('facebook') != -1) {
      linkText = 'Facebook Page';
      imageFile = 'facebook.png';
    } else if (url.toString().toLowerCase().indexOf('refugerecovery.org') !=
        -1) {
      linkText = 'Refuge Recovery';
      imageFile = 'rr_logo.png';
    } else {
      linkText = 'Web Site';
      imageFile = 'www.jpg';
    }

    return Column(children: <Widget>[
      FlatButton(
          child: Image(
              image: AssetImage('assets/$imageFile'),
              width: 75.0,
              height: 75.0),
          onPressed: () {
            _launchURL(url);
          }),
      Text(
        linkText,
        style: TextStyle(fontFamily: 'HelveticaNeue', fontSize: 16.0),
      )
    ]);
  }

  String _getTwelveHourTime(String time) {
    String twelveHourTime = '';
    String hour = time.substring(0, time.indexOf(':'));
    String minutes = time.substring(time.indexOf(':') + 1, time.length);
    int hourInt = int.parse(hour);
    if (hourInt > 12) {
      hourInt -= 12;
    }
    twelveHourTime = hourInt.toString();
    return twelveHourTime + ':' + minutes;
  }

  String _getAmPm(String time) {
    String hour = time.substring(0, time.indexOf(':'));
    int hourInt = int.parse(hour);
    return (hourInt < 12) ? 'a.m.' : 'p.m.';
  }

  List<Row> _getTypes(List<dynamic> types) {
    List<Row> _types = <Row>[];
    if (types != null) {
      types.forEach((t) {
        _types.add(Row(children: [
          SizedBox(width: 5.0),
          Icon(Icons.check, size: 16.0),
          SizedBox(width: 2.5),
          Text(type[t.toString()], style: _typeStyle)
        ]));
      });
    }
    return _types;
  }

  String _getMainImagePath(MeetingDetailsArgs m) {
    String mainImagePath = 'assets/google_maps.png';
    if ((m.website != null && m.website.indexOf('zoom.us') != -1) ||
        (m.website2 != null && m.website2.indexOf('zoom.us') != -1)) {
      mainImagePath = 'assets/zoom.jpg';
    }
    return mainImagePath;
  }

  String _getMainImageUrl(MeetingDetailsArgs m) {
    String mainImageUrl = '';
    if (m.website != null && m.website.indexOf('zoom.us') != -1) {
      mainImageUrl = m.website;
    } else if (m.website2 != null && m.website2.indexOf('zoom.us') != -1) {
      mainImageUrl = m.website2;
    } else {
      mainImageUrl =
          "https://www.google.com/maps?daddr=${m.longitude},${m.latitude}saddr=Current+Location&q=${m.location}";
    }
    return mainImageUrl;
  }

  String _getMainImageText(MeetingDetailsArgs m) {
    String mainImageText = 'Map and Directions';
    if ((m.website != null && m.website.indexOf('zoom.us') != -1) ||
        (m.website2 != null && m.website2.indexOf('zoom.us') != -1)) {
      mainImageText = 'Go to Meeting';
    }
    return mainImageText;
  }

  TextStyle _textStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0);
  TextStyle _notesStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 16.0);
  TextStyle _typeStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 18.0);
  TextStyle _headerStyle =
      const TextStyle(fontFamily: 'HelveticaNeue', fontSize: 28.0);

  @override
  Widget build(BuildContext context) {
    final MeetingDetailsArgs args = ModalRoute.of(context).settings.arguments;

    return Scaffold(
        appBar: AppBar(
            title: Text("Refuge Recovery",
                style: TextStyle(fontFamily: "Helvetica", color: Colors.black)),
            backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
        body: Center(
          child:
              ListView(padding: const EdgeInsets.all(15.0), children: <Widget>[
            Text(args.name, style: _headerStyle, textAlign: TextAlign.center),
            Container(
                padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(day[args.day],
                        style: _textStyle, textAlign: TextAlign.left),
                    Text(
                        _getTwelveHourTime(args.time) +
                            ' ' +
                            _getAmPm(args.time) +
                            ' to ' +
                            _getTwelveHourTime(args.endTime) +
                            ' ' +
                            _getAmPm(args.endTime),
                        style: _textStyle,
                        textAlign: TextAlign.left),
                  ],
                )),
            Container(
                padding: EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(args.location != null ? args.location : '',
                          style: _textStyle),
                      Text(
                          args.formattedAddress1 != null
                              ? args.formattedAddress1
                              : '',
                          style: _textStyle),
                      Text(
                          args.formattedAddress2 != null
                              ? args.formattedAddress2
                              : '',
                          style: _textStyle),
                      Visibility(
                          visible: args.locationNotes != null,
                          child: Text(
                              args.locationNotes != null
                                  ? args.locationNotes
                                  : '',
                              style: _notesStyle)),
                    ])),
            Visibility(
                visible: args.types != null,
                child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
                    child: Column(children: _getTypes(args.types)))),
            Container(
                child: Column(
                  children: <Widget>[
                    FlatButton(
                      child: Image(
                          image: AssetImage(_getMainImagePath(args)),
                          width: 75.0,
                          height: 75.0),
                      onPressed: () {
                        _launchURL(_getMainImageUrl(args));
                      },
                    ),
                    Text(
                      _getMainImageText(args),
                      style: TextStyle(
                          fontFamily: 'HelveticaNeue', fontSize: 16.0),
                    )
                  ],
                ),
                width: 100.0,
                height: 100.0),
            Row(children: <Widget>[
              Visibility(
                  visible: args.website != null &&
                      args.website.indexOf('zoom.us') == -1,
                  child: _getIconColumn(args.website)),
              Visibility(
                  visible: (args.website != null && args.website2 != null) &&
                      (args.website.indexOf('zoom.us') == -1 &&
                          args.website2.indexOf('zoom.us') == -1),
                  child: SizedBox(
                    width: 10.0,
                  )),
              Visibility(
                  visible: args.website2 != null &&
                      args.website2.indexOf('zoom.us') == -1,
                  child: _getIconColumn(args.website2)),
            ], mainAxisAlignment: MainAxisAlignment.center),
          ]),
        ));
  }
}
