// Pin assignments for each motor
int DirPin_specimen_rot = 2;
int StepPin_specimen_rot = 3;
int DirPin_arm = 4;
int StepPin_arm = 5;
int EndstopPin_arm = 10;
int DirPin_cam = 6;
int StepPin_cam = 7;
int EndstopPin_cam = 10;
int DirPin_specimen_height = 8;
int StepPin_specimen_height = 9;
int EndstopPin_specimen_height = 10;

int motorIndicesDir[4] = {DirPin_specimen_rot, DirPin_arm, DirPin_cam, DirPin_specimen_height};
int motorIndicesStep[4] = {StepPin_specimen_rot, StepPin_arm, StepPin_cam, StepPin_specimen_height};


int motorPositions[4] = {0, 0, 0, 0};  // Current motor positions (steps)
int motorMicrostepping[4] = {1, 1, 1, 1};  // Microstepping (1/x) - deprecated but still in use
int homingStates[4] = {1, 0, 0, 0};  // Current homing states (0 = not homed; 1 = homed)
// int targetPositions[4] = {0, 0, 0}; // Target positions
float stepsPerRevolution = 200;  // Steps per revolution for the motor

int delay_base = 500;

const int bufferSize = 64; // Maximum size of the input buffer
char inputBuffer[bufferSize]; // Buffer to hold the incoming data
int bufferIndex = 0; // Index to track the buffer position


void setup() {
  Serial.println('Setting up machine...');
  // Set step and direction pins as output
  pinMode(DirPin_specimen_rot, OUTPUT);
  pinMode(StepPin_specimen_rot, OUTPUT);
  pinMode(DirPin_arm, OUTPUT);
  pinMode(StepPin_arm, OUTPUT);
  pinMode(EndstopPin_arm, INPUT_PULLUP); // Enable pull-up resistor
  pinMode(DirPin_cam, OUTPUT);
  pinMode(StepPin_cam, OUTPUT);
  pinMode(EndstopPin_cam, INPUT_PULLUP); // Enable pull-up resistor
  pinMode(DirPin_specimen_height, OUTPUT);
  pinMode(StepPin_specimen_height, OUTPUT);
  pinMode(EndstopPin_specimen_height, INPUT_PULLUP); // Enable pull-up resistor

    // Set board LED pin as output
  pinMode(LED_BUILTIN, OUTPUT);
  
  Serial.begin(115200);  // Start serial communication
}


void loop() {
 // Check if data is available on the serial port
  while (Serial.available() > 0) {
    char receivedChar = Serial.read(); // Read one character from the serial port

    // Check for the end of the input (e.g., newline character '\n')
    if (receivedChar == '\n') {
      inputBuffer[bufferIndex] = '\0'; // Null-terminate the string
      parseAndExecuteCommand(inputBuffer); // Process the received command
      bufferIndex = 0; // Reset buffer index for the next input
    } else if (bufferIndex < bufferSize - 1) {
      inputBuffer[bufferIndex++] = receivedChar; // Add character to buffer
    } else {
      Serial.println("Input buffer overflow!");
      bufferIndex = 0; // Reset buffer index to prevent overflow
    }
  }

  
    
}

// Function to process the received command
void parseAndExecuteCommand(const char* command) {
  char commandString[16]; // To store the command part
  int number1, number2;   // To store the two numbers

  // Parse the command using sscanf
  if (sscanf(command, "%15s %d %d", commandString, &number1, &number2) == 3) {
    executeCommand(commandString, number1, number2); // Pass parsed values to a function
  } else {
    Serial.println("Invalid command format. Use: COMMAND <number1> <number2>");
  }
}

// Function to handle the parsed command and number
void executeCommand(const char* command, int value1, int value2) {
    if (strcmp(command, "ABS") == 0) {
      moveMotorTo(value1, value2);
    } else if (strcmp(command, "REL") == 0) {
      moveMotor(value1, value2);
    } else if (strcmp(command, "HOME") == 0) {
      homeMotor(value1);
    } else if (strcmp(command, "STATUS_MOTORS") == 0) {
      sendMotorPositions();
    } else if (strcmp(command, "STATUS_HOME") == 0) {
      sendHomingStates();
    } else if (strcmp(command, "RESET_SPEC_ROT") == 0) {
      motorPositions[0] = 0;
      sendMotorPositions();
    }
}

void turnLedOn() {
  Serial.println("Turning LED ON");
  digitalWrite(LED_BUILTIN, HIGH);
}

void turnLedOff() {
  Serial.println("Turning LED OFF");
  digitalWrite(LED_BUILTIN, LOW);
}

// void reportStatus() {
//   sendMotorPositions();
//   sendHomingStates();
// }

void homeMotor(int motorIndex){
  // Move until the endstop is triggered
  while (digitalRead(EndstopPin_arm) == LOW) { // LOW means not triggered
    moveMotor(motorIndex, degreesToSteps(-1, 200));
  }
  motorPositions[motorIndex] = 0;
  sendMotorPositions();
  homingStates[motorIndex] = 1;
  sendHomingStates();
}

void moveMotorTo(int motorIndex, float degrees){
  int curr_motor_position = motorPositions[motorIndex];
  float curr_motor_degrees = stepsToDegrees(curr_motor_position, 200);

  float curr_degrees_difference = degrees - curr_motor_degrees;
  moveMotor(motorIndex, curr_degrees_difference);
}

void moveMotor(int motorIndex, int degrees) {
  float target = -1;
  if(motorIndex == 0){
    Serial.print("degrees: ");
    Serial.println(degrees);
    target = degreesToSteps(degrees, 200);
    Serial.print("target: ");
    Serial.println(target);
  } else if(motorIndex == 1){
    Serial.print("degrees: ");
    Serial.println(degrees);
    target = degreesToSteps(degrees, 200);
    Serial.print("target: ");
    Serial.println(target);
  } else if(motorIndex == 2){
    Serial.print("degrees: ");
    Serial.println(degrees);
    target = degreesToSteps(degrees, 200);
    Serial.print("target: ");
    Serial.println(target);
  } else if (motorIndex == 3){
    Serial.print("degrees: ");
    Serial.println(degrees);
    target = degreesToSteps(degrees, 200);
    Serial.print("target: ");
    Serial.println(target);
  } else {
    Serial.print("Motor not defined.");
  }
  
  if(target > 0){
    digitalWrite(motorIndicesDir[motorIndex], HIGH);
    motorPositions[motorIndex] = motorPositions[motorIndex]+target;
  } else{
    digitalWrite(motorIndicesDir[motorIndex], LOW);
    motorPositions[motorIndex] = motorPositions[motorIndex]+target;
    target = abs(target);
  }

  int delay_steps = round(delay_base/motorMicrostepping[motorIndex]);
  for (int i = 0; i < target; i++) {
    digitalWrite(motorIndicesStep[motorIndex], HIGH);  // Step pin HIGH
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
    digitalWrite(motorIndicesStep[motorIndex], LOW);   // Step pin LOW
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  }

  sendMotorPositions();
}

// Send motor positions to Processing
void sendMotorPositions() {
  Serial.print(0);
  Serial.print(',');
  Serial.print(motorPositions[0]);
  Serial.print(',');
  Serial.print(motorPositions[1]);
  Serial.print(',');
  Serial.print(motorPositions[2]);
  Serial.print(',');
  Serial.println(motorPositions[3]);
}

// Send homing states to Processing
void sendHomingStates() {
  Serial.print(1);
  Serial.print(',');
  Serial.print(homingStates[0]);
  Serial.print(',');
  Serial.print(homingStates[1]);
  Serial.print(',');
  Serial.print(homingStates[2]);
  Serial.print(',');
  Serial.println(homingStates[3]);
}

// Function to convert motor steps to degrees
float stepsToDegrees(int steps, int stepsPerRevolution) {
  return (360.0 / stepsPerRevolution) * steps;
}

// Function to convert degrees to motor steps
int degreesToSteps(float degrees, int stepsPerRevolution) {
  return round((degrees / 360.0) * stepsPerRevolution);
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