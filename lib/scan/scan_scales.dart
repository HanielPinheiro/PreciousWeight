import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanScaleScreen extends StatelessWidget {
  const ScanScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Escanear Balança',
                  style: GoogleFonts.caprasimo(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 120),
                Container(
                  color: const Color(0xFFE1E1E1),
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -10,
                        left: 0,
                        child: Image.network(
                          'https://cdn.builder.io/api/v1/image/assets/TEMP/997b2ef8e18aa97d98761c49cd0aecb2a92f1ff2d949db0eb964a1a860ba9f61?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                          width: 85,
                          height: 85,
                        ),
                      ),
                      Positioned(
                        top: -10,
                        right: 0,
                        child: Image.network(
                          'https://cdn.builder.io/api/v1/image/assets/TEMP/35fcf00c9e6a624525cd2ab94d6af540c8668d9d009bd4b5e22f6993e49d587a?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                          width: 86,
                          height: 85,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Image.network(
                          'https://cdn.builder.io/api/v1/image/assets/TEMP/59a4bf5b3fe51e70c1b635e3fbddd19e5d441cd9e17c5e541cdba21a915af02d?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                          width: 85,
                          height: 85,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Image.network(
                          'https://cdn.builder.io/api/v1/image/assets/TEMP/331bdc5ef3ec1faf86962ac63675cd8812221da8bea1de7da03b31af8c34fa56?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                          width: 86,
                          height: 86,
                        ),
                      ),
                      const SizedBox(
                        height: 300,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
                SizedBox(
                  width: 282,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7800),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    child: Text(
                      'Voltar',
                      style: GoogleFonts.baloo2(
                        fontSize: 28,
                        color: Colors.white,
                      ),
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