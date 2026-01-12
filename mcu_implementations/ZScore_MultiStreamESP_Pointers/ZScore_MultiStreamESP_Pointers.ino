#include <Arduino.h>
#include <math.h>

#define N 64
#define STREAM_COUNT 188
struct StreamData {
  float temp[N] = {0};  // Circular buffer
  int head = 0, count = 0;
  float sum = 0.0f, sumSq = 0.0f;
  float mean = 0.0f, s = 0.0f;
};

StreamData streams[STREAM_COUNT];
double frequencyMhz;
double clockPeriod;
float z;
unsigned long totalTime = 0;
unsigned long sampleCount = 0;

void setup() {
  Serial.begin(115200);
  frequencyMhz = ESP.getCpuFreqMHz();
  Serial.print("ESP32 CPU Frequency (MHz): ");
  Serial.println(frequencyMhz);

  clockPeriod = (1.0 / frequencyMhz) * 1000;  // Convert to nanoseconds
  Serial.print("CPU Clock Period (ns): ");
  Serial.println(clockPeriod);
}

void updateWindow(StreamData &stream, float t) {
  if (stream.count < N) {
    // Buffer not full yet
    stream.temp[stream.head] = t;
    stream.sum += t;
    stream.sumSq += t * t;
    stream.count++;
  } else {
    // Buffer full: Remove oldest, add new
    int oldestIndex = (stream.head + 1) % N;
    float oldestT = stream.temp[oldestIndex];

    stream.sum -= oldestT;
    stream.sumSq -= oldestT * oldestT;

    stream.temp[stream.head] = t;
    stream.sum += t;
    stream.sumSq += t * t;
  }

  stream.head = (stream.head + 1) % N;  // Move head forward
}

bool zScore(StreamData &stream, float t) {
  updateWindow(stream, t);

  if (stream.count < N) {
    return false;
  }

  // Compute mean and standard deviation efficiently
  stream.mean = stream.sum / N;
  stream.s = sqrt((stream.sumSq / N) - (stream.mean * stream.mean));

  // Avoid division by zero
  if (stream.s == 0) {
    z = 0;
    return false;
  }

  // Z-score calculation
  z = (t - stream.mean) / stream.s;

  return (z > 3.0f || z < -3.0f);
}

void loop() {
  static int currentStream = 0;

  float t = random(1, 5);  // Random temperature value
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
}
