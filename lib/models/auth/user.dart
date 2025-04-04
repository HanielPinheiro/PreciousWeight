import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

List<User> usersFromJson(String str) => List<User>.from(json.decode(str).map((x) => User.fromJson(x)));

String usersToJson(List<User> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class User {
  String organization;
  String userId;
  String email;
  // Credentials credentials;
  Token token;
  Role role;

  User({required this.organization, required this.userId, required this.email, /*required this.credentials,*/ required this.token, required this.role});

  factory User.fromJson(Map<String, dynamic> json) => User(
        organization: json["organization"],
        userId: json["userId"],
        email: json["email"],
        // credentials: json["credentials"],
        token: json["email"],
        role: json["roles"].map((x) => Role.fromJson(x)),
      );

  Map<String, dynamic> toJson() => {
        "organization": organization,
        "userId": userId,
        "email": email,
        "roles": role.toJson(),
      };
}

// Credentials credentialsFromJson(String str) => Credentials.fromJson(json.decode(str));
// String credentialsToJson(Credentials data) => json.encode(data.toJson());
//
// class Credentials {
//   String username;
//   String password;
//
//   Credentials({
//     required this.username,
//     required this.password,
//   });
//
//   factory Credentials.fromJson(Map<String, dynamic> json) => Credentials(
//
//       );
//
//   Map<String, dynamic> toJson() => {
//         "username": username,
//         "password": password,
//       };
// }

Token tokenFromJson(String str) => Token.fromJson(json.decode(str));
String tokenToJson(Token data) => json.encode(data.toJson());

class Token {
  int expiresIn;
  String accessToken;

  Token({
    required this.accessToken,
    required this.expiresIn,
  });

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        accessToken: json["accessToken"],
        expiresIn: json["expiresIn"],
      );

  Map<String, dynamic> toJson() => {
        "accessToken": accessToken,
        "expiresIn": expiresIn,
      };
}

class Role {
  int roleId;
  String name;

  Role({
    required this.roleId,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        roleId: json["roleId"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "roleId": roleId,
        "name": name,
      };
}
