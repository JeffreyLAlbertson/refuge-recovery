class User {
  final String userId;
  final String authId;
  final String authProviderId;
  final String displayName;
  final String email;
  final DateTime joinDate;

  User({this.userId, this.authId, this.authProviderId, this.displayName, this.email, this.joinDate});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        userId: json['userId'],
        authId: json['authId'],
        authProviderId: json['authProviderId'],
        displayName: json['displayName'],
        email: json['email'],
        joinDate: DateTime.parse(json['joinDate'])
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data['authId'] = this.authId;
    data['authProviderId'] = this.authProviderId;
    data["displayName"] = this.displayName;
    data["email"] = this.email;
    data["joinDate"] = this.joinDate.toString();
    return data;
  }
}
