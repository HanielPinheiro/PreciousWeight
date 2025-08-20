import 'package:flutter/material.dart';
import '../design/button_styles.dart';
import '../design/fonts.dart';

class ElementsOfViews {
  static Widget ScanButton(BuildContext context, String label, String lbl_img, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        onTap: onTap, // Clickable behavior
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Row(
            children: [
              Image.asset("assets/imgs/$lbl_img", width: 80, height: 80, fit: BoxFit.cover),
              SizedBox(width: 12),
              Expanded(child: Text(label, style: amaranth_29.copyWith(color: Theme.of(context).colorScheme.primary))),
            ],
          ),
        ),
      ),
    );
  }

  static Widget ScanButtonNoImage(BuildContext context, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        onTap: onTap, // Clickable behavior
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(9),
          decoration: MyDecorations().GetBoxDecoration(context),
          child: Row(mainAxisSize: MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Expanded(child: Text(textAlign: TextAlign.center, label, style: amaranth_29.copyWith(color: theme.colorScheme.primary))),
          ]),
        ),
      ),
    );
  }

  static Widget CardToList(BuildContext context, IconData icon, String title, String subtitle, VoidCallback detailsScreen) {
    return Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 5,
        shadowColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: GestureDetector(
            onTap: detailsScreen,
            child: ListTile(
              leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
              title: Text(title, style: headlineSmall.copyWith(color: Theme.of(context).colorScheme.primary)),
              subtitle: Text(subtitle, style: bodyLarge.copyWith(color: Theme.of(context).colorScheme.primary)),
            )));
  }

  static Widget CardToText(BuildContext context, String label, {Color? bgColor, Color? fgColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Card(
        elevation: 5,
        shadowColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        color: bgColor ?? Theme.of(context).colorScheme.surface,
        child: Container(
          padding: EdgeInsets.all(9),
          alignment: Alignment.center, // Centers the text inside the card
          child: Text(
            label,
            style: amaranth_29.copyWith(color: fgColor ?? Theme.of(context).colorScheme.primary),
            textAlign: TextAlign.center, // Ensures text alignment
          ),
        ),
      ),
    );
  }

  static PreferredSizeWidget MenuAppBar(BuildContext context, String title, String label, Icon? _icon, VoidCallback action) {
    return AppBar(
        title: Text(title, style: headlineMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onPrimary)),
        shape: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid)),
        // foregroundColor: Theme.of(context).brightness == Brightness.dark? Colors.white: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: <Widget>[
          ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 100, minHeight: 40, maxHeight: 40),
              child: OutlinedButton.icon(
                icon: _icon ?? const SizedBox.shrink(),
                label: Text(
                  label,
                  style: headlineSmall.copyWith(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).colorScheme.onPrimary),
                ),
                style: MyButtonStyles().GetLogoutButtonStyle(context),
                onPressed: action,
              ))
        ]);
  }

  static PreferredSizeWidget SimpleAppBar(BuildContext context, String title) {
    return AppBar(
      title: Text(
        title,
        style: displayMedium.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
      shape: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.0, style: BorderStyle.solid)),
      foregroundColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  static Widget InputWithController(BuildContext context, TextEditingController _controller, String labelText, String hintText, Icon _icon, [bool isPassword = false, bool isReadOnly = false]) {
    return TextField(controller: _controller, style: TextStyle(color: Theme.of(context).colorScheme.primary), decoration: MyDecorations().GetInputDecoration(context, labelText, hintText, _icon), readOnly: isReadOnly, obscureText: isPassword);
  }

  static Future<void> ShowTimeManager(BuildContext context, ValueChanged<String> onSave, {required String initialTimes}) async {
    List<String> times = [];
    if (initialTimes != 'Sem horário definido') times = initialTimes.split(r"$")..removeWhere((t) => t.isEmpty);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: MyDecorations().GetBoxDecoration(context),
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Gerenciar horários', style: displayMedium.copyWith(color: Theme.of(context).colorScheme.primary)),
                SizedBox(height: 20),
                SimpleButton(context, "Adicionar horário", () async {
                  if (times.length > 9) {
                    await showDialog(context: context, builder: (context) => AlertDialog(content: Text("O número máximo de horários é 10!")));
                    return;
                  }
                  final time = await _GetTimePicker(context);
                  if (time != null) {
                    final formattedStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    if (!times.contains(formattedStr)) setState(() => times.add(formattedStr));
                    times.sort();
                  }
                }, true),
                SizedBox(height: 20),
                Expanded(
                    child: ListView.builder(
                        itemCount: times.length, itemBuilder: (ctx, i) => ListTile(leading: Text((i + 1).toString(), textAlign: TextAlign.center, style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary)), title: Text(times[i], textAlign: TextAlign.center, style: displaySmall.copyWith(color: Theme.of(context).colorScheme.primary)), trailing: IconButton(icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.primary), onPressed: () => setState(() => times.removeAt(i)))))),
                SizedBox(height: 20),
                SimpleButton(context, "Voltar", () {
                  onSave(times.join(r"$"));
                  Navigator.pop(context);
                }, true)
              ],
            ),
          );
        },
      ),
    );
  }

  static TimeOfDay _GetTimeOfDayInGmtMinusThree(TimeOfDay? time) {
    final now = DateTime.now();
    final utcTime = time != null ? DateTime(now.year, now.month, now.day, time.hour, time.minute) : DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final gmtMinus3Time = utcTime.subtract(const Duration(hours: 3));
    return TimeOfDay.fromDateTime(gmtMinus3Time);
  }

  static _GetTimePicker(BuildContext context) {
    return showTimePicker(
      context: context,
      initialTime: _GetTimeOfDayInGmtMinusThree(TimeOfDay.now()),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      cancelText: "Cancelar",
      confirmText: "Confirmar",
      helpText: "Insira as horas e minutos:",
      hourLabelText: "Hora",
      minuteLabelText: "Minuto",
      builder: (BuildContext context, Widget? child) {
        final colorScheme = Theme.of(context).colorScheme;
        final style = ButtonStyle(backgroundColor: WidgetStatePropertyAll(colorScheme.surface), foregroundColor: WidgetStatePropertyAll(colorScheme.primary), side: WidgetStatePropertyAll(BorderSide(color: colorScheme.primary, width: 1.5)), elevation: WidgetStatePropertyAll(2));
        return Theme(
          data: Theme.of(context).copyWith(timePickerTheme: TimePickerThemeData(confirmButtonStyle: style, cancelButtonStyle: style, backgroundColor: colorScheme.onSurface, hourMinuteColor: colorScheme.surface, hourMinuteTextColor: colorScheme.primary, helpTextStyle: headlineSmall.copyWith(color: colorScheme.primary))),
          child: Directionality(textDirection: TextDirection.ltr, child: MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!)),
        );
      },
    );
  }

  static Widget DateInput(BuildContext context, TextEditingController _controller, String labelText, String hintText) {
    String _formatDateInput(String input) {
      String digits = input.replaceAll(RegExp(r'[^0-9]'), ''); // Remove all non-digit characters

      if (digits.length >= 3)
        return '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
      else if (digits.length >= 2) return '${digits.substring(0, 2)}/${digits.substring(2)}';

      return digits;
    }

    return TextField(
        controller: _controller,
        keyboardType: TextInputType.datetime,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
          labelText: labelText,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary)),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            final formatted = _formatDateInput(value);
            if (formatted != value) _controller.value = _controller.value.copyWith(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
          }
        });
  }

  static Widget SimpleButton(BuildContext context, String _text, [VoidCallback? _onPressed = null, bool isActive = false, bool isDisable = false]) {
    return TextButton(
      onPressed: isDisable
          ? null
          : _onPressed != null
              ? _onPressed
              : () {},
      style: TextButton.styleFrom(
        backgroundColor: isActive ? Theme.of(context).colorScheme.onSecondary : Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.0,
          style: BorderStyle.solid,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
      child: Text(_text),
    );
  }

  static Widget ContrastButton(BuildContext context, Icon _icon, String _text, [VoidCallback? _onPressed = null]) {
    return ElevatedButton.icon(
      icon: _icon,
      label: Text(_text, style: headlineSmall.copyWith(color: Colors.black)),
      onPressed: _onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
        elevation: 4.0,
// side: BorderSide(color: Theme.of(context).colorScheme.onSecondary, width: 1.0, style: BorderStyle.solid,),
      ),
    );
  }

// static Widget RoundedInput(String text) {
//   return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//     Text(text, style: amaranth_20),
//     SizedBox(height: 5),
//     TextFormField(
//       decoration: InputDecoration(
//         filled: true,
//         fillColor: white,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
//       ),
//     ),
//   ]);
// }

// static Widget AlignedTextButton(String text, TextStyle style, Alignment align, VoidCallback? action) {
//   return Align(
//       alignment: align, //Alignment.centerRight,
//       child: TextButton(
//           onPressed: action, //() { },
//           child: Text(text, style: style) //Definitions.amaranth_20_white),
//       ));
// }

// static Widget RoundedElevatedButton(String text, Color color, TextStyle style, VoidCallback? action) {
//   return ElevatedButton(
//       onPressed: action,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         padding: const EdgeInsets.symmetric(vertical: 7),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       ),
//       child: Text(text, style: style));
// }
//
// static Widget BabyWeightChart(List<WeightModel> baby) {
//   return LineChart(
//     LineChartData(
//       gridData: const FlGridData(show: false),
//       titlesData: const FlTitlesData(show: true),
//       borderData: FlBorderData(
//         show: true,
//         border: Border.all(color: Colors.black),
//       ),
//       lineBarsData: [
//         LineChartBarData(
//           spots: [
//             const FlSpot(0, 1),
//             const FlSpot(1, 3),
//             const FlSpot(2, 7),
//             const FlSpot(3, 4),
//             const FlSpot(4, 6),
//           ],
//           isCurved: true,
//           color: Colors.blue,
//           barWidth: 3,
//           isStrokeCapRound: true,
//           belowBarData: BarAreaData(show: false),
//         ),
//       ],
//     ),
//   );
// }
}
