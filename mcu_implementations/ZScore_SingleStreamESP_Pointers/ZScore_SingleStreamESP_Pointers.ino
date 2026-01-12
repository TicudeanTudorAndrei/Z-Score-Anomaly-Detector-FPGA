#include <Arduino.h>
#include <math.h>

#define N 64  // Window size

float temp[N] = {0};  // Circular buffer
int head = 0, count = 0;
float mean = 0.0f, s = 0.0f;
float sum = 0.0f, sumSq = 0.0f;
double frequencyMhz;
double clockPeriod;
float z;

void setup() {
  Serial.begin(115200);

  frequencyMhz = ESP.getCpuFreqMHz();
  Serial.print("ESP32 CPU Frequency (MHz): ");
  Serial.println(frequencyMhz);

  clockPeriod = (1.0 / frequencyMhz) * 1000;  // Convert to nanoseconds
  Serial.print("CPU Clock Period (ns): ");
  Serial.println(clockPeriod);
}

void updateWindow(float t) {
  if (count < N) {
    // Buffer not full yet
    temp[head] = t;
    sum += t;
    sumSq += t * t;
    count++;
  } else {
    // Buffer full: Remove oldest, add new
    int oldestIndex = (head + 1) % N;
    float oldestT = temp[oldestIndex];

    sum -= oldestT;
    sumSq -= oldestT * oldestT;

    temp[head] = t;
    sum += t;
    sumSq += t * t;
  }

  head = (head + 1) % N;  // Move head forward
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

void loop() {
  float t = 1 + (random(1, 5)); // Random Temperature Value

  if (random(1, 100) < 10) {  // 10% chance of anomaly
    t = 50 + (random(1, 50));
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
