import 'package:flutter/material.dart';
import '../../models/scales/scales_repository.dart';

class ScalesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: ListView(
        children: ScalesRepository.GetScalesLikeCards(context),
      ),
    );
  }
}
