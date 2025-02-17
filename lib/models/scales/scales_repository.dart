import 'package:flutter/material.dart';
import '../../repository/widgets/elements.dart';
import '../../views/scales/scales_details.dart';
import 'scales.dart';


class ScalesRepository {
  static List<ScaleModel> scales = <ScaleModel>[
    ScaleModel(id: 1, hash: 'hash1', status: 1),
    ScaleModel(id: 2, hash: 'hash2', status: 0),
    ScaleModel(id: 3, hash: 'hash3', status: 1),
    ScaleModel(id: 4, hash: 'hash4', status: 0),
    ScaleModel(id: 5, hash: 'hash5', status: 1),
    ScaleModel(id: 6, hash: 'hash6', status: 1),
    ScaleModel(id: 7, hash: 'hash7', status: 0),
    ScaleModel(id: 8, hash: 'hash8', status: 1),
    ScaleModel(id: 9, hash: 'hash9', status: 0),
    ScaleModel(id: 10, hash: 'hash10', status: 1),
    ScaleModel(id: 11, hash: 'hash11', status: 1),
    ScaleModel(id: 12, hash: 'hash12', status: 0),
    ScaleModel(id: 13, hash: 'hash13', status: 1),
    ScaleModel(id: 14, hash: 'hash14', status: 0),
    ScaleModel(id: 15, hash: 'hash15', status: 1),
  ];

  static List<Widget> GetScalesLikeCards(BuildContext context) {
    return scales.map((_scale) {
      return ElementsOfViews.CardToList(
        Icons.scale,
        'Código da Balança  #${_scale.id}',
        'Estado: ${_scale.status == 1 ? 'Operante' : 'Inoperante'}',
            () {Navigator.push(context,MaterialPageRoute(builder: (context) => ScaleDetails(scale: _scale),));},
      );
    }).toList();
  }
}