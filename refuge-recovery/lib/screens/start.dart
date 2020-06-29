import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webfeed/webfeed.dart';

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

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    fetchFeed(http.Client());

    return Container(
        padding: EdgeInsets.all(25.0),
        child: ListView(children: <Widget>[
          Text(
            feedTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Metropolis',
                color: Color.fromRGBO(35, 40, 45, 1),
                fontSize: 24.0,
                fontWeight: FontWeight.bold),
          ),
          Html(
            data: feedHtml,
            onLinkTap: (url) {
              _launchURL(url);
            },
            customTextAlign: (_) => TextAlign.justify,
            useRichText: true,
            defaultTextStyle: TextStyle(
              fontFamily: 'Metropolis',
              fontSize: 16.0,
              height: 1.2,
              color: Color.fromRGBO(35, 40, 45, 1),
            ),
          )
        ]));
  }
}
