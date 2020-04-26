import 'package:flutter/material.dart';
import 'package:refugerecovery/locator.dart';
import 'package:refugerecovery/navigator/service.dart';
import 'package:refugerecovery/screens/home.dart';
import 'package:refugerecovery/screens/meeting_detail.dart';
import 'package:refugerecovery/screens/user_sit_detail.dart';
import 'package:refugerecovery/screens/user_sits.dart';

import 'locator.dart';
import 'screens/sign_in/sign_in.dart';

void main() {
  setupLocator();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RefugeRecovery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignInScreen(),
      navigatorKey: locator<NavigationService>().navigatorKey,
      routes: {
        MeetingDetailsScreen.routeName: (context) => MeetingDetailsScreen(),
        UserSitsScreen.routeName: (context) => UserSitsScreen(),
        UserSitDetailsScreen.routeName: (context) => UserSitDetailsScreen(),
        HomeScreen.routeName: (context) => HomeScreen(0),
        HomeScreen.routeNameHistory: (context) => HomeScreen(3)
      },
    );
  }
}
