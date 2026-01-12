#include <Arduino.h>
#include <math.h>

#define N 64
#define STREAM_COUNT 2

struct StreamData {
  float temp[N];
  int count = 0;
  float mean = 0.0f, s = 0.0f, ssq = 0.0f;
  float oldestT = 0.0f;
};

StreamData streams[STREAM_COUNT];
double frequencyMhz;
long frequencyHz;
double clockPeriod;
float z;
unsigned long totalTime = 0;
unsigned long sampleCount = 0;

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

void shiftWindow(StreamData &stream, float t) {
  stream.oldestT = stream.temp[0];
  for (int i = 0; i < N - 1; i++) {
    stream.temp[i] = stream.temp[i + 1];
  }
  stream.temp[N - 1] = t;
}

void updateWindow(StreamData &stream, float t) {
  if (stream.count < N) {
    stream.temp[stream.count] = t;
  } else {
    shiftWindow(stream, t);
  }
  stream.count++;
}

bool zScore(StreamData &stream, float t) {
  updateWindow(stream, t);

  if (stream.count < N) {
    return false;
  }

  // Mean
  stream.mean = 0.0f;
  for (int i = 0; i < N; i++) {
    stream.mean += stream.temp[i];
  }
  stream.mean /= N;

  // Standard Deviation
  stream.ssq = 0.0f;
  for (int i = 0; i < N; i++) {
    float diff = stream.temp[i] - stream.mean;
    stream.ssq += diff * diff;
  }
  stream.s = sqrt(stream.ssq / N);

  // Z-score
  z = (t - stream.mean) / stream.s;

  return (z > 3.0f || z < -3.0f);
}

void loop() {
  static int currentStream = 0;

  float t = random(1, 5); // Random value
  if (sampleCount > (N * STREAM_COUNT) && random(0, 100) < 10) {  // 10% chance of anomaly
    t = random(80, 100);
  }

  unsigned long timeBefore = micros();
  bool anomaly = zScore(streams[currentStream], t);
  unsigned long timeAfter = micros();

  unsigned long elapsedTime = timeAfter - timeBefore;
  sampleCount++;
  if (sampleCount > (N * STREAM_COUNT)) {
    totalTime += elapsedTime;
  }

  Serial.print("Stream ID: ");
  Serial.print(currentStream);
  Serial.print(" | Temp: ");
  Serial.print(t);
  Serial.print(" | Z-Score: ");
  Serial.print(z);
  Serial.print(" | Anomaly: ");
  Serial.print(anomaly);
  Serial.print(" | Z-score time (us): ");
  Serial.print(elapsedTime);

  if (sampleCount > (N * STREAM_COUNT)) {
    Serial.print(" | Average Z-score time (us): ");
    Serial.println(totalTime / (sampleCount - N * STREAM_COUNT));
  } else {
    Serial.println();
  }

  currentStream = (currentStream + 1) % STREAM_COUNT;
  delay(500);
}
