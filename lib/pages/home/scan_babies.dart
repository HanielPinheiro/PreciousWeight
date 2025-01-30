import 'package:flutter/material.dart';

class ScanBabiesScreen extends StatelessWidget {
  const ScanBabiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 109),
            child: Column(
              children: [
                const Text(
                  'Escanear Bebês',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: 'Caprasimo',
                    fontWeight: FontWeight.w400,
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
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: -85,
                        right: 0,
                        child: Image.network(
                          'https://cdn.builder.io/api/v1/image/assets/TEMP/35fcf00c9e6a624525cd2ab94d6af540c8668d9d009bd4b5e22f6993e49d587a?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                          width: 86,
                          height: 85,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: 222,
                        left: 0,
                        child: Image.network(
                          'https://cdn.builder.io/api/v1/image/assets/TEMP/59a4bf5b3fe51e70c1b635e3fbddd19e5d441cd9e17c5e541cdba21a915af02d?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                          width: 85,
                          height: 85,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        bottom: -11,
                        right: 0,
                        child: Image.network(
                          'https://cdn.builder.io/api/v1/image/assets/TEMP/331bdc5ef3ec1faf86962ac63675cd8812221da8bea1de7da03b31af8c34fa56?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                          width: 86,
                          height: 86,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(247, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 4),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontFamily: 'Baloo',
                      fontWeight: FontWeight.w400,
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

final scanBabiesTheme = ThemeData(
  fontFamily: 'Caprasimo',
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Colors.white,
      fontSize: 32,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Baloo',
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.w400,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF7800),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
  ),
);