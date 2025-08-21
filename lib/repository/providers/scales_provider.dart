import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../api/baby_api.dart';
import '../../models/scales.dart';
import '../../api/scale_api.dart';

class ScalesProvider with ChangeNotifier {
  final _scaleApi = new ScaleApi();
  final _babyApi = new BabyApi();

  List<ScaleModel> _scales = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<ScaleModel> get scales => _scales;

  ScalesProvider() {
    loadScales();
  }

  Future<void> _updateCache() async {
    _isLoading = false;
    notifyListeners();

    _scales = (await _scaleApi.listScales())!;
    _scales.forEach((p) async {
      await _populatesScaleModelWithExtraData(p);
    });

    _isLoading = true;
    notifyListeners();
  }

  Future<void> _populatesScaleModelWithExtraData(ScaleModel newScale) async {
    final data = await _scaleApi.getScaleDataFromHash(newScale.hash);
    newScale.mac = data[0];
    newScale.pop = data[1];
    if (newScale.babyId != null) newScale.assignedBaby = await _babyApi.searchBaby(newScale.babyId!.toString());
  }

  int _getIndexFromList(int scale_id) {
    return _scales.indexWhere((b) => b.id == scale_id);
  }

  ScaleModel? _scaleInCache(int scale_id) {
    final index = _scales.indexWhere((b) => b.id == scale_id);
    return (index != -1) ? _scales[index] : null;
  }

  Future<void> _setNewScaleToCache(ScaleModel scale) async {
    await _populatesScaleModelWithExtraData(scale);
    _scales.add(scale);
  }

  ScaleModel? _scaleInCacheFromHash(String hash) {
    final index = _scales.indexWhere((b) => b.hash == hash);
    return (index != -1) ? _scales[index] : null;
  }

  Future<void> loadScales() async {
    await _updateCache();
  }

  Future<ScaleModel?> getScaleById(int scale_id) async {
    ScaleModel? scale = null;

    scale = _scaleInCache(scale_id);
    if (scale == null) {
      await _updateCache();
      scale = _scaleInCache(scale_id);
      if (scale == null) throw new Exception("Scale not found");
    }

    notifyListeners();
    return scale;
  }

  Future<ScaleModel?> setNewScale(String hash) async {
    final scale = await _scaleApi.setNewScale(hash);
    await _setNewScaleToCache(scale!);
    notifyListeners();
    return scale;
  }

  Future<void> setOrUnsetBaby(int scale_id, {String? baby_code}) async {
    bool result = await _scaleApi.setOrUnsetBaby(scale_id.toString(), baby_code: baby_code);
    if (!result) throw Exception("Erro ao executar setOrUnsetScale");
    final updatedScale = await getScaleById(scale_id);
    final index = _getIndexFromList(scale_id);
    if ((updatedScale!.babyId == null || updatedScale.babyId!.toString() != baby_code) && index != -1) _scales[index] = updatedScale.copyWith(babyId: int.tryParse(baby_code ?? ''));
    notifyListeners();
  }

  Future<void> enableOrDisableScale(ScaleModel scale) async {
    final isActive = scale.status == 1;
    await _scaleApi.enableOrDisableScale(scale.id.toString(), !isActive);
    final idx = _getIndexFromList(scale.id);
    if (idx != -1) _scales[idx] = scale.copyWith(status: !isActive ? 1 : 0);
    notifyListeners();
  }

  Future<Uint8List?> getScaleQrFromHash(String hash) async {
    final data = await _scaleApi.getScaleQrFromHash(hash);
    notifyListeners();
    return data;
  }
}
