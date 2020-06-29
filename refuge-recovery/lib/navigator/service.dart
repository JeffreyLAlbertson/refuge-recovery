import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey =
      new GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToRoute(MaterialPageRoute route) {
    return navigatorKey.currentState.push(route);
  }

  void goBack() {
    return navigatorKey.currentState.pop();
  }
}
