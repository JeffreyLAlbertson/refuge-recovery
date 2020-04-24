class User {
  final String userId;
  final String displayName;
  final String email;
  final DateTime joinDate;

  User({this.userId, this.displayName, this.email, this.joinDate});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        userId: json['userId'],
        displayName: json['displayName'],
        email: json['email'],
        joinDate: json['joinDate']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    data["displayName"] = this.displayName;
    data["email"] = this.email;
    data["joinDate"] = this.joinDate.toString();
    return data;
  }
}
