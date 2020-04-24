class Meditation {
  final String meditationId;
  final String name;
  final Duration length;
  final String fileName;
  final String logoFileName;
  final String language;

  Meditation(
      {this.meditationId,
      this.name,
      this.length,
      this.fileName,
      this.logoFileName,
      this.language});

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
        meditationId: json['meditationId'],
        name: json['name'],
        length: Duration(milliseconds: json['length']['totalMilliseconds']),
        fileName: json['filename'],
        logoFileName: json['logoFilename'],
        language: json['language']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['meditationId'] = this.meditationId;
    data['name'] = this.name;
    data['length'] = this.length;
    data['fileName'] = this.fileName;
    data['logoFileName'] = this.logoFileName;
    data['language'] = this.language;
    return data;
  }
}
