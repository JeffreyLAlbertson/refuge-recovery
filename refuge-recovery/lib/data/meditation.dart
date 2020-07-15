class Meditation {
  final String meditationId;
  final String name;
  final String logoFileName;
  final String folderName;

  Meditation(
      {this.meditationId, this.name, this.logoFileName, this.folderName});

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
        meditationId: json['meditationId'],
        name: json['name'],
        logoFileName: json['logoFilename'],
        folderName: json['folderName']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['meditationId'] = this.meditationId;
    data['name'] = this.name;
    data['logoFileName'] = this.logoFileName;
    data['folderName'] = this.folderName;
    return data;
  }
}
