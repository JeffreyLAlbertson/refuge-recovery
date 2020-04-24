class Stats {
  final Duration averageLength;
  final int daysWithOneSession;
  final DateTime firstSitDate;
  final SitRun currentRun;
  final List<SitRun> sitRuns;

  Stats({this.averageLength, this.daysWithOneSession, this.firstSitDate, this.currentRun, this.sitRuns});

  factory Stats.fromJson(Map<String, dynamic> json) {

    List<SitRun> srs = <SitRun>[];
    (json['sitRuns'] as List<dynamic>).forEach((sr) {
      srs.add(SitRun(
        length: sr['length'],
        startDate: DateTime.parse(sr['startDate']),
        endDate: DateTime.parse(sr['endDate'])
      ));
    });

    return Stats(
        averageLength: Duration(milliseconds: json['averageLength']['totalMilliseconds'].round()),
        daysWithOneSession: json['daysWithOneSession'] as int,
        firstSitDate: DateTime.parse(json['firstSessionDate']),
        currentRun: SitRun.fromJson(json['currentRun']),
        sitRuns: srs);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['averageLength'] = this.averageLength;
    data["daysWithOneSession"] = this.daysWithOneSession;
    data['firstSessionDate'] = this.firstSitDate;
    data["currentRun"] = this.currentRun;
    data["sitRuns"] = this.sitRuns;
    return data;
  }
}

class SitRun {
  final int length;
  final DateTime startDate;
  final DateTime endDate;

  SitRun({this.length, this.startDate, this.endDate});

  factory SitRun.fromJson(Map<String, dynamic> json) {
    return SitRun(
        length: json['length'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate'])
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['length'] = this.length;
    data["startDate"] = this.startDate.toString();
    data["endDate"] = this.endDate.toString();
    return data;
  }
}