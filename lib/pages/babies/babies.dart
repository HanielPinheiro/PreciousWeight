import 'package:flutter/material.dart';

class BabyWeightScreen extends StatelessWidget {
  const BabyWeightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5C5EA3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: const [
              HeaderSection(),
              BabySelector(),
              RecentWeight(),
              WeightChart(),
              NavigationBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Image.asset(
            'assets/profile_icon.png',
            width: 35,
            height: 35 / 1.09,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class BabySelector extends StatelessWidget {
  const BabySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 42),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selecione o RH do Bebê',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            Image.asset(
              'assets/dropdown_icon.png',
              width: 18,
              height: 18 * 1.2,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class RecentWeight extends StatelessWidget {
  const RecentWeight({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Text(
            'Pesagem Recente',
            style: TextStyle(
              fontFamily: 'Actor',
              fontSize: 33,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 11),
          padding: const EdgeInsets.symmetric(horizontal: 61, vertical: 6),
          width: 361,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.black),
          ),
          child: Text(
            '28/12/24 - 21:58\n1005 gramas\nId da Balança - 1250498',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Jost',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}

class WeightChart extends StatelessWidget {
  const WeightChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 66),
          child: Text(
            'Evolução Ponderal',
            style: TextStyle(
              fontFamily: 'Actor',
              fontSize: 33,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(13),
          width: 370,
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Image.asset(
              'assets/weight_chart.png',
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 38),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
      color: const Color(0xFFFF7800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('assets/home_icon.png', 'Início', false),
          _buildNavItem('assets/babies_icon.png', 'Bebês', true),
          _buildNavItem('assets/scale_icon.png', 'Balança', false),
          _buildNavItem('assets/history_icon.png', 'Histórico', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, bool isSelected) {
    return Column(
      children: [
        Image.asset(
          iconPath,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Baloo',
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}