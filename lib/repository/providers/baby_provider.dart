import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../api/baby_api.dart';
import '../../api/scale_api.dart';
import '../../models/baby.dart';
import '../services/api_service.dart';

class BabyProvider with ChangeNotifier {
  final _scaleApi = new ScaleApi();
  final _babyApi = new BabyApi();

  List<BabyModel> _babies = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<BabyModel> get babies => _babies;

  BabyProvider() {
    loadBabies();
  }

  Future<void> _updateCache() async {
    try {
      _isLoading = true;
      notifyListeners();

      _babies = (await _babyApi.listBabies())!;
      _babies.forEach((p) async {
        await _populatesBabyModelWithExtraData(p);
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _populatesBabyModelWithExtraData(BabyModel newBaby) async {
    try {
      if (newBaby.hasQrCode) {
        final qrData = await _babyApi.getQrCode(newBaby.id!.toString());
        newBaby.qrCodeImage = Image.memory(qrData!);
      }

      if (newBaby.scaleId != null) {
        newBaby.assignedScale = await _scaleApi.getScaleFromId(newBaby.scaleId!.toString());
      }
    } finally {}
  }

  int _getIndexFromList(int baby_id) {
    return _babies.indexWhere((b) => b.id == baby_id);
  }

  void _refreshOnlyOneBabyInCache(BabyModel baby) async {
    await _populatesBabyModelWithExtraData(baby);
    _babies[_getIndexFromList(baby.id!)] = baby;
  }

  BabyModel? _babyInCache(int baby_id) {
    final index = _babies.indexWhere((b) => b.id == baby_id);
    return (index != -1) ? _babies[index] : null;
  }

  Future<void> loadBabies() async {
    await _updateCache();
  }

  Future<BabyModel> getBabyById(BuildContext context, int id) async {
    try {
      BabyModel? baby = null;

      baby = _babyInCache(id);
      if (baby == null) {
        await SafeApi.call(
            context: context,
            apiCall: () async {
              await _updateCache();
            });
        baby = _babyInCache(id);
        if (baby == null) throw new Exception("Baby not found");
      }
      return baby;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<void> toggleBabyStatus(BuildContext context, BabyModel baby) async {
    try {
      await SafeApi.call(
        context: context,
        apiCall: () async {
          await _babyApi.enableOrDisableBaby(baby.id.toString(), !baby.isActive!);
        },
      );
      final idx = _getIndexFromList(baby.id!);
      if (idx != -1) _babies[idx] = baby.copyWith(isActive: !baby.isActive!);
    } catch (e) {
      return;
    } finally {
      notifyListeners();
    }
  }

  Future<BabyModel> addBaby(BuildContext context, BabyModel newBaby) async {
    try {
      final baby = await SafeApi.call(
          context: context,
          apiCall: () async {
            await _babyApi.insertBaby(babyToJson(newBaby));
          });
      if (baby == null) throw Exception("Falha ao adicionar novo bebê");
      _refreshOnlyOneBabyInCache(baby);
      return baby;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateBaby(BuildContext context, BabyModel updatedBaby) async {
    try {
      final baby = await SafeApi.call(
          context: context,
          apiCall: () async {
            await _babyApi.updateBaby(updatedBaby.id.toString(), updatedBaby.toJson());
          });
      if (baby == null) throw Exception("Falha ao adicionar novo bebê");
      _refreshOnlyOneBabyInCache(baby);
      return baby;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateQrCode(BuildContext context, int baby_id, Uint8List? qrImage) async {
    try {
      final res = await SafeApi.call(
          context: context,
          apiCall: () async {
            await _babyApi.updateBabyQr(baby_id.toString(), qrImage);
          });
      if (!res) throw Exception("Falha ao atualizar qr code");
      _refreshOnlyOneBabyInCache(_babies[_getIndexFromList(baby_id)]);
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }
}
