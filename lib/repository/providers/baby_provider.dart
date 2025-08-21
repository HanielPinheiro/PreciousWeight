import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../api/baby_api.dart';
import '../../models/baby.dart';

class BabyProvider with ChangeNotifier {
  final BabyApi _api = BabyApi();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<BabyModel> _babies = [];
  List<BabyModel> get babies => _babies;

  BabyProvider(){
    loadBabies();
  }

  Future<void> loadBabies() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _updateCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateCache() async {
    try {
      _babies = (await _api.listBabies())!;
      notifyListeners();
    } catch (e) {
      print('Error updating cache: $e');
    }
  }

  int _getIndexFromList(int baby_id){
    return _babies.indexWhere((b) => b.id == baby_id);
  }

  BabyModel? _babyInCache(int baby_id){
    final index = _babies.indexWhere((b) => b.id == baby_id);
    return (index != -1) ? _babies[index]: null;
  }

  Future<BabyModel?> getBabyById(int id) async {
    try {
      final searchInCache = _babyInCache(id);
      if(searchInCache != null) return searchInCache;
      else{
        final searchInDb = await _api.searchBaby(id.toString());
        if(searchInDb != null) {
          _updateCache();
          notifyListeners();
          return searchInDb;
        }
        throw new Exception("Baby not found");
      }
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> getQrCode(int id) async {
    return await _api.getQrCode(id.toString());
  }

  Future<BabyModel> loadBabyWithQr(int id) async {
    try {
      final baby = await getBabyById(id);
      if (baby != null && baby.hasQrCode) {
        await baby.loadQrImage(_api);
      }
      return baby!;
    } catch (e) {
      throw Exception('Failed to load baby with QR: $e');
    }
  }

  Future<void> toggleBabyStatus(BabyModel baby) async {
    await _api.enableOrDisableBaby(baby.id.toString(), !baby.isActive!);
    final idx =  _getIndexFromList(baby.id!);
    if(idx != -1) _babies[idx] = baby.copyWith(isActive: !baby.isActive!);
    notifyListeners();
  }

  Future<BabyModel> addBaby(BabyModel newBaby) async {
    final babyLikeJson = babyToJson(newBaby);
    final baby = await _api.insertBaby(babyLikeJson);
    _updateCache();
    notifyListeners();
    return baby!;
  }

  Future<void> updateBaby(BabyModel updatedBaby) async {
    await _api.updateBaby(updatedBaby.id.toString(), updatedBaby.toJson());
    _updateCache();
    notifyListeners();
  }

  Future<void> updateQrCode(int baby_id, Uint8List? qrImage) async {
    await _api.updateBabyQr(baby_id.toString(), qrImage);
    _updateCache();
    notifyListeners();
  }


}