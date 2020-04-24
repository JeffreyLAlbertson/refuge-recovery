import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:refugerecovery/locator.dart';
import 'package:refugerecovery/navigator/service.dart';
import 'package:refugerecovery/data/meeting.dart';
import 'package:refugerecovery/screens/meeting_detail.dart';
import 'package:refugerecovery/args/meetingdetails.dart';

class MeetingsDataSource extends DataTableSource {
  final NavigationService _navigationService = locator<NavigationService>();

  final List<Meeting> _meetings;
  MeetingsDataSource(this._meetings);

  int _selectedCount = 0;

  Map<int, String> day = {
    -1: 'All',
    0: 'Sun',
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat'
  };

  TextStyle cellStyle = TextStyle(fontFamily: 'HelveticaNeue', fontSize: 20.0);

  void sort<T>(Comparable<T> getField(Meeting m), bool ascending) {
    _meetings.sort((Meeting a, Meeting b) {
      if (!ascending) {
        final Meeting c = a;
        a = b;
        b = c;
      }
      final Comparable<T> aValue = getField(a);
      final Comparable<T> bValue = getField(b);
      return Comparable.compare(aValue, bValue);
    });
    notifyListeners();
  }

  void _tapCell(Meeting m) {
    _navigationService.navigateTo(MeetingDetailsScreen.routeName,
        arguments: MeetingDetailsArgs(
            m.id,
            m.name,
            m.slug,
            m.updated,
            m.locationId,
            m.url,
            m.day,
            m.time,
            m.endTime,
            m.timeFormatted,
            m.website,
            m.website2,
            m.phone,
            m.types,
            m.location,
            m.locationNotes,
            m.locationUrl,
            m.formattedAddress1,
            m.formattedAddress2,
            m.longitude,
            m.latitude,
            m.regionId,
            m.region,
            m.subRegion));
  }

  String _getSubRegion(Meeting m) {
    return m.subRegion != null
        ? m.subRegion
        : m.location.toString().indexOf('Online') != -1 ? 'Online' : '';
  }

  String _getLocation(Meeting m) {
    return m.location != null ? m.location : '';
  }

  @override
  DataRow getRow(int index) {
    if (index >= _meetings.length) return null;

    final Meeting m = _meetings[index];

    return DataRow.byIndex(index: index, cells: <DataCell>[
      DataCell(Text(day[m.day], style: cellStyle), onTap: () {
        _tapCell(m);
      }),
      DataCell(Text(m.timeFormatted, style: cellStyle), onTap: () {
        _tapCell(m);
      }),
      DataCell(Text(_getSubRegion(m), style: cellStyle), onTap: () {
        _tapCell(m);
      }),
      DataCell(
          Text(
            _getLocation(m),
            style: cellStyle,
          ), onTap: () {
        _tapCell(m);
      }),
      DataCell(Text(m.formattedAddress1, style: cellStyle), onTap: () {
        _tapCell(m);
      }),
      DataCell(Text(m.name, style: cellStyle), onTap: () {
        _tapCell(m);
      }),
    ]);
  }

  @override
  int get rowCount => _meetings.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;
}
