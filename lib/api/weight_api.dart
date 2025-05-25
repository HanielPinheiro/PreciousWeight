import '../models/weight.dart';
import '../repository/helper/constants.dart';
import '../repository/services/api_service.dart';
import 'user_api.dart';

class WeightApi {
  Future<List<WeightModel>?> getWeights() async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      final result = await ApiService.apiConn("${address_api}${api_weight_list}", header: _header);
      return weightsFromJson(result);
    } catch (error) {
      throw error;
    }
  }

  Future<List<WeightModel>?> getBabyWeigths(String baby_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      final result = await ApiService.apiConn("${address_api}${api_weight_babies.replaceAll(api_pattern_code, baby_code)}", header: _header);
      return weightsFromJson(result);
    } catch (error) {
      throw error;
    }
  }

  Future<List<WeightModel>?> getScaleWeights(String scale_code) async {
    try {
      final _header = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${UserApi().token!.accessToken}'};
      final result = await ApiService.apiConn("${address_api}${api_weight_scales.replaceAll(api_pattern_code, scale_code)}", header: _header);
      return weightsFromJson(result);
    } catch (error) {
      throw error;
    }
  }
}
