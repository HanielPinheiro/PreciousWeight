import 'dart:convert';

import '../models/scales.dart';
import '../repository/helper/constants.dart';
import '../repository/services/api_service.dart';
import 'user_api.dart';

class ScaleApi {
  Future<List<ScaleModel>?> listScales() async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      return scalesFromJson(await ApiService.apiConn("${address_api}${api_scale_list}", header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<ScaleModel?> searchScale(String scale_code) async {
    try {
      return scaleFromJson(await ApiService.apiConn("${address_api}${api_scale_search.replaceAll(api_pattern_code, scale_code)}"));
    } catch (error) {
      throw error;
    }
  }

  Future<ScaleModel?> insertScale(Map<String, dynamic> scaleLikeJson) async {
    try {
      final _body = jsonEncode(scaleLikeJson);
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      return scaleFromJson(await ApiService.apiConn("${address_api}${api_scale_new}", body: _body, header: _header));
    } catch (error) {
      throw error;
    }
  }

  Future<bool> updateScale(String scale_code, Map<String, dynamic> scaleLikeJson) async {
    try {
      final _body = jsonEncode(scaleLikeJson);
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
      await ApiService.apiConn("${address_api}${api_baby_update.replaceAll(api_pattern_code, scale_code)}", body: _body, header: _header);
      return true;
    } catch (error) {
      throw error;
    }
  }

  Future<bool> enableOrDisableScale(String scale_code, [bool enable = true]) async {
    final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};
    try {
      if (enable)
        await ApiService.apiConn("${address_api}${api_scale_enable.replaceAll(api_pattern_code, scale_code)}",header: _header);
      else
        await ApiService.apiConn("${address_api}${api_scale_disable.replaceAll(api_pattern_code, scale_code)}", header: _header);
      return true;
    } catch (error) {
      throw error;
    }
  }

  Future<bool> setOrUnsetScale(String scale_code, {String? baby_code}) async {
    try {
      String _body;
      String _uri;
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}', 'Accept': 'application/json'};

      if (baby_code == null) {
        _body = jsonEncode({"scaleId": scale_code});
        _uri = "${address_api}${api_scale_unset}";
      } else {
        _body = jsonEncode({"scaleId": scale_code, "babyId": baby_code});
        _uri = "${address_api}${api_scale_set}";
      }

      await ApiService.apiConn(_uri, body: _body, header: _header);
      return true;
    } catch (error) {
      throw error;
    }
  }
}
