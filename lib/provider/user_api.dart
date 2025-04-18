import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth/user.dart';
import '../repository/helper/constants.dart';

class UserApi {
  User? _user;

  UserApi._internal(); // Private constructor
  static final UserApi _instance = UserApi._internal();

  factory UserApi() => _instance;

  Token? get token => _user!.token;

  User? get user => _user;

  Future<void> Login(String username, String password) async {
    try {
      var client = http.Client();
      var uri = Uri.parse("${address_localhost}${api_user_login}");
      var response = await client.post(
        uri,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final _data = const Utf8Decoder().convert(response.bodyBytes);
        _user = userFromJson(_data);
      }

      throw new Exception("${response.statusCode} - Erro ao tentar acessar");
    } catch (error) {
      throw error;
    }
  }

  Future<List<User>?> listUsers() async {
    try {
      var client = http.Client();
      var uri = Uri.parse("${address_api}${api_user_list}");
      var response = await client.post(uri);
      if (response.statusCode == 200) {
        return usersFromJson(const Utf8Decoder().convert(response.bodyBytes));
      }
      throw new Exception("${response.statusCode} - Erro ao tentar acessar");
    } catch (error) {
      throw error;
    }
  }

  Future<void> Logout() async {
    try {
      // var client = http.Client();
      // var uri = Uri.parse("${address_api}${api_user_list}");
      // var response = await client.post(uri);
      // if (response.statusCode == 200)
        _user = null;

      // throw new Exception("${response.statusCode} - Erro ao tentar acessar");
    } catch (error) {
      throw error;
    }
  }

}
