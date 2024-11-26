// define motors to control
int motors_to_control = 3;

// Pin assignments for each motor
int motor1DirPin = 2;
int motor1StepPin = 3;
int motor2DirPin = 4;
int motor2StepPin = 5;
int motor3DirPin = 6;
int motor3StepPin = 7;
// int motor4DirPin = 8;
// int motor4StepPin = 9;

int endstop1Pin = 10;
int endstop2Pin = 10; // 11;
int endstop3Pin = 10; // 12;
// int endstop4Pin = 10; // 13;

int motorPositions[3] = {0, 0, 0};  // Current motor positions (steps)
int motorMicrostepping[3] = {8, 1, 1};  // Microstepping (1/x) - deprecated but still in use
int homingStates[3] = {0, 0, 1};  // Current homing states (0 = not homed; 1 = homed)
int targetPositions[4] = {0, 0, 0}; // Target positions
int stepsPerRevolution = 200;  // Steps per revolution for the motor
int motorMaxPosition = 10000;   // Max position in steps

int delay_base = 100;
float step_mode = 1; 
int delay_steps = round(delay_base/step_mode);

void setup() {
  // Set step and direction pins as output
  pinMode(motor1DirPin, OUTPUT);
  pinMode(motor1StepPin, OUTPUT);
  pinMode(motor2DirPin, OUTPUT);
  pinMode(motor2StepPin, OUTPUT);
  pinMode(motor3DirPin, OUTPUT);
  pinMode(motor3StepPin, OUTPUT);
  // pinMode(motor4DirPin, OUTPUT);
  // pinMode(motor4StepPin, OUTPUT);

  // Set board LED pin as output
  pinMode(LED_BUILTIN, OUTPUT);

  // Set endstop pins as input with pullup resistors
  pinMode(endstop1Pin, INPUT_PULLUP);
  pinMode(endstop2Pin, INPUT_PULLUP);
  // pinMode(endstop3Pin, INPUT_PULLUP);
  // pinMode(endstop4Pin, INPUT_PULLUP);
  
  Serial.begin(115200);  // Start serial communication
}

void loop() {
  // Check if data is available on the serial port
  if (Serial.available()) {
    char command = Serial.read();  // Get command from Processing
    
    // Homing procedure
    if (command == 'h') {
      homeMotors();
    }
    
    // Update target positions based on received data (e.g., slider values)
    if (command == 's') {
      for (int i = 0; i < motors_to_control; i++) {
        targetPositions[i] = Serial.parseInt();  // Read positions from Processing
        if (targetPositions[i] > motorMaxPosition) {
          targetPositions[i] = motorMaxPosition;  // Cap target position to max
        }
      }
    }
  }
  
  // Update motor positions and handle movement
  for (int i = 0; i < motors_to_control; i++) {
    moveToTarget(i);
  }

  // Send updated positions back to Processing
  sendMotorPositions();
}

// Homing each motor by moving until the endstop is hit
void homeMotors() {
  for (int i = 0; i < motors_to_control; i++) {
    while (digitalRead(endstop1Pin + i) == HIGH) {  // Move until endstop is triggered
      setMotorDirection(i, LOW);  // Move motor backward
      stepMotor(i);
    }
    motorPositions[i] = 0;  // Reset position to 0 (home)
    homingStates[i] =  1;  // Reset position to 0 (home)
  }
  // Send new homing states to Processing
  sendHomingStates();
}

// Move motor to the target position
void moveToTarget(int motorIndex) {
  digitalWrite(LED_BUILTIN, HIGH);  // turn the LED on 
  if (motorPositions[motorIndex] < targetPositions[motorIndex]) {
    setMotorDirection(motorIndex, HIGH);  // Move forward
    stepMotor(motorIndex);
    motorPositions[motorIndex]++;
  } else if (motorPositions[motorIndex] > targetPositions[motorIndex]) {
    setMotorDirection(motorIndex, LOW);   // Move backward
    stepMotor(motorIndex);
    motorPositions[motorIndex]--;
  }
  digitalWrite(LED_BUILTIN, LOW);  // turn the LED off
}

// Set the motor direction
void setMotorDirection(int motorIndex, int direction) {
  digitalWrite(motor1DirPin + motorIndex * 2, direction);  // Set direction pin (2nd pin for each motor)
}

// Step the motor once
void stepMotor(int motorIndex) {
  // int current_microstepping = 1;
  // for (int i = 0; i < current_microstepping; i++) {
    digitalWrite(motor1StepPin + motorIndex * 2, HIGH);  // Step pin HIGH
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
    digitalWrite(motor1StepPin + motorIndex * 2, LOW);   // Step pin LOW
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  // }
}

// Send motor positions to Processing
void sendMotorPositions() {
  Serial.print(0);
  Serial.print(',');
  Serial.print(motorPositions[0]);
  Serial.print(',');
  Serial.print(motorPositions[1]);
  Serial.print(',');
  // Serial.print(motorPositions[2]);
  // Serial.print(',');
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
  // Serial.print(homingStates[2]);
  // Serial.print(',');
  Serial.println(homingStates[2]);
}
