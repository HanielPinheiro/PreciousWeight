import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth/user.dart';
import '../repository/helper/constants.dart';

class UserApi {
  /*
    final _userApi = UserApi();
    Future<List<User>?> getAllCountries() async {
      return _userApi.listUsers();
    }
      void initState() {
      super.initState();
      loadCountries();
    }
    Future<void> loadCountries() async {
      final countryService = CountryService();
      countries = await countryService.getAllCountries();
      setState(() {
        isLoaded = true;
      });
    }
  */

  Future<Token?> getToken(String username, String password) async {
    var client = http.Client();
    var uri = Uri.parse("http://10.0.2.2:8080${api_user_login}");
    var response = await client.post(uri, body: jsonEncode({
      'username': username,
      'password': password,
    }),headers:{'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return tokenFromJson(const Utf8Decoder().convert(response.bodyBytes));
    }
    return null;
  }


  Future<List<User>?> listUsers() async {
    var client = http.Client();
    var uri = Uri.parse("${address_api}${api_user_list}");
    var response = await client.post(uri);
    if (response.statusCode == 200) {
      return usersFromJson(const Utf8Decoder().convert(response.bodyBytes));
    }
    return null;
  }
}
