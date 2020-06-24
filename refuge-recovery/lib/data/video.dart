class Video {
  final String videoId;
  final String name;
  final Duration length;
  final String fileName;
  final bool isLocal;
  final String logoFileName;
  final String title;
  final String description;
  final DateTime date;
  final String language;

  Video(
      {this.videoId,
      this.name,
      this.length,
      this.fileName,
      this.isLocal,
      this.logoFileName,
      this.title,
      this.description,
      this.date,
      this.language});

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
        videoId: json['meditationId'],
        name: json['name'],
        length: Duration(milliseconds: json['length']['totalMilliseconds']),
        fileName: json['filename'],
        isLocal: json['isLocal'],
        logoFileName: json['logoFilename'],
        title: json['title'],
        description: json['description'],
        date: DateTime.parse(json['date']),
        language: json['language']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['meditationId'] = this.videoId;
    data['name'] = this.name;
    data['length'] = this.length;
    data['fileName'] = this.fileName;
    data['isLocal'] = this.isLocal;
    data['logoFileName'] = this.logoFileName;
    data['title'] = this.title;
    data['description'] = this.description;
    data['date'] = this.date;
    data['language'] = this.language;
    return data;
  }
}
