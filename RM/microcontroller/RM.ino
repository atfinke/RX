#include "Adafruit_BluefruitLE_UART.h"
#include <Adafruit_CircuitPlayground.h>

// CONSTANTS

static const int VOLUME_UP_INPUT_PIN = 3;
static const int VOLUME_DOWN_INPUT_PIN = 2;

static const int VOLUME_UP_OUTPUT_PIN = 9;
static const int VOLUME_DOWN_OUTPUT_PIN = 6;

static const int ACCELEROMETER_MOVEMENT_TRIGGER_THRESHOLD = 110;
static const int ACCELEROMETER_MOVEMENT_MIN_TIME_SINCE_PRESS = 1000;
static const int ACCELEROMETER_LED_TIME = 2000;

static const int ACCELEROMETER_VOLUME_UP_LED_VALUE = 20;
static const int ACCELEROMETER_VOLUME_DOWN_LED_VALUE = 50;

static const int PRESSED_LED_VALUE = 255;

static const int STARTUP_LED_TIME = 10000;

static const bool INITIAL_SETUP = false;

// BUTTON STATE

int lastVolumeDownButtonValue = 0;
int lastVolumeUpButtonValue = 0;
int buttonValue = 0;
unsigned long pressedEndDate = 0;

// OTHER

unsigned long setupEndDate = 0;
unsigned long accelerometerEndDate = 0;
Adafruit_BluefruitLE_UART ble(Serial1, -1);

// SETUP

void setup(void)
{
  CircuitPlayground.begin();
  CircuitPlayground.setPixelColor(1, 0, 0, 20);

  if (!Serial) {
    delay(1000);
  }
  CircuitPlayground.setPixelColor(2, 0, 0, 20);

  if (Serial) {
    Serial.begin(115200);
  }
  CircuitPlayground.setPixelColor(3, 0, 0, 20);

  ble.begin(false);
  CircuitPlayground.setPixelColor(4, 0, 0, 20);

  ble.echo(false);
  CircuitPlayground.setPixelColor(5, 0, 0, 20);

  if (Serial) {
    ble.info();
  }
  CircuitPlayground.setPixelColor(6, 0, 0, 20);

  pinMode(VOLUME_DOWN_INPUT_PIN, INPUT_PULLUP);
  pinMode(VOLUME_UP_INPUT_PIN, INPUT_PULLUP);
  CircuitPlayground.setPixelColor(7, 0, 0, 20);

  pinMode(VOLUME_DOWN_OUTPUT_PIN, OUTPUT);
  pinMode(VOLUME_UP_OUTPUT_PIN, OUTPUT);
  CircuitPlayground.setPixelColor(8, 0, 0, 20);

  if (INITIAL_SETUP) {
    if (ble.factoryReset()) {
      Serial.println("success: factoryReset");
    } else {
      Serial.println("error: factoryReset");
    }

    if (ble.sendCommandCheckOK(F("AT+BleHIDEn=On"))) {
      Serial.println("success: hid");
    } else {
      Serial.println("error: hid");
    }

    if (ble.reset()) {
      Serial.println("success: reset");
    } else {
      Serial.println("error: reset");
    }

    if (ble.sendCommandCheckOK(F("AT+HWModeLED=disable"))) {
      Serial.println("success: led");
    } else {
      Serial.println("error: led");
    }

    if (ble.sendCommandCheckOK(F("AT+GAPDEVNAME=RM" ))) {
      Serial.println("success: name");
    } else {
      Serial.println("error: name");
    }
  }

  setupEndDate = millis();

}

// MAIN

void loop(void)
{
  checkStartup();
  checkAccelerometer();
  checkVolumeUpButton(true);
  checkVolumeUpButton(false);
}

// HELPERS

void checkStartup(void) {
  if (setupEndDate == 0) {
    return;
  }
  unsigned long duration = millis() - setupEndDate;
  if (duration > STARTUP_LED_TIME) {
    setupEndDate = 0;
    for (int i = 1; i < 9; i++) {
      CircuitPlayground.setPixelColor(i, 0, 0, 0);
    }
  }
}

void checkAccelerometer(void) {
  float motionX = CircuitPlayground.motionX();
  float motionY = CircuitPlayground.motionY();
  float motionZ = CircuitPlayground.motionZ();

  int composite = int(motionX * motionX + motionY * motionY + motionZ * motionZ);
  if (composite > ACCELEROMETER_MOVEMENT_TRIGGER_THRESHOLD) {
    if (pressedEndDate != 0) {
      if (millis() - pressedEndDate > ACCELEROMETER_MOVEMENT_MIN_TIME_SINCE_PRESS) {
        pressedEndDate = 0;
      } else {
        return;
      }
    }
    accelerometerEndDate = millis();
    analogWrite(VOLUME_UP_OUTPUT_PIN, ACCELEROMETER_VOLUME_UP_LED_VALUE);
    analogWrite(VOLUME_DOWN_OUTPUT_PIN, ACCELEROMETER_VOLUME_DOWN_LED_VALUE);
  } else if (accelerometerEndDate != 0) {
    unsigned long duration = millis() - accelerometerEndDate;
    if (duration > ACCELEROMETER_LED_TIME) {
      accelerometerEndDate = 0;
    }
  }
}

void checkVolumeUpButton(bool isVolumeUp) {
  int inputPin = isVolumeUp ? VOLUME_UP_INPUT_PIN : VOLUME_DOWN_INPUT_PIN;
  int outputPin = isVolumeUp ? VOLUME_UP_OUTPUT_PIN : VOLUME_DOWN_OUTPUT_PIN;
  int cpOutputPin = isVolumeUp ? 9 : 0;
  int& lastValueRef = isVolumeUp ? lastVolumeUpButtonValue : lastVolumeDownButtonValue;

  // check if button just pressed
  int buttonValue = (digitalRead(inputPin) - 1) * -1;
  if (buttonValue == 1 && lastValueRef == 0) {
    const char* command = isVolumeUp ? "+" : "-";
    String message = "AT+BLEHIDCONTROLKEY=VOLUME" + String(command);
    ble.println(message);
  }
  CircuitPlayground.setPixelColor(cpOutputPin, 0, 0, 20 * buttonValue);

  // 1) Turn button led on if pressed
  // 2) Turn button led off if not pressed and not shaking
  // 3) Turn button led to shaking value if not pressed and  shaking
  if (lastValueRef == 1) {
    analogWrite(outputPin, PRESSED_LED_VALUE);
    pressedEndDate = millis();
  } else if (accelerometerEndDate == 0) {
    analogWrite(outputPin, 0);
  } else {
    int value = isVolumeUp ? ACCELEROMETER_VOLUME_UP_LED_VALUE : ACCELEROMETER_VOLUME_DOWN_LED_VALUE;
    analogWrite(outputPin, value);
  }

  lastValueRef = buttonValue;
}
