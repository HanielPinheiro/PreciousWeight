import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:precious_weight/api/baby_api.dart';
import 'package:precious_weight/models/scales.dart';

import '../../api/scale_api.dart';


class ScalesProvider with ChangeNotifier {
  final ScaleApi _api = ScaleApi();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<ScaleModel> _scales = [];
  List<ScaleModel> get scales => _scales;

  ScalesProvider(){
    loadScales();
  }


  Future<void> loadScales() async {
    _isLoading = true;
    notifyListeners();

    try {
      _scales = (await _api.listScales())!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setOrUnsetScale(String scale_id, {String? baby_code}) async {
    try {
      bool result = await _api.setOrUnsetScale(scale_id, baby_code: baby_code);
      if (result) {
        ScaleModel? updatedScale = await _api.searchScale(scale_id);
        final index = _scales.indexWhere((b) => b.id == scale_id);

        if (index != -1 && updatedScale != null) {
          _scales[index] = updatedScale;
          notifyListeners();
        }
      } else
        throw Exception("Erro ao executar setOrUnsetScale");
    }
    catch(Exception){

    }
  }


}