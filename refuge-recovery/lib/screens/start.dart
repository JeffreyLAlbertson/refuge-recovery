import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:flutter_html/flutter_html.dart';

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String feedHtml = '';
  String feedXml = '';
  String feedTitle = '';

  Future<void> fetchFeed(http.Client client) async {
    final response = await client.get('https://refugerecovery.org/feed');
    if (this.mounted) {
      setState(() {
        feedXml = response.body;
        var rssFeed = new RssFeed.parse(feedXml);
        RssItem item = rssFeed.items.first;
        feedHtml = item.content.value;
        feedTitle = item.title;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    fetchFeed(http.Client());

    return Container(
        padding: EdgeInsets.all(10.0),
        child: ListView(children: <Widget>[
          Text(
            feedTitle,
            style: TextStyle(
                fontFamily: 'HelveticaNeue',
                fontSize: 24.0,
                fontWeight: FontWeight.bold),
          ),
          Html(
              data: feedHtml,
              defaultTextStyle:
                  TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0))
        ]));
  }
}
