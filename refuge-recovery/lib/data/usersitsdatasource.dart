import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:refugerecovery/args/usersitdetails.dart';
import 'package:refugerecovery/data/user_sit.dart';
import 'package:refugerecovery/locator.dart';
import 'package:refugerecovery/navigator/service.dart';
import 'package:refugerecovery/screens/user_sit_detail.dart';

class UserSitsDataSource extends DataTableSource {
  final NavigationService _navigationService = locator<NavigationService>();

  final List<UserSit> _userSits;
  UserSitsDataSource(this._userSits);

  int _selectedCount = 0;

  TextStyle cellStyle = TextStyle(fontFamily: 'Metropolis', fontSize: 18.0);
  final DateFormat dayFormat = new DateFormat("MMM d, yyyy");

  void _tapCell(UserSit us) {
    var arguments = UserSitDetailsArgs(
        us.sitId, us.meditationId, us.name, us.date, us.length);
    _navigationService.navigateTo(UserSitDetailsScreen.routeName,
        arguments: arguments);
  }

  String formatDuration(Duration d) {
    String s = (new Duration(seconds: d.inSeconds)).toString();
    s = s.substring(0, s.indexOf('.'));
    return s;
  }

  @override
  DataRow getRow(int index) {
    if (index >= _userSits.length) return null;

    final UserSit us = _userSits[index];

    return DataRow.byIndex(index: index, cells: <DataCell>[
      DataCell(Text(dayFormat.format(us.date), style: cellStyle), onTap: () {
        _tapCell(us);
      }),
      DataCell(Text(formatDuration(us.length), style: cellStyle), onTap: () {
        _tapCell(us);
      }),
      DataCell(Text(us.name, style: cellStyle), onTap: () {
        _tapCell(us);
      }),
    ]);
  }

  @override
  int get rowCount => _userSits.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;
}
