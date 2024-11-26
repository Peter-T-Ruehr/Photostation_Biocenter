import controlP5.*;
// PShape backgrounds_armVG; // To store the SVG background
import processing.serial.*;

ControlP5 cp5;
PImage[] backgrounds_arm = new PImage[1];
PImage[] backgrounds_specimen = new PImage[1];
Serial arduinoPort;
int[] motorPositions = {0, 0, 0, 0};  // Current positions of the motors
int[] homingStates = {0, 0, 1};  // Current Homing states of the motors
int[] targetPositions = {0, 0, 0}; // Slider values (target positions)
int[] motorMicrostepping = {0, 1, 1, 1}; // Microstepping (1/x)
int[] MaxmotorPositions_raw = {0, 360, 90, 360};
int[] MaxmotorPositions = multiplyArrays(MaxmotorPositions_raw, motorMicrostepping);

int motors_to_control = 3;

// Define motor rotations
float stepAngle = 1.8; // Step angle in degrees
float gearRatio = 1;    // Approximate gear reduction ratio
float stepsPerRevolution = 360 / (stepAngle * gearRatio);
  
int backgroundIndex_arm = 0;
int backgroundIndex_specimen = 0;
int previousbackgroundIndex_arm = -1;
int previousmotorPosition = -1;
String previousposData = "-1";

float imgX = 300; // X-coordinate of the image's top-left corner
float imgY = 200; // Y-coordinate of the image's top-left corner
float imgWidth, imgHeight;

float miccrostepping_specimen = 8;
float miccrostepping_arm = 1;

void setup() {
  println(MaxmotorPositions[0]);
  size(1000, 1000); // Match the SVG's dimensions for best alignment
  
  // Load background images
  for (int i = 0; i < backgrounds_specimen.length; i++) {
    backgrounds_specimen[i] = loadImage("01_angles_specimen.png");
  }
  for (int i = 0; i < backgrounds_arm.length; i++) {
    backgrounds_arm[i] = loadImage("02_angles_arm.png");
  }
  
  // Set up serial communication with Arduino (adjust COM port as needed)
  arduinoPort = new Serial(this, "COM4", 115200);  // Use the correct port number
  
  // Initialize ControlP5 GUI components
  cp5 = new ControlP5(this);
  
  
  
  // Create sliders to control each motor
  for (int i = 0; i < motors_to_control; i++) {
    cp5.addSlider("motor" + (i + 1))
       .setPosition(50, 50 + i * 60) // Adjust position to fit over SVG
       .setRange(0, MaxmotorPositions[i+1])
       .setSize(300, 20)  // Slider width and height (px)
       .setValue(0)
       .setId(i);
  }
  
  // Button to home all motors
  cp5.addButton("Home Motors")
     .setPosition(400, 50)
     .setSize(150, 40);
}

void draw() {
  background(255);
  
  //// Draw the SVG file as the background
  //shape(backgrounds_armVG, 0, 0, width, height);
  
  // Draw the rotating image at a fixed position
  pushMatrix(); // Save the current transformation
  translate(100 + 200 / 2, 300 + 200 / 2); // Move origin to the image center
  int current_microstepping = motorMicrostepping[1];
  rotate(degreesToRadians(motorPositions[1]/current_microstepping)); // Rotate around the image's center
  imageMode(CENTER); // Draw the image from its center
  image(backgrounds_specimen[backgroundIndex_specimen], 0, 0, 200, 200); // width, height
  popMatrix(); // Restore the original transformation
  
  // Draw the rotating image at a fixed position
  pushMatrix(); // Save the current transformation
  translate(400 + 400 / 2, 200 + 400/ 2); // Move origin to the image center (imgX + imgWidth / 2, imgY + imgHeight / 2)
  rotate(-1*degreesToRadians(motorPositions[2])); // Rotate around the image's center
  imageMode(CENTER); // Draw the image from its center
  image(backgrounds_arm[backgroundIndex_arm], 0, 0, 400, 400); // width, height
  popMatrix(); // Restore the original transformation
  
  
  // GUI components are automatically drawn on top by ControlP5
  // Display current motor positions
  fill(0);
  textSize(16);
  for (int i = 0; i < motors_to_control; i++) {
    text("Motor " + (i + 1) + " Position: " + motorPositions[i], 50, 40 + i * 60);
    //println("Motor " + (i + 1) + " Position: " + motorPositions[i]);
  }
  //for (int i = 0; i < motors_to_control; i++) {
  //  float motorDegrees = stepsToDegrees(motorPositions[i], stepAngle, gearRatio);
  //  text("Motor " + (i + 1) + " Position: " + nf(motorDegrees, 1, 2) + "°", 50, 40 + i * 60); // 150, 90 + i * 80
  //}
}

// Function to multiply two arrays element-wise
int[] multiplyArrays(int[] a, int[] b) {
  if (a.length != b.length) {
    println("Error: Arrays must be of the same length");
    return null; // Return null if lengths don't match
  }

  int[] result = new int[a.length];
  for (int i = 0; i < a.length; i++) {
    result[i] = a[i] * b[i];
  }
  return result;
}

float degreesToRadians(float degrees) {
  return degrees * PI / 180; // Multiply degrees by π/180 to get radians
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    if (theEvent.getController().getName().equals("Home Motors")) {
      arduinoPort.write('h');  // Send homing command
    } else {
      int motorIndex =  theEvent.getController().getId();
      if(motorIndex == -1){
        motorIndex = 1;
      }
      
      // println(current_microstepping);
      targetPositions[motorIndex] = int (theEvent.getController().getValue());
      sendTargetPositions();
    }
  }
}

// Send target positions to Arduino
void sendTargetPositions() {
  arduinoPort.write('s');  // Signal start of positions
  for (int i = 0; i < motors_to_control; i++) {
    arduinoPort.write(str(targetPositions[i]) + ',');  // Send each position
  }
  arduinoPort.write('\n');  // End of transmission
}

// Receive motor positions and homing states from Arduino
void serialEvent(Serial myPort) {
  String posData = myPort.readStringUntil('\n');
  posData = trim(posData); // Remove leading/trailing whitespace
  if (posData != null) {
    if(posData.startsWith("0")){
      String[] positions = split(trim(posData), ',');
      for (int i = 1; i < positions.length; i++) { // start at 1, not 0, to skip identifier
        motorPositions[i] = int(positions[i]);
        
        backgroundIndex_arm = 0;
        backgroundIndex_specimen = 0;
      }
    } else if (posData.startsWith("1")) {
      String[] positions = split(trim(posData), ',');
      for (int i = 1; i < positions.length; i++) { // start at 1, not 0, to skip identifier
        homingStates[i] = int(positions[i]);
      }
    }
  }
  
  
}

float degreesToSteps(float degrees, float stepAngle, float gearRatio) {
  float stepsPerRevolution = 360 / stepAngle * gearRatio;
  return round((degrees / 360) * stepsPerRevolution);
}

// Converts steps to degrees based on step angle and gear ratio
float stepsToDegrees(int steps, float stepAngle, float gearRatio) {
  float stepsPerRevolution = 360 / stepAngle * gearRatio;
  return (steps * 360.0) / stepsPerRevolution;
}
