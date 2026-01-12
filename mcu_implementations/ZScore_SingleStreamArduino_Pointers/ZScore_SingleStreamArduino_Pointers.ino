#include <Arduino.h>
#include <math.h>

#define N 64

float temp[N] = {0}; // Circular buffer
int head = 0, count = 0;
float mean = 0.0f, s = 0.0f, ssq = 0.0f;
double frequencyMhz;
long frequencyHz;
double clockPeriod;
float z;
float sum = 0.0f, sumSq = 0.0f;

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

void updateWindow(float t) {
  if (count < N) {
    // Buffer not yet full
    temp[head] = t;
    sum += t;
    sumSq += t * t;
    count++;
  } else {
    // Buffer is full: Remove oldest value, add new value
    int oldestIndex = (head + 1) % N;
    float oldestT = temp[oldestIndex];

    sum -= oldestT;
    sumSq -= oldestT * oldestT;

    temp[head] = t;
    sum += t;
    sumSq += t * t;
  }

  head = (head + 1) % N; // Move the head forward
}

bool zScore(float t) {
  updateWindow(t);

  if (count < N) {
    return false;
  }

  // Compute mean and standard deviation efficiently
  mean = sum / N;
  s = sqrt((sumSq / N) - (mean * mean));

  // Avoid division by zero
  if (s == 0) {
    z = 0;
    return false;
  }

  // Z-score calculation
  z = (t - mean) / s;

  return (z > 3.0f || z < -3.0f);
}
