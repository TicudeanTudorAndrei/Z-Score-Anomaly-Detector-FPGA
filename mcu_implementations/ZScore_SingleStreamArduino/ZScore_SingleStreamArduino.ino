#include <Arduino.h>
#include <math.h>

#define N 64

float temp[N], oldestT = 0.0f;
int count = 0;
float mean = 0.0f, s = 0.0f, ssq = 0.0f;
double frequencyMhz;
long frequencyHz;
double clockPeriod;
float z;

void setup() {
  Serial.begin(9600);
  frequencyHz = F_CPU;
  frequencyMhz = frequencyHz / 1000000;
  Serial.print("CPU frequency (Mhz): ");
  Serial.println(frequencyMhz);

  clockPeriod = 1.0 / frequencyMhz * 1000;
  Serial.print("CPU clock period (ns): ");
  Serial.println(clockPeriod);
}

void loop() {
  float t = random(1, 5); // Random Temperature Value

  if (random(0, 100) < 10) {  // 10% chance of anomaly
    t = random(50, 100);
  }

  unsigned long timeBefore = micros();
  bool anomaly = zScore(t);
  unsigned long timeAfter = micros();

  Serial.print("Temp: ");
  Serial.print(t);
  Serial.print(" | Z-Score: ");
  Serial.print(z);
  Serial.print(" | Anomaly: ");
  Serial.print(anomaly);
  Serial.print(" | Z-score time (us): ");
  Serial.println(timeAfter - timeBefore);

  
}

void shiftWindow(float t) {
  oldestT = temp[0];
  for (int i = 0; i < N - 1; i++) {
    temp[i] = temp[i + 1];
  }
  temp[N - 1] = t;
}

void updateWindow(float t) {
  if (count < N) {
    temp[count] = t;
  } else {
    shiftWindow(t);
  }
  count++;
}

bool zScore(float t) {
  updateWindow(t);

  if (count < N) {
    return false;
  }

  // Mean
  mean = 0.0f;
  for (int i = 0; i < N; i++) {
    mean += temp[i];
  }
  mean /= N;

  // Standard Deviation
  ssq = 0.0f;
  for (int i = 0; i < N; i++) {
    float diff = temp[i] - mean;
    ssq += diff * diff;
  }
  s = sqrt(ssq / N);

  // Z-score
  z = (t - mean) / s;

  return (z > 3.0f || z < -3.0f);
}
