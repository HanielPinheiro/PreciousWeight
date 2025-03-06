void FastBuzzer_OneTime() {
  analogPin(BUZZER_PINOUT, 1);
  delay(FAST_DELAY);
  analogPin(BUZZER_PINOUT, 0);
}

void FastBuzzer_TwoTimes() {
  for (int i = 1; i <= 2; i++) {
    SlowBuzzer_OneTime();
    delay(FAST_DELAY);
  }
}

void FastBuzzer_ThreeTimes() {
  for (int i = 1; i <= 3; i++) {
    SlowBuzzer_OneTime();
    delay(FAST_DELAY);
  }
}

void SlowBuzzer_OneTime() {
  analogPin(BUZZER_PINOUT, 1);
  delay(SLOW_DELAY);
  analogPin(BUZZER_PINOUT, 0);
}

void SlowBuzzer_TwoTimes() {
  for (int i = 1; i <= 2; i++) {
    SlowBuzzer_OneTime();
    delay(SLOW_DELAY);
  }
}

void SlowBuzzer_ThreeTimes() {
  for (int i = 1; i <= 3; i++) {
    SlowBuzzer_OneTime();
    delay(SLOW_DELAY);
  }
}