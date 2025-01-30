import 'package:flutter/material.dart';
import 'definitions.dart';

class ElementsOfViews {
  static Widget RoundedInput(String text) {
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

  static Widget AlignedTextButton(String text, TextStyle style, Alignment align, VoidCallback? action) {
    return Align(
        alignment: align, //Alignment.centerRight,
        child: TextButton(
            onPressed: action, //() { },
            child: Text(text, style: style) //Definitions.amaranth_20_white),
            ));
  }

  static Widget RoundedElevatedButton(String text, Color color, TextStyle style, VoidCallback? action) {
    return ElevatedButton(
        onPressed: action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, style: style));
  }

  static Widget ScanButton(String label, String lbl_img, VoidCallback onTap) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Material(
            color: Definitions.white,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
                onTap: onTap, // Call the provided onTap callback
                borderRadius: BorderRadius.circular(15), // Match the Material's borderRadius
                child: Container(
                    padding: EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      border: Border.all(color: Definitions.partial_black),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(width: 80, height: 80, color: Definitions.blue, child: Image.asset("assets/imgs/$lbl_img")),
                        SizedBox(width: 12),
                        Expanded(child: Text(label, style: Definitions.amaranth_29_black)),
                      ],
                    )))));
  }

  static Widget NavBarItem(String iconPath, String label, bool isSelected) {
    var imgName = isSelected ? '${iconPath}_w.png' : '$iconPath.png';
    return GestureDetector(
        //onTap: onTap,
        child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected ? Definitions.strongOrange.withOpacity(0.2) : Colors.transparent,
            ),
            child: Column(children: [
              Container(width: 50, height: 50, color: Definitions.strongOrange, child: Image.asset('assets/imgs/$imgName')),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Baloo',
                  fontSize: 20,
                  color: isSelected ? Colors.white : const Color(0xFF333333),
                ),
              ),
            ])));
  }

  static Widget Menu() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
      Expanded(flex: 25, child: ElementsOfViews.NavBarItem("menu_home", 'Início', true)),
      Expanded(flex: 25, child: ElementsOfViews.NavBarItem("menu_bb", 'Bebês', false)),
      Expanded(flex: 25, child: ElementsOfViews.NavBarItem("menu_balances", 'Balança', false)),
      Expanded(flex: 25, child: ElementsOfViews.NavBarItem("menu_logs", 'Históricos', false)),
    ]);
  }
}
