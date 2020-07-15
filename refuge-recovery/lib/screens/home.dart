import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refugerecovery/globals.dart' as globals;
import 'package:refugerecovery/screens/meditations.dart';
import 'package:refugerecovery/screens/meetings.dart';
import 'package:refugerecovery/screens/start.dart';
import 'package:refugerecovery/screens/stats.dart';
import 'package:refugerecovery/screens/user_sits.dart';
import 'package:refugerecovery/screens/videos.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  static const routeNameHistory = '/home/history';

  final int page;
  HomeScreen(this.page);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pageIndex;

  @override
  void initState() {
    getAppDocsDirectory();

    _pageIndex = widget.page;

    super.initState();
  }

  void getAppDocsDirectory() async {
    globals.appDocsDirectory = await getApplicationDocumentsDirectory();
  }

  final List<Widget> _children = [
    StartScreen(),
    VideosScreen(),
    MeetingsScreen(),
    MeditationsScreen(),
    UserSitsScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Refuge Recovery",
              style: TextStyle(
                  fontFamily: "Metropolis",
                  backgroundColor: Color.fromRGBO(165, 132, 41, 1),
                  color: Color.fromRGBO(35, 40, 35, 1),
                  fontWeight: FontWeight.bold)),
          backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
      backgroundColor: Color.fromRGBO(238, 236, 230, 1),
      body: _children[_pageIndex],
      bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _pageIndex,
          backgroundColor: Color.fromRGBO(238, 236, 230, 1),
          selectedItemColor: Color.fromRGBO(165, 132, 41, 1),
          unselectedItemColor: Color.fromRGBO(35, 40, 35, 1),
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
                icon: Icon(Icons.menu), title: Text('Stats')),
          ]),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      debugPrint(index.toString());
      _pageIndex = index;
    });
  }
}
