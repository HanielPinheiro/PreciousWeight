import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF5C5EA3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: const [
            HeaderWidget(),
            SizedBox(height: 33),
            Text(
              'Histórico de Eventos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 37,
                fontFamily: 'Actor',
              ),
            ),
            SizedBox(height: 10),
            FilterExportBar(),
            EventList(),
            NavigationBar(),
          ],
        ),
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 54, 25, 13),
      color: const Color(0xFFF8F8F8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Olá, Haniel Nunes',
                style: TextStyle(
                  fontFamily: 'SeoulNamsan CM',
                  fontSize: 32,
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
          Image.network(
            'https://cdn.builder.io/api/v1/image/assets/TEMP/5f800e13466da1cad38235d0d6de7c0a58faefa55f031186e14335c1fc63ef73?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
            width: 35,
            height: 35 * 1.09,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class FilterExportBar extends StatelessWidget {
  const FilterExportBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 27, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black),
              ),
              child: Row(
                children: [
                  const Text(
                    'Filtrar',
                    style: TextStyle(
                      fontFamily: 'Baloo 2',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Image.network(
                    'https://cdn.builder.io/api/v1/image/assets/TEMP/dd63a194c1cbca0dc5d0f7b17a29f821f169ab5bf55deb8d149812439a85278a?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                    width: 37,
                    height: 37,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black),
              ),
              child: Row(
                children: [
                  const Text(
                    'Exportar',
                    style: TextStyle(
                      fontFamily: 'Baloo 2',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Image.network(
                    'https://cdn.builder.io/api/v1/image/assets/TEMP/81cb9d972305a944325286bbf8322cbb866b8fa8f17757640b50d807e55e0ec1?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
                    width: 41,
                    height: 41 * 0.98,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventList extends StatelessWidget {
  const EventList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      width: 361,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '-> 29/12/2024 - 23h45: RH 1250498 vinculado à balança 32 (MacAddres: 00-B0-D0-63-C2-26).',
                    style: TextStyle(
                      fontFamily: 'Alegreya',
                      fontSize: 33,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 39),
                  Text(
                    '-> 29/12/2024 - 20h45: RH 1250492 é desvinculado da balança 32 (MacAddres: 00-B0-',
                    style: TextStyle(
                      fontFamily: 'Alegreya',
                      fontSize: 33,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE1E1E1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  height: 119,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8B8B8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 403),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationBar extends StatelessWidget {
  const NavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
      color: const Color(0xFFFF7800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
              'Início',
              'https://cdn.builder.io/api/v1/image/assets/TEMP/5fd7b9eb3883c28d233d097991688c3044f06dcce332286bcb337d71a59aa6aa?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
              false),
          _buildNavItem(
              'Bebês',
              'https://cdn.builder.io/api/v1/image/assets/TEMP/29de1dbc7cac1fde548f33f28173d2890fc0ba7d8906d8f01168bd2fc820cda9?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
              false),
          _buildNavItem(
              'Balança',
              'https://cdn.builder.io/api/v1/image/assets/TEMP/9de94528ab3708b59271b8455b7754df18ae324eb73499db5b01758112af6a07?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
              false),
          _buildNavItem(
              'Histórico',
              'https://cdn.builder.io/api/v1/image/assets/TEMP/699c5c54481096e246d710ae13cad3c00c37c72502322c2610e5b03096ca4620?placeholderIfAbsent=true&apiKey=5fa504f45304401ab7e7738672da76d4',
              true),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, String imageUrl, bool isSelected) {
    return Column(
      children: [
        Image.network(
          imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
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
