import 'package:flutter/material.dart';

class ScaleDetailsScreen extends StatelessWidget {
  final String userName;
  final String scaleId;
  final bool isActive;
  final String babyId;
  final String macAddress;

  const ScaleDetailsScreen({
    super.key,
    required this.userName,
    required this.scaleId,
    required this.isActive,
    required this.babyId,
    required this.macAddress,
  });

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
                    'Olá, $userName',
                    style: const TextStyle(
                      fontFamily: 'SeoulNamsan CM',
                      fontSize: 32,
                    ),
                  ),
                  Image.asset(
                    'assets/images/profile.png',
                    width: 35,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Selecione o ID da balança',
                          style: TextStyle(
                            fontFamily: 'Baloo 2',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Image.asset(
                          'assets/images/dropdown.png',
                          width: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ScaleStatusWidget(isActive: isActive),
                  const SizedBox(height: 20),
                  BabyLinkWidget(babyId: babyId),
                  const SizedBox(height: 20),
                  MacAddressWidget(macAddress: macAddress),
                ],
              ),
            ),
            const Spacer(),
            const NavigationBarWidget(),
          ],
        ),
      ),
    );
  }
}

class ScaleStatusWidget extends StatelessWidget {
  final bool isActive;

  const ScaleStatusWidget({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Estado da Balança',
          style: TextStyle(
            fontFamily: 'Actor',
            fontSize: 33,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          width: 361,
          decoration: BoxDecoration(
            color: const Color(0xFF4D965A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black),
          ),
          child: const Text(
            'Ativa',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 29,
              fontWeight: FontWeight.w800,
              color: Color(0xFFF8F8F8),
            ),
          ),
        ),
      ],
    );
  }
}

class BabyLinkWidget extends StatelessWidget {
  final String babyId;

  const BabyLinkWidget({
    super.key,
    required this.babyId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'RH do bebê vinculado',
          style: TextStyle(
            fontFamily: 'Actor',
            fontSize: 33,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 28,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black),
              ),
              child: Text(
                babyId,
                style: const TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF333333),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.fromLTRB(19, 8, 19, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFFA973F),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 6,
                      ),
                    ),
                  ),
                  const Text(
                    'Desvincular',
                    style: TextStyle(
                      fontFamily: 'Jost',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MacAddressWidget extends StatelessWidget {
  final String macAddress;

  const MacAddressWidget({
    super.key,
    required this.macAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Mac Address',
          style: TextStyle(
            fontFamily: 'Actor',
            fontSize: 33,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 44,
            vertical: 28,
          ),
          width: 361,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black),
          ),
          child: Text(
            macAddress,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Jost',
              fontSize: 29,
              fontWeight: FontWeight.w800,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}

class NavigationBarWidget extends StatelessWidget {
  const NavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
      color: const Color(0xFFFF7800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('Início', 'assets/images/home.png', false),
          _buildNavItem('Bebês', 'assets/images/babies.png', false),
          _buildNavItem('Balança', 'assets/images/scale.png', true),
          _buildNavItem('Histórico', 'assets/images/history.png', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, String imagePath, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 40,
          height: 40,
        ),
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
