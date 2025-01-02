import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5C5EA3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(25, 54, 25, 13),
              color: const Color(0xFFF8F8F8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Olá, Haniel Nunes',
                    style: TextStyle(
                      fontFamily: 'SeoulNamsan',
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Image.network(
                    'https://cdn.builder.io/api/v1/image/assets/TEMP/5f800e13466da1cad38235d0d6de7c0a58faefa55f031186e14335c1fc63ef73?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                    width: 35,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 65),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Precious ',
                    style: TextStyle(
                      fontFamily: 'SeoulNamsan',
                      fontSize: 50,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: 'Weight',
                    style: TextStyle(
                      fontFamily: 'Caprasimo',
                      fontSize: 50,
                      color: const Color(0xFFFF7800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 92),
            ScanButton(
              label: 'Escanear Bebês',
              onTap: () {/* Handle tap */},
            ),
            const SizedBox(height: 63),
            ScanButton(
              label: 'Escanear Balança',
              onTap: () {/* Handle tap */},
            ),
            const SizedBox(height: 63),
            ScanButton(
              label: 'Trocar de Balança',
              onTap: () {/* Handle tap */},
            ),
            const Spacer(),
            const NavBar(),
          ],
        ),
      ),
    );
  }
}

class ScanButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ScanButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Material(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Amaranth',
                      fontSize: 32,
                      color: Color(0xFF333333),
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

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFF7800),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(
            icon: 'https://cdn.builder.io/api/v1/image/assets/TEMP/e2c318bc33b48ec1585f05c7ba8cbd95af5d1afbef96e48358611f48341078c7?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
            label: 'Início',
            isSelected: true,
          ),
          _NavBarItem(
            icon: 'https://cdn.builder.io/api/v1/image/assets/TEMP/29de1dbc7cac1fde548f33f28173d2890fc0ba7d8906d8f01168bd2fc820cda9?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
            label: 'Bebês',
            isSelected: false,
          ),
          _NavBarItem(
            icon: 'https://cdn.builder.io/api/v1/image/assets/TEMP/e97ef89482cd19b88dc0ad25d3e530eff76b142301f33a0603353fc5ac7ef4e0?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
            label: 'Balança',
            isSelected: false,
          ),
          _NavBarItem(
            icon: 'https://cdn.builder.io/api/v1/image/assets/TEMP/94ddf911fdcdbd50a53596ee5242f256ad93a552e09e8b27cea003b30604dd9a?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
            label: 'Histórico',
            isSelected: false,
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isSelected;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.network(
          icon,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 4),
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