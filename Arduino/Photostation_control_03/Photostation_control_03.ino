// Pin assignments for each motor
int DirPin_specimen_rot = 2;
int StepPin_specimen_rot = 3;
int EndstopPin_specimen_rot = 11; // connect directly to GND
int DirPin_specimen_height = 4;
int StepPin_specimen_height = 5;
int EndstopPin_specimen_height = 10; // connect 2nd to GND and use outer contacts (1&2) | LOW means not triggered
int DirPin_arm = 6;
int StepPin_arm = 7;
int EndstopPin_arm = 10;
int DirPin_cam = 8;
int StepPin_cam = 9;
int EndstopPin_cam = 10;

/*
0 Specimen rotation
1 Specimen height
2 Arm
3 Camera offset
*/

//                            0                         1                           2                 3
long motorIndicesDir[4] =      {DirPin_specimen_rot,     DirPin_specimen_height,     DirPin_arm,       DirPin_cam};
long motorIndicesStep[4] =     {StepPin_specimen_rot,    StepPin_specimen_height,    StepPin_arm,      StepPin_cam};
long motorIndicesEndstop[4] =  {EndstopPin_specimen_rot, EndstopPin_specimen_height, EndstopPin_arm,   EndstopPin_cam};

long motorPositions[4] = {0, 0, 0, 0};  // Current motor positions (steps)
long motorMicrostepping[4] = {32, 1, 1, 10};  // Microstepping (1/x)
long homingStates[4] = {1, 0, 0, 0};  // Current homing states (0 = not homed; 1 = homed)
long motorIndicesDelays[4] = {300, 500, 500, 300};

bool homing = false; // variable to enter and leave homing procedure

// int DelayReadOut = 10*1000;

long mm_per_rev_4 = 4;

// Function to convert motor steps to degrees
float stepsToDegrees(long steps, long stepsPerRevolution) {
  return (360.0 / stepsPerRevolution) * steps;
}

// Function to convert degrees to motor steps
long degreesToSteps(long degrees, long stepsPerRevolution) {
  return round((degrees / 360.0) * stepsPerRevolution);
}

// Function to convert motor steps to mm
float stepsToMm(long steps, long stepsPerRevolution) {
  return (mm_per_rev_4 / stepsPerRevolution) * steps;
}

// Function to convert mm to motor steps
long mmToSteps(long mm, long stepsPerRevolution) {
  // 1 rev = 4 mm (mm_per_rev_4)
  return round((mm * stepsPerRevolution/mm_per_rev_4));
}

// Function to multiply two arrays
void multiplyArrays(long arr1[], long arr2[], long result[], long size) {
  for (long i = 0; i < size; i++) {
    result[i] = arr1[i] * arr2[i]; // Multiply corresponding elements
  }
  return result;
}

// define soft endstop values
long motorIndicesSoftendstops_raw[4] = {degreesToSteps(360,200), degreesToSteps(3600,200), degreesToSteps(90,200), mmToSteps(1500,200)};
long motorIndicesSoftendstops[4]; // is calculated in setup
long motorIndicesStepsPerRevolution_raw[4] = {200, 200, 200, 200};
long motorIndicesstepsPerRevolution[4]; // is calculated in setup

// // long targetPositions[4] = {0, 0, 0}; // Target positions
// float stepsPerRevolution = 200;  // Steps per revolution for the motor

// long delay_base = 500;

const int bufferSize = 64; // Maximum size of the input buffer
char inputBuffer[bufferSize]; // Buffer to hold the incoming data
int bufferIndex = 0; // Index to track the buffer position

boolean verbose = true; // Global toggle for verbose mode


void printArray(long arr[], int size) { // Function must be defined before use
  for (int i = 0; i < size; i++) {
    Serial.print(arr[i]); // Print element
    if (i < size - 1) Serial.print(", "); // Print comma
  }
  Serial.println(); // End line
}

void setup() {
  Serial.begin(115200);  // Start serial communication

  Serial.println('Setting up machine...');
  // Set step and direction pins as output
  pinMode(DirPin_specimen_rot, OUTPUT);
  pinMode(StepPin_specimen_rot, OUTPUT);
  pinMode(EndstopPin_specimen_rot, INPUT_PULLUP); // Enable pull-up resistor
  pinMode(DirPin_specimen_height, OUTPUT);
  pinMode(StepPin_specimen_height, OUTPUT);
  pinMode(EndstopPin_specimen_height, INPUT_PULLUP); // Enable pull-up resistor
  pinMode(DirPin_arm, OUTPUT);
  pinMode(StepPin_arm, OUTPUT);
  pinMode(EndstopPin_arm, INPUT_PULLUP); // Enable pull-up resistor
  pinMode(DirPin_cam, OUTPUT);
  pinMode(StepPin_cam, OUTPUT);
  pinMode(EndstopPin_cam, INPUT_PULLUP); // Enable pull-up resistor

    // Set board LED pin as output
  pinMode(LED_BUILTIN, OUTPUT);

  // Multiply the arrays
  multiplyArrays(motorIndicesSoftendstops_raw, motorMicrostepping, motorIndicesSoftendstops, 4);
  // motorIndicesSoftendstops[3] = 75000;

  multiplyArrays(motorIndicesStepsPerRevolution_raw, motorMicrostepping, motorIndicesstepsPerRevolution, 4);

  Serial.println("Steps per revolution: ");
  printArray(motorIndicesStepsPerRevolution_raw, 4);
  Serial.println("Soft endstops: ");
  printArray(motorIndicesSoftendstops, 4);
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
  long number1, number2;   // To store the two numbers

  // Parse the command using sscanf
  if (sscanf(command, "%15s %d %d", commandString, &number1, &number2) == 3) {
    executeCommand(commandString, number1, number2); // Pass parsed values to a function
  } else {
    Serial.println("Invalid command format. Use: COMMAND <number1> <number2>");
  }
}

// Function to handle the parsed command and number
void executeCommand(const char* command, long value1, long value2) {
    if (strcmp(command, "ABS") == 0) {
      moveMotorTo(value1, value2);
    } else if (strcmp(command, "REL") == 0) {
      // if(value2 == 3) value1 = -1*value1;
      moveMotor(value1, value2);
    } else if (strcmp(command, "HOME") == 0) {
      homeMotor(value1);
    } else if (strcmp(command, "STATUS_MOTORS") == 0) {
      sendMotorPositions();
      sendMotorDegrees();
    } else if (strcmp(command, "STATUS_HOME") == 0) {
      sendHomingStates();
    } else if (strcmp(command, "RESET_SPEC_ROT") == 0) {
      motorPositions[0] = 0;
      sendMotorPositions();
      sendMotorDegrees();
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
//   sendMotorDegrees();
//   sendHomingStates();
// }

void homeMotor(int motorIndex){
  // Move until the endstop is triggered
  int delay_steps = motorIndicesDelays[motorIndex]; // round(delay_base/(curr_microstepping/2));
  digitalWrite(motorIndicesDir[motorIndex], LOW);
  while (digitalRead(EndstopPin_arm) == LOW) { // LOW means not triggered
    digitalWrite(motorIndicesStep[motorIndex], HIGH);  // Step pin HIGH
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
    digitalWrite(motorIndicesStep[motorIndex], LOW);   // Step pin LOW
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  }
  motorPositions[motorIndex] = 0;
  sendMotorPositions();
  sendMotorDegrees();
  homingStates[motorIndex] = 1;
  sendHomingStates();
}

void moveMotorTo(int motorIndex, long degrees){
  long curr_motor_position = motorPositions[motorIndex];
  long curr_degrees_difference;
  if(motorIndex == 3){
    long curr_motor_degrees = stepsToMm(curr_motor_position, motorIndicesstepsPerRevolution[motorIndex]);
    curr_degrees_difference = degrees - curr_motor_degrees;
  } else{
    long curr_motor_degrees = stepsToDegrees(curr_motor_position, motorIndicesstepsPerRevolution[motorIndex]);
    curr_degrees_difference = degrees - curr_motor_degrees;
  }
  moveMotor(motorIndex, curr_degrees_difference);
}

void moveMotor(int motorIndex, int degrees) {
  float target = -1;
  
  int curr_microstepping = motorMicrostepping[motorIndex];

  if(motorIndex == 0){
    target = degreesToSteps(degrees, 200*curr_microstepping);
  } else if(motorIndex == 1){
    target = degreesToSteps(degrees, 200*curr_microstepping);
  } else if(motorIndex == 2){
    target = degreesToSteps(degrees, 200*curr_microstepping);
  } else if (motorIndex == 3){
    target = mmToSteps(degrees, 200*curr_microstepping);
  } else {
    Serial.print("Motor not defined.");
  }
  
  if (verbose) {
    Serial.println("********");
    Serial.print("movement steps: ");
    Serial.println(target);
    Serial.print("movement degrees: ");
    Serial.println(degrees);
  }
  
  if(target > 0){
    digitalWrite(motorIndicesDir[motorIndex], HIGH);
  } else {
    digitalWrite(motorIndicesDir[motorIndex], LOW);
  }

  int target_abs = abs(target); // * curr_microstepping;
  int delay_steps = motorIndicesDelays[motorIndex]; // round(delay_base/(curr_microstepping/2));

  
  int curr_endstop_pin = motorIndicesEndstop[motorIndex];
  // Serial.println(curr_endstop_pin);
  int curr_endstop_soft = motorIndicesSoftendstops[motorIndex];

  // check if soft endstops would be reached
  // Serial.println(motorPositions[motorIndex] + target);
  // Serial.println("****");
  if(motorPositions[motorIndex] + target < curr_endstop_soft){
    if(motorPositions[motorIndex] + target > 0) {
      
    } else{
      Serial.println("HARD END!!");
      target_abs = motorPositions[motorIndex];
      Serial.print("new movement steps: ");
      Serial.println(target_abs);
    }
    
  } else {
    Serial.println("SOFT END!!");
    target_abs = curr_endstop_soft-motorPositions[motorIndex];
    Serial.print("new movement steps: ");
    Serial.println(target_abs);
  }

  for (int i = 0; i < target_abs; i++) {
    // Check if endstop is reached
    digitalWrite(motorIndicesStep[motorIndex], HIGH);  // Step pin HIGH
    delayMicroseconds(delay_steps);
    digitalWrite(motorIndicesStep[motorIndex], LOW);   // Step pin LOW
    delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  }

  if(target > 0){
    motorPositions[motorIndex] = motorPositions[motorIndex]+target_abs;
  } else {
    motorPositions[motorIndex] = motorPositions[motorIndex]-target_abs;
  }
  

  // // reverse one step in case 0 position was reached
  // if(motorPositions[motorIndex] == 0 - 1){
  //   Serial.print("Motor ");
  //   Serial.print(motorIndex);
  //   Serial.println(" hit position 0.");
  //   // reverse motor direction
  //   if(target > 0){
  //     digitalWrite(motorIndicesDir[motorIndex], LOW);
  //     motorPositions[motorIndex] = motorPositions[motorIndex]-1;
  //   } else {
  //     digitalWrite(motorIndicesDir[motorIndex], HIGH);
  //     motorPositions[motorIndex] = motorPositions[motorIndex]+1;
  //   }
  //   digitalWrite(motorIndicesStep[motorIndex], HIGH);  // Step pin HIGH
  //   delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  //   digitalWrite(motorIndicesStep[motorIndex], LOW);   // Step pin LOW
  //   delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  // }

  // // reverse one step in case soft endstop was reached
  // if(motorPositions[motorIndex] == curr_endstop_soft + 1){
  //   Serial.print("Motor ");
  //   Serial.print(motorIndex);
  //   Serial.print(" hit soft end position of ");
  //   Serial.print(curr_endstop_soft);
  //   Serial.println(".");
    
  //   // reverse motor direction
  //   if(target > 0){
  //     digitalWrite(motorIndicesDir[motorIndex], LOW);
  //     motorPositions[motorIndex] = motorPositions[motorIndex]-1;
  //   } else {
  //     digitalWrite(motorIndicesDir[motorIndex], HIGH);
  //     motorPositions[motorIndex] = motorPositions[motorIndex]+1;
  //   }
  //   digitalWrite(motorIndicesStep[motorIndex], HIGH);  // Step pin HIGH
  //   delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  //   digitalWrite(motorIndicesStep[motorIndex], LOW);   // Step pin LOW
  //   delayMicroseconds(delay_steps);  // Control speed by delay (adjustable)
  // }

  if (verbose) {
    sendMotorDegrees();
    sendMotorPositions();
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
  Serial.print(motorPositions[2]);
  Serial.print(',');
  Serial.println(motorPositions[3]);
}

// Send motor degrees to Processing
void sendMotorDegrees() {
  Serial.print(2);
  Serial.print(',');
  Serial.print(stepsToDegrees(motorPositions[0],motorIndicesstepsPerRevolution[0]));
  Serial.print(',');
  Serial.print(stepsToDegrees(motorPositions[1],motorIndicesstepsPerRevolution[1]));
  Serial.print(',');
  Serial.print(stepsToDegrees(motorPositions[2],motorIndicesstepsPerRevolution[2]));
  Serial.print(',');
  Serial.println(stepsToDegrees(motorPositions[3],motorIndicesstepsPerRevolution[3]));
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