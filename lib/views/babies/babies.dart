import 'package:flutter/material.dart';
import '../../models/babies/babies_repository.dart';

class BabiesPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: ListView(
        children: BabiesRepository.GetBabiesLikeCards(context),
      ),
    );
  }
}