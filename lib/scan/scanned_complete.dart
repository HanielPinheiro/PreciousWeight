import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssociationScreen extends StatelessWidget {
  const AssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFB676),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 67, 25, 105),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Associação Feita',
                  style: GoogleFonts.getFont(
                    'ADLaM Display',
                    fontSize: 37,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 135),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF333333),
                      width: 5,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 55, 16, 33),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF4D965A),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(56),
                    child: Image.network(
                      'https://cdn.builder.io/api/v1/image/assets/TEMP/3ef30edfb14bc684df1fc0dcd649534ee4d981c7ed2532edd66beea546bee8b8?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                      width: 218,
                      fit: BoxFit.contain,
                      semanticLabel: 'Association success icon',
                    ),
                  ),
                ),
                const SizedBox(height: 94),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Voltar',
                    style: GoogleFonts.getFont(
                      'ADLaM Display',
                      fontSize: 37,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}