// Pin assignments for each motor
int DirPin_specimen = 2;
int StepPin_specimen = 3;
int DirPin_arm = 4;
int StepPin_arm = 5;
int EndstopPin_arm = 10;
int DirPin_cam = 6;
int StepPin_cam = 7;
int EndstopPin_cam = 11;

int motorIndicesDir[3] = {DirPin_specimen, DirPin_arm, DirPin_cam};
int motorIndicesStep[3] = {StepPin_specimen, StepPin_arm, StepPin_cam};

int endstop2Pin = 10;
int endstop3Pin = 10; // 11;

int motorPositions[3] = {0, 0, 0};  // Current motor positions (steps)
int motorMicrostepping[3] = {8, 1, 1};  // Microstepping (1/x) - deprecated but still in use
int homingStates[3] = {1, 0, 0};  // Current homing states (0 = not homed; 1 = homed)
int targetPositions[4] = {0, 0, 0}; // Target positions
int stepsPerRevolution = 200;  // Steps per revolution for the motor

int delay_base = 500;



void setup() {
  // Set step and direction pins as output
  pinMode(DirPin_specimen, OUTPUT);
  pinMode(StepPin_specimen, OUTPUT);
  pinMode(DirPin_arm, OUTPUT);
  pinMode(StepPin_arm, OUTPUT);
  pinMode(EndstopPin_arm, INPUT_PULLUP); // Enable pull-up resistor
  pinMode(DirPin_cam, OUTPUT);
  pinMode(StepPin_cam, OUTPUT);
  pinMode(EndstopPin_cam, INPUT_PULLUP); // Enable pull-up resistor

  // Set board LED pin as output
  pinMode(LED_BUILTIN, OUTPUT);

  // Set endstop pins as input with pullup resistors
  pinMode(endstop2Pin, INPUT_PULLUP);
  pinMode(endstop3Pin, INPUT_PULLUP);
  
  Serial.begin(115200);  // Start serial communication
}


void loop() {
  if (Serial.available()) {
    char command = Serial.read();  // Get command from Processing
    
    if (command == '1') {
      moveMotor(0,200);
    }
    if (command == '2') {
      moveMotor(0,-200);
    }
    if (command == '3') {
      moveMotor(1,200);
    }
    if (command == '4') {
      moveMotor(1,-200);
    }
    if (command == '5') {
      moveMotor(2,200);
    }
    if (command == '6') {
      moveMotor(2,-200);
    }

    
    if (command == '7') {
      homeMotor(0);
    }
  }
}

void homeMotor(int motorIndex){
  // Move until the endstop is triggered
  while (digitalRead(EndstopPin_arm) == LOW) { // LOW means not triggered
    moveMotor(motorIndex, -1);
  }
  motorPositions[motorIndex] = 0;
  sendMotorPositions();
  homingStates[motorIndex] = 1;
  sendHomingStates();
}

void moveMotor(int motorIndex, int steps) {
  // Serial.println(steps);
  if(steps > 0){
    digitalWrite(motorIndicesDir[motorIndex], HIGH);
    motorPositions[motorIndex] = motorPositions[motorIndex]+steps;
  } else{
    digitalWrite(motorIndicesDir[motorIndex], LOW);
    motorPositions[motorIndex] = motorPositions[motorIndex]+steps;
    steps = abs(steps);
  }

  sendMotorPositions();

  int delay_steps = round(delay_base/motorMicrostepping[motorIndex]);
  for (int i = 0; i < steps; i++) {
    digitalWrite(motorIndicesStep[motorIndex], HIGH);  // Step pin HIGH
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
    digitalWrite(motorIndicesStep[motorIndex], LOW);   // Step pin LOW
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  }
}

// Send motor positions to Processing
void sendMotorPositions() {
  Serial.print(0);
  Serial.print(',');
  Serial.print(motorPositions[0]);
  Serial.print(',');
  Serial.print(motorPositions[1]);
  Serial.print(',');
  Serial.println(motorPositions[2]);
}

// Send homing states to Processing
void sendHomingStates() {
  Serial.print(1);
  Serial.print(',');
  Serial.print(homingStates[0]);
  Serial.print(',');
  Serial.print(homingStates[1]);
  Serial.print(',');
  Serial.println(homingStates[2]);
}
// // Function to print an integer array
// int arraySize = sizeof(motorPositions) / sizeof(motorPositions[0]);  // Calculate array sizeprintArray(motorPositions, arraySize);
// void printArray(int arr[], int size) {
//   for (int i = 0; i < size; i++) {
//     Serial.print(arr[i]);
//     if (i < size - 1) {
//       Serial.print(", ");  // Add a comma between elements
//     }
//   }
//   Serial.println();  // Add a newline at the end
// }