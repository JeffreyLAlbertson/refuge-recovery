class Reading {
  final String readingId;
  final String meditationId;
  final String meditationName;
  final String folderName;
  final String reader;
  final bool isLocal;
  final String fileName;
  final String logoFileName;
  final String language;

  Reading(
      {this.readingId,
      this.meditationId,
      this.meditationName,
      this.folderName,
      this.reader,
      this.isLocal,
      this.fileName,
      this.logoFileName,
      this.language});

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
        readingId: json['readingId'],
        meditationId: json['meditationId'],
        meditationName: json['meditationName'],
        folderName: json['folderName'],
        reader: json['reader'],
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
    data['folderName'] = this.folderName;
    data['reader'] = this.reader;
    data['isLocal'] = this.isLocal;
    data['fileName'] = this.fileName;
    data['logoFileName'] = this.logoFileName;
    data['language'] = this.language;
    return data;
  }
}
