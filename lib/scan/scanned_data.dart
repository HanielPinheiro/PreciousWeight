import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannedDataScreen extends StatelessWidget {
  const ScannedDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFB676),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 63),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dados Escaneados',
                  style: GoogleFonts.aDLaMDisplay(
                    fontSize: 37,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 69),
                Image.network(
                  'https://cdn.builder.io/api/v1/image/assets/TEMP/3adeb370fdd2d571db5d07fc930051d42169e74bdbb9d020db91d0b15a6e30d8?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                  width: 233,
                  fit: BoxFit.contain,
                  semanticLabel: 'Scanned Data Image 1',
                ),
                const SizedBox(height: 11),
                const DataDisplayCard(
                  content: 'RH: 1250498',
                ),
                const SizedBox(height: 43),
                Image.network(
                  'https://cdn.builder.io/api/v1/image/assets/TEMP/a67756a3de6df9819cea68394ffe8f6153d819dfa65a7caf2df35391d7034078?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                  width: 230,
                  fit: BoxFit.contain,
                  semanticLabel: 'Scanned Data Image 2',
                ),
                const SizedBox(height: 13),
                const DataDisplayCard(
                  content: 'ID: 12\nMAC Address\n00-B0-D0-63-C2-26',
                ),
                const SizedBox(height: 76),
                Text(
                  'Confirmar?',
                  style: GoogleFonts.aDLaMDisplay(
                    fontSize: 37,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 9),
                const ConfirmationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DataDisplayCard extends StatelessWidget {
  final String content;

  const DataDisplayCard({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 70),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: GoogleFonts.jost(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ConfirmationButtons extends StatelessWidget {
  const ConfirmationButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ConfirmationButton(
          text: 'Sim',
          backgroundColor: const Color(0xFF4D965A),
          onPressed: () {
            // Handle confirmation
          },
        ),
        const SizedBox(width: 20),
        _ConfirmationButton(
          text: 'Não',
          backgroundColor: const Color(0xFF964D4D),
          onPressed: () {
            // Handle rejection
          },
        ),
      ],
    );
  }
}

class _ConfirmationButton extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _ConfirmationButton({
    required this.text,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.aDLaMDisplay(
          fontSize: 37,
          color: Colors.white,
        ),
      ),
    );
  }
}
