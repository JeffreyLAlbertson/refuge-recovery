class Chime {
  final String chimeId;
  final String chimeName;
  final bool isLocal;
  final String fileName;
  final String logoFileName;
  final String description;
  final String language;

  Chime(
      {this.chimeId,
      this.chimeName,
      this.isLocal,
      this.fileName,
      this.logoFileName,
      this.description,
      this.language});

  factory Chime.fromJson(Map<String, dynamic> json) {
    return Chime(
        chimeId: json['chimeId'],
        chimeName: json['chimeName'],
        isLocal: json['isLocal'],
        fileName: json['filename'],
        logoFileName: json['logoFilename'],
        description: json['description'],
        language: json['language']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['chimeId'] = this.chimeId;
    data['chimeName'] = this.chimeName;
    data['isLocal'] = this.isLocal;
    data['filename'] = this.fileName;
    data['logoFileName'] = this.logoFileName;
    data['description'] = this.description;
    data['language'] = this.language;
    return data;
  }
}
