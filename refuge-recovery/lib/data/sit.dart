class Sit {
  final String sitId;
  int seq;
  DateTime startTime;
  DateTime endTime;
  Duration length;
  DateTime date;
  String meditationId;
  final String userId;

  Sit(
      {this.sitId,
      this.seq,
      this.startTime,
      this.endTime,
      this.length,
      this.date,
      this.meditationId,
      this.userId});

  factory Sit.fromJson(dynamic json) {
    return Sit(
        sitId: json['sitId'].toString().toUpperCase(),
        seq: int.parse(json['seq']),
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        length: Duration(milliseconds: json['length']['totalMilliseconds']),
        date: DateTime.parse(json['date']),
        meditationId: json['meditationId'].toString().toUpperCase() ,
        userId: json['userId']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sitId'] = this.sitId;
    data['seq'] = this.seq.toString();
    data['startTime'] = this.startTime.toString();
    data['endTime'] = this.endTime == null ? null : this.endTime.toString();
    data['length'] = this.length.toString();
    data['date'] = this.date.toString();
    data['meditationId'] = this.meditationId;
    data['userId'] = this.userId;
    return data;
  }
}
