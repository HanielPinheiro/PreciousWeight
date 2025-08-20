import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

final dateFormatter_dbToObj = DateFormat('yyyy-MM-dd');
final dateFormatter_objToDb = DateFormat('dd/MM/yyyy');
final dateFormatter_log= DateFormat('dd/MM/yyyy - HH:mm:ss');

DateTime parseUtcTime(String dateString) {
  return DateTime.parse("${dateString}Z").toLocal(); // "Z" forces UTC
}

Future<Uint8List> imageToUint8List(Image image) async {
  // Get the image as ui.Image
  final completer = Completer<ui.Image>();
  image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((info, _) => completer.complete(info.image)));

  final ui.Image uiImage = await completer.future;

  // Convert to byte data
  final ByteData? byteData = await uiImage.toByteData(
    format: ui.ImageByteFormat.png,
  );

  // Ensure we have the correct Uint8List type
  return Uint8List.view(byteData!.buffer);
}