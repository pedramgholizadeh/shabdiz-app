import 'json_utils.dart';

class User {
  const User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: asInt(json['id']),
        email: asString(json['email']),
        name: asString(json['name']),
      );

  final int id;
  final String email;
  final String name;
}
