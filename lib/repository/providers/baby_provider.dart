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
      _babies = (await _api.listBabies())!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBaby(BabyModel updatedBaby, [Uint8List? qrImage]) async {
    await _api.updateBaby(updatedBaby.id.toString(), updatedBaby.toJson());
    await _api.updateBabyQr(updatedBaby.id.toString(), qrImage);
    final index = _babies.indexWhere((b) => b.id == updatedBaby.id);
    if (index != -1) {
      _babies[index] = updatedBaby;
      notifyListeners();
    }
  }

  Future<void> toggleBabyStatus(BabyModel baby) async {
    await _api.enableOrDisableBaby(baby.id.toString(), !baby.isActive!);
    final index = _babies.indexWhere((b) => b.id == baby.id);
    if (index != -1) {
      _babies[index] = baby.copyWith(isActive: !baby.isActive!);
      notifyListeners();
    }
  }

  Future<BabyModel> addBaby(BabyModel newBaby) async {
    final babyLikeJson = babyToJson(newBaby);
    final baby = await _api.insertBaby(babyLikeJson);
    _babies.add(baby!);
    notifyListeners();
    return baby;
  }

  Future<BabyModel?> getBabyById(int id) async {
    try {
      final baby = await _api.searchBaby(id.toString());
      // Update in local cache if found
      final index = _babies.indexWhere((b) => b.id == id);
      if (index != -1 && baby != null) {
        _babies[index] = baby;
        notifyListeners();
      }
      return baby;
    } catch (e) {
      return null;
    }
  }
}