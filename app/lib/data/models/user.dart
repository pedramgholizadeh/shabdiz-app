import 'json_utils.dart';

class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.isGuest = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: asInt(json['id']),
        email: asString(json['email']),
        name: asString(json['name']),
        isGuest: json['is_guest'] == true || asInt(json['is_guest']) == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'is_guest': isGuest,
      };

  final int id;
  final String email;
  final String name;
  final bool isGuest;
}
