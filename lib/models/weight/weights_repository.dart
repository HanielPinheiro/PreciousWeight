import 'dart:math';
import 'weight.dart';

class WeightRepository {
  static List<WeightModel> generateWeights() {
    List<WeightModel> weights = [];
    int idCounter = 1;
    DateTime startDate = DateTime(2024, 6, 1);
    Random random = Random();

    for (int patientId = 0; patientId < 15; patientId++) {
      for (int scaleId = 0; scaleId < 15; scaleId++) {
        weights.add(WeightModel(
          id: idCounter++,
          date: startDate.add(Duration(days: idCounter - 1)),
          scaleId: scaleId,
          patientId: patientId,
          weight: 750 + random.nextInt(2751), // Random weight between 750 and 3500
        ));
      }
    }
    return weights;
  }

  static final List<WeightModel> weights = generateWeights();
}
