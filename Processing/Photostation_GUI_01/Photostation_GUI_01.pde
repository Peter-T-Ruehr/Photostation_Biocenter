import controlP5.*;
// PShape backgrounds_armVG; // To store the SVG background
import processing.serial.*;

ControlP5 cp5;
PImage[] backgrounds_arm = new PImage[91];
Serial arduinoPort;
int[] motorPositions = {0, 0, 0, 0};  // Current positions of the motors
int[] homingStates = {0, 0, 1};  // Current Homing states of the motors
int[] targetPositions = {0, 0, 0}; // Slider values (target positions)
int motorMaxPosition = 90;


int motors_to_control = 3;

// Define motor rotations
float stepAngle = 1.8; // Step angle in degrees
float gearRatio = 1;    // Approximate gear reduction ratio
float stepsPerRevolution = 360 / (stepAngle * gearRatio);
  
int backgroundIndex_arm = 0;
int previousbackgroundIndex_arm = -1;
int previousmotorPosition = -1;
String previousposData = "-1";

void setup() {
  
  //println(motorPositions[0]);
  //println(motorMaxPosition);

  size(1000, 1000); // Match the SVG's dimensions for best alignment
  
  //// Load the background SVG file
  //backgrounds_armVG = loadShape("station_CAD.svg");
  // Load background images
  for (int i = 0; i < backgrounds_arm.length; i++) {
    int j = i+1;
    // backgrounds_arm[i] = loadImage("station_CAD_" + j + ".png");
    backgrounds_arm[i] = loadImage("./02_angles_arm/" + nf(j, 4) + ".png");
  }
  
  // Set up serial communication with Arduino (adjust COM port as needed)
  arduinoPort = new Serial(this, "COM4", 115200);  // Use the correct port number
  
  // Initialize ControlP5 GUI components
  cp5 = new ControlP5(this);
  
  
  
  // Create sliders to control each motor
  for (int i = 0; i < motors_to_control; i++) {
    cp5.addSlider("motor" + (i + 1))
       .setPosition(50, 50 + i * 60) // Adjust position to fit over SVG
       .setRange(0, motorMaxPosition)
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
  
  // println(backgrounds_arm[backgroundIndex_arm]);
  image(backgrounds_arm[backgroundIndex_arm], 800/2, 600/3, 800/2, 800/2); // width, height
  
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

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    if (theEvent.getController().getName().equals("Home Motors")) {
      arduinoPort.write('h');  // Send homing command
    } else {
      int motorIndex =  theEvent.getController().getId();
      if(motorIndex == -1){
        motorIndex = 1;
      }
      targetPositions[motorIndex] = int(theEvent.getController().getValue());
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
        
        backgroundIndex_arm = round(motorPositions[1]); 
        //// Select a background based on motor positions
        //float bg_ratio = (float) motorPositions[1] / motorMaxPosition; // Floating-Point Division
        //if(bg_ratio < 0.5){
        //  backgroundIndex_arm = 0;
        //} else{
        //  backgroundIndex_arm = 1;
        //}
        //// If the background index changed, print it
        //if (backgroundIndex_arm != previousbackgroundIndex_arm) {
        //  println("Background index arm changed to: " + backgroundIndex_arm);
        //  previousbackgroundIndex_arm = backgroundIndex_arm; // Update the tracking variable
        //}
        //if (motorPositions[0] != previousmotorPosition) {
        //  println("Motor position changed to: " + motorPositions[0]);
        //  previousbackgroundIndex_arm = backgroundIndex_arm; // Update the tracking variable
        //  previousmotorPosition = motorPositions[0];
        //}
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
