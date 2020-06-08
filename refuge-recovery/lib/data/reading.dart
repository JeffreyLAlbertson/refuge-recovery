class Reading {
  final String readingId;
  final String meditationId;
  final String meditationName;
  final String reader;
  final Duration length;
  final bool isLocal;
  final String fileName;
  final String logoFileName;
  final String language;

  Reading(
      {this.readingId,
      this.meditationId,
      this.meditationName,
      this.reader,
      this.length,
      this.isLocal,
      this.fileName,
      this.logoFileName,
      this.language});

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
        readingId: json['readingId'],
        meditationId: json['meditationId'],
        meditationName: json['meditationName'],
        reader: json['reader'],
        length: Duration(milliseconds: json['length']['totalMilliseconds']),
        isLocal: json['isLocal'],
        fileName: json['filename'],
        logoFileName: json['logoFilename'],
        language: json['language']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['readingId'] = this.readingId;
    data['meditationId'] = this.meditationId;
    data['meditationName'] = this.meditationName;
    data['reader'] = this.reader;
    data['length'] = this.length;
    data['isLocal'] = this.isLocal;
    data['fileName'] = this.fileName;
    data['logoFileName'] = this.logoFileName;
    data['language'] = this.language;
    return data;
  }
}
