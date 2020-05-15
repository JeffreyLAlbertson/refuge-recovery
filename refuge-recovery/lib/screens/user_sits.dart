import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/args/usersitdetails.dart';
import 'package:refugerecovery/data/user_sit.dart';
import 'package:refugerecovery/data/usersitsdatasource.dart';
import 'package:refugerecovery/globals.dart' as globals;
import 'package:refugerecovery/locator.dart';
import 'package:refugerecovery/navigator/service.dart';
import 'package:refugerecovery/screens/user_sit_detail.dart';

Future<List<UserSit>> fetchResults(http.Client client, String userId) async {
  final response = await client.get(
      'https://refugerecoverydata.azure-api.net/api/sits/history/' +
          userId.toUpperCase(),
      headers: {
        "Ocp-Apim-Subscription-Key": "ccc40bb65a5d41808eaadcdeab79a3ba"
      });

  return compute(parseResults, response.body);
}

List<UserSit> parseResults(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<UserSit>((json) => UserSit.fromJson(json)).toList();
}

class UserSitsScreen extends StatefulWidget {
  static const routeName = '/user_sits';

  @override
  _UserSitsScreenState createState() => _UserSitsScreenState();
}

class _UserSitsScreenState extends State<UserSitsScreen> {
  final NavigationService _navigationService = locator<NavigationService>();

  UserSitsDataSource _userSitsDataSource = UserSitsDataSource([]);

  bool isLoaded = false;

  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  List<UserSit> results;

  TextStyle headerStyle = const TextStyle(
      fontFamily: 'HelveticaNeue', fontSize: 20.0, fontWeight: FontWeight.bold);

  Future<void> getData() async {
    results = await fetchResults(http.Client(), globals.currentUser.userId);
    if (!isLoaded) {
      setState(() {
        _userSitsDataSource = UserSitsDataSource(results);
        isLoaded = true;
      });
    }
  }

  void addSit(BuildContext context) {
    var arguments = UserSitDetailsArgs(
        '00000000-0000-0000-0000-000000000000',
        'df38a4ab-614b-485f-b572-25e164a8e078'
            .toUpperCase(), // default to silent meditation
        '',
        DateTime.now(),
        Duration.zero);

    _navigationService.navigateTo(UserSitDetailsScreen.routeName,
        arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    getData();
    return Center(
        child: ListView(padding: const EdgeInsets.all(10.0), children: <Widget>[
      Container(
        alignment: Alignment.center,
        width: 75.0,
        height: 50.0,
        child: FlatButton(
          color: Color.fromRGBO(165, 132, 41, 1),
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
          onPressed: () {
            addSit(context);
          },
          child: Text('Add'),
        ),
      ),
      Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PaginatedDataTable(
                header: Text(''),
                rowsPerPage: _rowsPerPage,
                onRowsPerPageChanged: (int value) {
                  setState(() {
                    _rowsPerPage = value;
                  });
                },
                columns: <DataColumn>[
                  DataColumn(label: Text('Day', style: headerStyle)),
                  DataColumn(label: Text('Length', style: headerStyle)),
                  DataColumn(label: Text('Meditation', style: headerStyle)),
                ],
                source: _userSitsDataSource)
          ]),
    ]));
  }
}
