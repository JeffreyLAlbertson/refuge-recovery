import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:refugerecovery/data/meeting.dart';
import 'package:refugerecovery/data/meetingsdatasource.dart';

Future<List<Meeting>> fetchResults(http.Client client) async {
  final response = await client.get(
      'https://refugerecovery.org/wp-admin/admin-ajax.php?action=meetings');
  return compute(parseResults, response.body);
}

// A function that will convert a response body into a List<Result>
List<Meeting> parseResults(String responseBody) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Meeting>((json) => Meeting.fromJson(json)).toList();
}

class MeetingsScreen extends StatefulWidget {
  @override
  _MeetingsScreenState createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  MeetingsDataSource _meetingsDataSource = MeetingsDataSource([]);

  bool isLoaded = false;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _sortColumnIndex;
  bool _sortAscending = true;

  List<Meeting> results;
  List<DropdownMenuItem<String>> states = <DropdownMenuItem<String>>[];

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
  int dayFilter = -1;
  String stateFilter = '';
  String subRegionFilter = '';

  TextEditingController nameController = new TextEditingController();
  TextEditingController subRegionController = new TextEditingController();

  TextStyle headerStyle = const TextStyle(
      fontFamily: 'HelveticaNeue', fontSize: 24.0, fontWeight: FontWeight.bold);

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    subRegionController.addListener(subRegionListener);
  }

  subRegionListener() {
    subRegionFilter = subRegionController.text;
    _filter();
  }

  regionChange(region) {
    subRegionFilter = region;
    _filter();
  }

  void _filter() {
    List<Meeting> filtered = results;
    filtered = filtered
        .where((m) => dayFilter >= 0 ? m.day == dayFilter : true)
        .toList();
    filtered = filtered
        .where((m) => stateFilter != '' ? m.region == stateFilter : true)
        .toList();
    filtered = filtered
        .where((m) => subRegionFilter != ''
            ? m.subRegion
                    .toString()
                    .toLowerCase()
                    .indexOf(subRegionFilter.toLowerCase()) !=
                -1
            : true)
        .toList();
    _meetingsDataSource = MeetingsDataSource(filtered);
  }

  void _sort<T>(
      Comparable<T> getField(Meeting m), int columnIndex, bool ascending) {
    _meetingsDataSource.sort<T>(getField, ascending);

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  Future<void> getData() async {
    results = await fetchResults(http.Client());

    if (!isLoaded) {
      setState(() {
        _meetingsDataSource = MeetingsDataSource(results);
        results
            .map<String>((Meeting m) {
              return m.region.toString();
            })
            .toSet()
            .toList()
            .forEach((String s) {
              states.add(new DropdownMenuItem<String>(
                  value: s,
                  child: Text(s,
                      style: TextStyle(
                          fontFamily: 'HelveticaNeue',
                          fontWeight: FontWeight.bold))));
            });
        states.sort((a, b) => a.value.compareTo(b.value));
        states.insert(
            0, new DropdownMenuItem<String>(value: '', child: Text('All')));
        isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    getData();

    return Center(
        child: ListView(padding: const EdgeInsets.all(10.0), children: <Widget>[
      Row(children: <Widget>[
        Container(
            margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
            child: Text('Day',
                style: TextStyle(
                    fontFamily: 'HelveticaNeue', fontWeight: FontWeight.bold))),
        DropdownButton<int>(
            value: dayFilter,
            onChanged: (int newValue) {
              setState(() {
                dayFilter = newValue;
                _filter();
              });
            },
            items: <int>[-1, 0, 1, 2, 3, 4, 5, 6]
                .map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(day[value],
                    style: TextStyle(
                        fontFamily: 'HelveticaNeue',
                        fontWeight: FontWeight.bold)),
              );
            }).toList()),
        Container(
            margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
            child: Text('Region',
                style: TextStyle(
                    fontFamily: 'HelveticaNeue', fontWeight: FontWeight.bold))),
        DropdownButton<String>(
            value: stateFilter,
            onChanged: (String newValue) {
              setState(() {
                stateFilter = newValue;
                _filter();
              });
            },
            items: states)
      ]),
      Row(children: <Widget>[
        Container(
            margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
            child: Text('Place',
                style: TextStyle(
                    fontFamily: 'HelveticaNeue', fontWeight: FontWeight.bold))),
        Expanded(
            child: Container(
                margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
                child: TextField(
                  onChanged: (newValue) {
                    setState(() {
                      subRegionFilter = newValue;
                      _filter();
                    });
                  },
                  controller: subRegionController,
                )
            )
        )
      ]),
      PaginatedDataTable(
          header: Text(''),
          rowsPerPage: _rowsPerPage,
          onRowsPerPageChanged: (int value) {
            setState(() {
              _rowsPerPage = value;
            });
          },
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          columns: <DataColumn>[
            DataColumn(
                label: Text('Day', style: headerStyle),
                onSort: (int columnIndex, bool ascending) => _sort<String>(
                    (Meeting m) => m.day.toString(), columnIndex, ascending)),
            DataColumn(
                label: Text('Time', style: headerStyle),
                onSort: (int columnIndex, bool ascending) => _sort<String>(
                    (Meeting m) => m.time, columnIndex, ascending)),
            DataColumn(
                label: Text('Place', style: headerStyle),
                onSort: (int columnIndex, bool ascending) => _sort<String>(
                    (Meeting m) => m.subRegion != null ? m.subRegion : '',
                    columnIndex,
                    ascending)),
            DataColumn(
                label: Text(
                  'Venue',
                  style: headerStyle,
                ),
                onSort: (int columnIndex, bool ascending) => _sort<String>(
                    (Meeting m) => m.location != null ? m.location : '',
                    columnIndex,
                    ascending)),
            DataColumn(
                label: Text('Address', style: headerStyle),
                onSort: (int columnIndex, bool ascending) => _sort<String>(
                    (Meeting m) => m.formattedAddress1,
                    columnIndex,
                    ascending)),
            DataColumn(
                label: Text('Name', style: headerStyle),
                onSort: (int columnIndex, bool ascending) => _sort<String>(
                    (Meeting m) => m.name, columnIndex, ascending)),
          ],
          source: _meetingsDataSource)
    ]));
  }
}
