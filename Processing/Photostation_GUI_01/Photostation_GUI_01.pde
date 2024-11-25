import controlP5.*;
import processing.serial.*;

ControlP5 cp5;
Serial arduinoPort;
int[] motorPositions = {0, 0, 0, 0};  // Current positions of the motors
int[] targetPositions = {0, 0, 0, 0}; // Slider values (target positions)
int motorMaxPosition = 10000;

int motors_to_control = 3;

void setup() {
  size(600, 400);
  
  // Set up serial communication with Arduino (adjust COM port as needed)
  arduinoPort = new Serial(this, "COM4", 115200);  // Use the correct port number
  
  // Create sliders to control each motor
  cp5 = new ControlP5(this);
  for (int i = 0; i < motors_to_control; i++) {
    cp5.addSlider("motor" + (i + 1))
       .setPosition(50, 50 + i * 60)
       .setRange(0, motorMaxPosition)
       .setSize(300, 20)  // slider width (px)
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
  
  // Display current motor positions
  textSize(16);
  fill(0);
  for (int i = 0; i < motors_to_control; i++) {
    text("Motor " + (i + 1) + " Position: " + motorPositions[i], 50, 40 + i * 60);
  }
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
      // print(str(motorIndex)+'\n');
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
    // print(str(targetPositions[i]) + ',');
  }
  arduinoPort.write('\n');  // End of transmission
}

// Receive motor positions from Arduino
void serialEvent(Serial myPort) {
  String posData = myPort.readStringUntil('\n');
  if (posData != null) {
    String[] positions = split(trim(posData), ',');
    for (int i = 0; i < positions.length; i++) {
      motorPositions[i] = int(positions[i]);
    }
  }
}
