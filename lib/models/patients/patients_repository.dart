import 'package:flutter/material.dart';
import '../../models/patients/patient.dart';
import '../../models/scales/scales_repository.dart';
import '../../repository/widgets/elements.dart';
import '../../views/babies/babies_details.dart';
import '../weight/weights_repository.dart';

class BabiesRepository {
  static List<PatientModel> babies = [
    PatientModel(id: 1,hospitalRegister: 12354684,name: 'Carlos Joaquem da Silva',birthDate: DateTime(2025, 1, 2),weight: 1052.25,isActive: true,scale: ScalesRepository.scales[0],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[0].id).toList()),
    PatientModel(id: 2,hospitalRegister: 12354685,name: 'Maria Eduarda Almeida',birthDate: DateTime(2025, 2, 15), weight: 3200.50,isActive: true,scale: ScalesRepository.scales[1],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[1].id).toList()),
    PatientModel(id: 3,hospitalRegister: 12354686,name: 'João Pedro Souza',birthDate: DateTime(2025, 3, 10),weight: 2800.75,isActive: false,scale: ScalesRepository.scales[2],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[2].id).toList()),
    PatientModel(id: 4,hospitalRegister: 12354687,name: 'Ana Clara Fernandes',birthDate: DateTime(2025, 4, 5),weight: 2950.00,isActive: true,scale: ScalesRepository.scales[3],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[3].id).toList()),
    PatientModel(id: 5,hospitalRegister: 12354688,name: 'Lucas Gabriel Oliveira',birthDate: DateTime(2025, 5, 20),weight: 3100.25,isActive: true,scale: ScalesRepository.scales[4],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[4].id).toList()),
    PatientModel(id: 6,hospitalRegister: 12354689,name: 'Isabella Santos',birthDate: DateTime(2025, 6, 12),weight: 2650.50,isActive: false,scale: ScalesRepository.scales[5],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[5].id).toList()),
    PatientModel(id: 7,hospitalRegister: 12354690,name: 'Miguel Costa',birthDate: DateTime(2025, 7, 8),weight: 3400.75,isActive: true,scale: ScalesRepository.scales[6],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[6].id).toList()),
    PatientModel(id: 8,hospitalRegister: 12354691,name: 'Sophia Rodrigues',birthDate: DateTime(2025, 8, 25),weight: 2750.00,isActive: true,scale: ScalesRepository.scales[7],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[7].id).toList()),
    PatientModel(id: 9,hospitalRegister: 12354692,name: 'Arthur Martins',birthDate: DateTime(2025, 9, 18),weight: 2900.25,isActive: false,scale: ScalesRepository.scales[8],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[8].id).toList()),
    PatientModel(id: 10,hospitalRegister: 12354693,name: 'Helena Pereira',birthDate: DateTime(2025, 10, 30),weight: 3150.50,isActive: true,scale: ScalesRepository.scales[9],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[9].id).toList()),
    PatientModel(id: 11,hospitalRegister: 12354694,name: 'Davi Lima',birthDate: DateTime(2025, 11, 22),weight: 3000.75,isActive: true,scale: ScalesRepository.scales[10],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[10].id).toList()),
    PatientModel(id: 12,hospitalRegister: 12354695,name: 'Valentina Gomes',birthDate: DateTime(2025, 12, 14),weight: 2850.00,isActive: false,scale: ScalesRepository.scales[11],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[11].id).toList()),
    PatientModel(id: 13,hospitalRegister: 12354696,name: 'Bernardo Ribeiro',birthDate: DateTime(2026, 1, 7),weight: 3300.25,isActive: true,scale: ScalesRepository.scales[12],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[12].id).toList()),
    PatientModel(id: 14,hospitalRegister: 12354697,name: 'Laura Carvalho',birthDate: DateTime(2026, 2, 19),weight: 2700.50,isActive: true,scale: ScalesRepository.scales[13],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[13].id).toList()),
    PatientModel(id: 15,hospitalRegister: 12354698,name: 'Gustavo Henrique Silva',birthDate: DateTime(2026, 3, 11),weight: 3050.75,isActive: false,scale: ScalesRepository.scales[14],
        historicWeight: WeightRepository.weights.where((weight) => weight.scaleId == ScalesRepository.scales[14].id).toList())];

  static List<Widget> GetBabiesLikeCards(BuildContext context) {
    return babies.map((_baby) {
      return ElementsOfViews.CardToList(Icons.baby_changing_station, _baby.name!, 'Último peso: ${_baby.weight}g', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BabiesDetails(baby: _baby)),
        );
      });
    }).toList();
  }
}
