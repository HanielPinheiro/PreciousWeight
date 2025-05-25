import 'dart:convert';
import '../models/user.dart';
import '../repository/helper/constants.dart';
import '../repository/services/api_service.dart';

class UserApi {
  UserApi._internal(); // Private constructor
  static final UserApi _instance = UserApi._internal();
  factory UserApi() => _instance;

  User? _user;
  Token? get token => _user!.token;
  User? get user => _user;

  Future<void> Login(String username, String password) async {
    try {
      final _body = jsonEncode({
        'username': username,
        'password': password,
      });

      final _header = {'Content-Type': 'application/json'};

      _user = userFromJson(await ApiService.apiConn("${address_api}${api_user_login}", body: _body, header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<List<User>?> listUsers() async {
    try {
      final result = await ApiService.apiConn("${address_api}${api_user_list}");
      return usersFromJson(result);
    } catch (error) {
      throw error;
    }
  }

  Future<void> Logout() async {
    try {
      _user = null;
      // ApiConn("${address_api}${api_user_logout}");
    } catch (error) {
      throw error;
    }
  }
}
