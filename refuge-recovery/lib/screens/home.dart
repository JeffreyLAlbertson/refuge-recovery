import 'package:flutter/material.dart';
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
    _pageIndex = widget.page;
    super.initState();
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
                  fontFamily: "Helvetica", color: Color.fromRGBO(0, 0, 0, 1))),
          backgroundColor: Color.fromRGBO(165, 132, 41, 1)),
      body: _children[_pageIndex],
      bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _pageIndex,
          selectedItemColor: Color.fromRGBO(165, 132, 41, 1),
          unselectedItemColor: Colors.grey,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.home), title: Text('Home')),
            BottomNavigationBarItem(
                icon: Icon(Icons.video_library), title: Text('Videos')),
            BottomNavigationBarItem(
                icon: Icon(Icons.people), title: Text('Meetings')),
            BottomNavigationBarItem(
                icon: Icon(Icons.audiotrack), title: Text('Meditations')),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), title: Text('History')),
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
