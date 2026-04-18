import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../api/baby_api.dart';
import '../../api/scale_api.dart';
import '../../models/baby.dart';
import '../helper/conversions.dart';
import '../services/api_service.dart';

class BabyProvider with ChangeNotifier {
  final _scaleApi = new ScaleApi();
  final _babyApi = new BabyApi();

  final Map<int, BabyModel> _babiesMap = {};

  List<BabyModel> get babies => _babiesMap.values.toList();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  BabyProvider() {
    _updateCache();
  }

  Future<void> _updateCache() async {
    try {
      _isLoading = true;
      notifyListeners();

      final bb = await _babyApi.listBabies();
      if (bb == null) return;
      _babiesMap.clear();
      for (final newBaby in bb) {
        BabyModel tempBaby = newBaby;
        if (newBaby.hasQrCode) {
          final qrData = await _babyApi.getQrCode(newBaby.id!.toString());
          if (qrData != null) tempBaby = tempBaby.copyWith(qrCodeImage: Image.memory(qrData));
        }

        if (newBaby.scaleId != null) {
          final scale = await _scaleApi.getScaleFromId(newBaby.scaleId!.toString());
          tempBaby = tempBaby.copyWith(assignedScale: scale);
        }
        _babiesMap[tempBaby.id!] = tempBaby;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _babyExists(int baby_id) => _babiesMap.containsKey(baby_id);

  BabyModel? _getBabyFromMap(int baby_id) => _babiesMap[baby_id];

  Future<void> loadBabies() async {
    await _updateCache();
  }

  Future<BabyModel> getBabyById(BuildContext context, int id) async {
    try {
      BabyModel? baby = _babyExists(id) ? _getBabyFromMap(id) : null;
      if (baby == null) {
        await SafeApi.call(context: context, apiCall: () async => await _updateCache());
        baby = _babyExists(id) ? _getBabyFromMap(id) : null;
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
      final result = await SafeApi.call<bool>(context: context, apiCall: () async => await _babyApi.enableOrDisableBaby(baby.id.toString(), !baby.isActive!));
      if (!result) throw Exception("Erro ao alterar estado");
      if (_babyExists(baby.id!)) _babiesMap[baby.id!] = baby.copyWith(isActive: !baby.isActive!);
    } catch (e) {
      return;
    } finally {
      notifyListeners();
    }
  }

  Future<BabyModel> addBaby(BuildContext context, BabyModel newBaby) async {
    try {
      final baby = await SafeApi.call<BabyModel?>(context: context, apiCall: () async => await _babyApi.insertBaby(babyToJson(newBaby)));
      if (baby == null) throw Exception("Falha ao adicionar novo bebê");
      _babiesMap[baby.id!] = baby;
      return baby;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<BabyModel> updateBaby(BuildContext context, BabyModel updatedBaby) async {
    try {
      final baby = await SafeApi.call<BabyModel?>(context: context, apiCall: () async => await _babyApi.updateBaby(updatedBaby.id.toString(), updatedBaby.toJson()));
      if (baby == null) throw Exception("Falha ao adicionar novo bebê");
      _babiesMap[updatedBaby.id!] = updatedBaby;
      return updatedBaby;
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateQrCode(BuildContext context, int baby_id, Uint8List? qrImage) async {
    try {
      final baby = _getBabyFromMap(baby_id);
      if (baby == null) throw new Exception("Bebe não localizado!");
      final res = await SafeApi.call<bool>(context: context, apiCall: () async => await _babyApi.updateBabyQr(baby_id.toString(), qrImage));
      if (!res) throw Exception("Falha ao atualizar qr code!");
      if (qrImage != null) _babiesMap[baby_id] = baby.copyWith(hasQr: true, qrCodeImage: Image.memory(qrImage));
    } catch (e) {
      throw e;
    } finally {
      notifyListeners();
    }
  }
}
