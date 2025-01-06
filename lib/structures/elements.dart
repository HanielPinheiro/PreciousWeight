import 'package:flutter/material.dart';
import 'definitions.dart';

class ElementsOfViews {

  static RoundedInput(String text) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(text, style: Definitions.amaranth_20_white),
      SizedBox(height: 5),
      TextFormField(
        decoration: InputDecoration(
          filled: true,
          fillColor: Definitions.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    ]);
  }

  static AlignedTextButton(String text, TextStyle style, Alignment align, VoidCallback? action) {
    return Align(
        alignment: align, //Alignment.centerRight,
        child: TextButton(
            onPressed: action, //() { },
            child: Text(text, style: style) //Definitions.amaranth_20_white),
            ));
  }

  static RoundedElevatedButton(String text, Color color, TextStyle style, VoidCallback? action) {
    return ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, style: style));
  }

  static ScanButton(String label){
    return Padding( padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Material(
        color: Definitions.white,
        borderRadius: BorderRadius.circular(15),
        child: Container(
            padding: EdgeInsets.all(9),
            decoration: BoxDecoration(
              border: Border.all(color: Definitions.partial_black),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(width: 80,height: 80,color: Definitions.blue),
                SizedBox(width: 12),
                Expanded(child: Text(label,style: Definitions.amaranth_29_black)),
              ],
            ))
      ));
  }

  static NavBarItem(String iconPath, String label, bool isSelected){
    return Column(
      children: [
       /* Image.network(
          iconPath,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),*/
        Container(width: 50,height: 50,color: Definitions.blue),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Baloo',
            fontSize: 20,
            color: isSelected ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
