class UserSit {
  final String sitId;
  final String meditationId;
  final String name;
  final DateTime date;
  final Duration length;

  UserSit(
      {this.sitId,
        this.meditationId,
        this.name,
        this.date,
        this.length});

  factory UserSit.fromJson(dynamic json) {
    return UserSit(
        sitId: json['sitId'].toString().toUpperCase(),
        meditationId: json['meditationId'].toString().toUpperCase(),
        name: json['name'],
        date: DateTime.parse(json['date']),
        length: Duration(milliseconds: json['length']['totalMilliseconds']));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sitId'] = this.sitId;
    data['meditationId'] = this.meditationId;
    data['name'] = this.name;
    data['date'] = this.date;
    data['length'] = this.length;
    return data;
  }
}