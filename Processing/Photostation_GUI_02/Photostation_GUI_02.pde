import controlP5.*;
import processing.serial.*;

ControlP5 cp5;
PImage image_specimen_rot; // Variable for the Image image_specimen_rot
PImage image_specimen_height; // Variable for the Image image_specimen_height
PImage ImageMachine; // Variable for the Image ImageMachine
PImage ImageArm; // Variable for the Image ImageArm
PFont calibriFont;

Serial arduinoPort;
int[] motorPositions = {0, 0, 0, 0};  // Current positions of the motors
float[] motorDegrees =  {0, 0, 0, 0};  // Current degree positions of the motors
int[] homingStates = {1, 0, 0, 0};  // Current Homing states of the motors
int[] targetPositions = {0, 0, 0, 0}; // Slider values (target positions)
int[] MaxmotorPositions = {360, 90, 3600, 1800};

int motors_to_control = 4;

int windowWidth = 1200;
int windowHeight = 600;
int buttonWidth = 45;    // Button width
int buttonHeight = 25;    // Button height
int marginX = 10;         // Horizontal spacing between buttons
int marginY = 10;         // Vertical spacing between buttons
int labelWidth = 150;     // Width for the label column


boolean isSpecHeightHomed = false; // Example control variable
boolean isArmHomed = false; // Example control variable
boolean isCameraHomed = false; // Example control variable

void setup() {
  // Set up serial communication with Arduino (adjust COM port as needed)
  arduinoPort = new Serial(this, "COM5", 115200);  // Use the correct port number
  
  size(1200, 600); // Set the window size
  cp5 = new ControlP5(this);

  // Load the Calibri font
  calibriFont = createFont("Calibri", 12); 
  cp5.setFont(calibriFont); // Apply font globally to all buttons
  
   // Load the background image
  image_specimen_rot = loadImage("01_angles_specimen.png");
  image_specimen_height = loadImage("02_specimen_height.png");
  ImageArm = loadImage("03_arm.png");
  ImageMachine = loadImage("00_immovable.png");
  // Add row labels and buttons for each group
  int x = 50;
  int y = 20;  // Initial vertical position for the first row

  // Rotation Buttons Specimen
  // positive
  String[] rotationButtons_specimen_positive = {
    // "Set Specimen Rotation to 0", "Rotate Specimen to 0°", 
    // "Rotate Specimen to 180°", "Rotate Specimen to 270°", "Rotate Specimen to 360°"
    "1°", "5°",  "45°", 
    "90°", "180°", "360°", 
  };
  y = addRow("RotControlsSpecimensPos", rotationButtons_specimen_positive, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // negative
  String[] rotationButtons_specimen_negative = {
    // "Rotate Specimen to 0°", 
    // "Rotate Specimen to 180°", "Rotate Specimen to 270°", "Rotate Specimen to 360°"
    "-1°", "-5°",  "-45°", 
    "-90°", "-180°", "-360°", 
  };
  y = addRow("RotControlsSpecimensNeg", rotationButtons_specimen_negative, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // Specimen Height Buttons
  y = y+buttonHeight+marginY;
  // positive
  String[] specimenHeightButtons_positive = {
     "0.1 mm", "0.5 mm", "1 mm", "5 mm", "10 mm", 
  };
  y = addRow("SpecHeightControlsPos", specimenHeightButtons_positive, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // negative
  String[] specimenHeightButtons_negative = {
     "-0.1 mm", "-0.5 mm", "-1 mm", "-5 mm", "-10 mm", 
  };
  y = addRow("SpecHeightControlsNeg", specimenHeightButtons_negative, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  
  // Arm Buttons
  y = y+buttonHeight+marginY;
  // positive
  String[] armButtons_positive = {
    //Move Arm to 0°", "Move Arm to 22.5°", "Move Arm to 45°", 
    //"Move Arm to 67.5°", "Move Arm to 90°"
    "1°", "5°", "10°", "45°", "90°"
  };
  y = addRow("ArmControlsPos", armButtons_positive, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // negative
  String[] armButtons_negative = {
    // "Move Arm to 0°", "Move Arm to 22.5°", "Move Arm to 45°", 
    //"Move Arm to 67.5°", "Move Arm to 90
    "-1°", "-5°", "-10°", "-45°", "-90°"
  };
  y = addRow("ArmControlsNeg", armButtons_negative, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // Camera Buttons
  y = y+buttonHeight+marginY;
  // positive
  String[] cameraButtons_positive = {
    //Move Arm to 0°", "Move Arm to 22.5°", "Move Arm to 45°", 
    //"Move Arm to 67.5°", "Move Arm to 90°"
    "1 mm", "5 mm", "10 mm", "50 mm", "100 mm"
  };
  y = addRow("CamControlsPos", cameraButtons_positive, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // negative
  String[] cameraButtons_negative = {
    // "Move Arm to 0°", "Move Arm to 22.5°", "Move Arm to 45°", 
    //"Move Arm to 67.5°", "Move Arm to 90°"
    "-1 mm", "-5 mm", "-10 mm", "-50 mm", "-100 mm"
  };
  y = addRow("CamControlsNeg", cameraButtons_negative, x, y, buttonWidth, buttonHeight, marginX, marginY);

  // Homing
  y = y+buttonHeight+marginY;
  buttonWidth = buttonWidth*2+marginX;    // Button width
  String[] HomingButtons = {
    "Specimen Height", "Arm Tilt", "Camera Offset"
  };
  y = addRow("HomingControls", HomingButtons, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // Specimen Rot
  String[] SpecimenRotationReset = {
    "Reset"
  };
  y = addRow("SpecRotReset", SpecimenRotationReset, x, y, buttonWidth, buttonHeight, marginX, marginY);

  // Save Button
  y = y+buttonHeight+marginY;
  String[] saveButton = {
    "Save Setting"
  };
  y = addRow("SaveSettingsControls", saveButton, x, y, buttonWidth, buttonHeight, marginX, marginY);

  // Check if the buttons fit inside the window
  if (y > windowHeight) {
    println("Warning: Buttons may not fit in the current window size.");
  }
  
  // Disable some buttons initially
    disableButtons(new String[]{
      "SpecHeightControlsPos_0", "SpecHeightControlsPos_1", "SpecHeightControlsPos_2", "SpecHeightControlsPos_3", "SpecHeightControlsPos_4",
      "SpecHeightControlsNeg_0", "SpecHeightControlsNeg_1", "SpecHeightControlsNeg_2", "SpecHeightControlsNeg_3", "SpecHeightControlsNeg_4",
      "ArmControlsPos_0", "ArmControlsPos_1", "ArmControlsPos_2", "ArmControlsPos_3", "ArmControlsPos_4",
      "ArmControlsNeg_0", "ArmControlsNeg_1", "ArmControlsNeg_2", "ArmControlsNeg_3", "ArmControlsNeg_4",
      "CamControlsPos_0", "CamControlsPos_1", "CamControlsPos_2", "CamControlsPos_3", "CamControlsPos_4",
      "CamControlsNeg_0", "CamControlsNeg_1", "CamControlsNeg_2", "CamControlsNeg_3", "CamControlsNeg_4"
    });
}

void draw() {
  background(255); // Set a light background
  
  int machine_image_x = 562;
  int machine_image_y = 289;
  
  int specimen_height_image_x = 562;
  int specimen_height_image_y = 289;
  
  int arm_image_x = 511;
  int arm_image_y = 132;
  
  // Draw machine image at a fixed position
  pushMatrix(); // Save the current transformation
  translate(550 + machine_image_x / 2, 160 + 100 +  machine_image_y / 2); // Move origin to the image center (imgX + imgWidth / 2, imgY + imgHeight / 2)
  imageMode(CENTER); // Draw the image from its center
  image(ImageMachine, 0, 0, machine_image_x, machine_image_y); // width, height
  popMatrix(); // Restore the original transformation
  
  // Draw the rotating arm image at a fixed position
  pushMatrix(); // Save the current transformation
  translate(550 - 18 + (machine_image_x-arm_image_x)/2 + arm_image_x / 2, 100 + 124 + arm_image_y / 2); // Move origin to the image center (imgX + imgWidth / 2, imgY + imgHeight / 2)0
  //println(motorDegrees[2]);
  rotate(degreesToRadians(motorDegrees[2])); // Rotate around the image's center degreesToRadians(motorPositions[2]/current_microstepping)
  imageMode(CENTER); // Draw the image from its center
  image(ImageArm, 0, 0, arm_image_x, arm_image_y); // width, height
  popMatrix(); // Restore the original transformation
  
  // Draw the species height translation image at a fixed position
  pushMatrix(); // Save the current transformation
  translate(550 + specimen_height_image_x / 2, 160 + 100 +  specimen_height_image_y / 2); // Move origin to the image center (imgX + imgWidth / 2, imgY + imgHeight / 2)
  //println(motorDegrees[2]);
  translate(0, -1*motorDegrees[1]/50);
  
  imageMode(CENTER); // Draw the image from its center
  image(image_specimen_height, 0, 0, specimen_height_image_x, specimen_height_image_y); // width, height
  popMatrix(); // Restore the original transformation
  
  
  // Draw the rotating image at a fixed position
  pushMatrix(); // Save the current transformation
  translate(25 + 550 + 150 / 2, 5 + 150/ 2); // Move origin to the image center (imgX + imgWidth / 2, imgY + imgHeight / 2)
  rotate(degreesToRadians(motorDegrees[0])); // Rotate around the image's center
  imageMode(CENTER); // Draw the image from its center
  image(image_specimen_rot, 0, 0, 150, 150); // width, height
  popMatrix(); // Restore the original transformation
  
  String row_labels[] = {"Rotate Specimen Right", "Rotate Specimen Left", 
    "",
    "Raise Specimen by", "Lower Specimen by",
    "",
    "Tilt Arm Up by", "Tilt Arm Down by",
    "",
    "Increase Camera Distance by", "Decrease Camera Distance by",
    "",
    "Home Motors", "Specimen Rotation",
    "",
    "Save Settings"
  };
  
  textSize(13.5);
  textAlign(RIGHT);
  fill(0);
  int y = 20;
  int x = 20;
  for (int i = 0; i < row_labels.length; i++) {
    text(row_labels[i], 20+155, (i+1)*(buttonHeight+marginY));
  }
}

float degreesToRadians(float degrees) {
  return degrees * PI / 180; // Multiply degrees by π/180 to get radians
}

// Function to disable buttons
void disableButtons(String[] buttonNames) {
  for (String name : buttonNames) {
    cp5.getController(name)
       .setLock(true); // Disable the button
       //.setColorActive(color(180)); // Gray out active state
       //.setColorBackground(color(200)) // Gray out background
       //.setColorForeground(color(150)); // Gray out foreground
  }
}

// Function to enable buttons
void enableButtons(String[] buttonNames) {
  for (String name : buttonNames) {
    cp5.getController(name)
       .setLock(false); // Enable the button
       //.setColorActive(color(0, 128, 255)) // Restore active state
       //.setColorBackground(color(200, 200, 255)) // Restore background
       //.setColorForeground(color(50, 50, 200)); // Restore foreground
  }
}

// Function to add a row of buttons and a label
int addRow(String label, String[] labels, int x, int y, int width, int height, int marginX, int marginY) {  
  // Add buttons for the row (place them after the label)
  int buttonsInRow = labels.length;
  for (int i = 0; i < buttonsInRow; i++) {
    cp5.addButton(label + "_" + i)
       .setLabel(labels[i]) // Use the label as written
       .setPosition(x + labelWidth + i * (width + marginX), y)
       .setSize(width, height);
  }

  // Return the next vertical position after this row
  return y + height + marginY;
}
  
void controlEvent(ControlEvent theEvent) {
  if (theEvent.isController()) {
    String name = theEvent.getController().getName();
    println("Button " + name + " clicked!");
    if (theEvent.getController().getName().equals("RotControlsSpecimensPos_0")) {
      arduinoPort.write("REL 0 1\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_1")) {
      arduinoPort.write("REL 0 5\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_2")) {
      arduinoPort.write("REL 0 45\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_3")) {
      arduinoPort.write("REL 0 90\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_4")) {
      arduinoPort.write("REL 0 180\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_5")) {
      arduinoPort.write("REL 0 360\n");
    } 
    else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_0")) {
      arduinoPort.write("REL 0 -1\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_1")) {
      arduinoPort.write("REL 0 -5\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_2")) {
      arduinoPort.write("REL 0 -45\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_3")) {
      arduinoPort.write("REL 0 -90\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_4")) {
      arduinoPort.write("REL 0 -180\n");
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_5")) {
      arduinoPort.write("REL 0 -360\n");
    }
    else if (theEvent.getController().getName().equals("SpecHeightControlsPos_0")) {
      arduinoPort.write("REL 1 1\n");
    } else if (theEvent.getController().getName().equals("SpecHeightControlsPos_1")) {
      arduinoPort.write("REL 1 5\n");
    } else if (theEvent.getController().getName().equals("SpecHeightControlsPos_2")) {
      arduinoPort.write("REL 1 45\n");
    } else if (theEvent.getController().getName().equals("SpecHeightControlsPos_3")) {
      arduinoPort.write("REL 1 90\n");
    } else if (theEvent.getController().getName().equals("SpecHeightControlsPos_4")) {
      arduinoPort.write("REL 1 180\n");
    }
    else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_0")) {
      arduinoPort.write("REL 1 -1\n");
    } else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_1")) {
      arduinoPort.write("REL 1 -5\n");
    } else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_2")) {
      arduinoPort.write("REL 1 -45\n");
    } else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_3")) {
      arduinoPort.write("REL 1 -90\n");
    } else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_4")) {
      arduinoPort.write("REL 1 -180\n");
    }
    else if (theEvent.getController().getName().equals("ArmControlsPos_0")) {
      arduinoPort.write("REL 2 1\n");
    } else if (theEvent.getController().getName().equals("ArmControlsPos_1")) {
      arduinoPort.write("REL 2 5\n");
    } else if (theEvent.getController().getName().equals("ArmControlsPos_2")) {
      arduinoPort.write("REL 2 10\n");
    } else if (theEvent.getController().getName().equals("ArmControlsPos_3")) {
      arduinoPort.write("REL 2 45\n");
    } else if (theEvent.getController().getName().equals("ArmControlsPos_4")) {
      arduinoPort.write("REL 2 90\n");
    }
    else if (theEvent.getController().getName().equals("ArmControlsNeg_0")) {
      arduinoPort.write("REL 2 -1\n");
    } else if (theEvent.getController().getName().equals("ArmControlsNeg_1")) {
      arduinoPort.write("REL 2 -5\n");
    } else if (theEvent.getController().getName().equals("ArmControlsNeg_2")) {
      arduinoPort.write("REL 2 -10\n");
    } else if (theEvent.getController().getName().equals("ArmControlsNeg_3")) {
      arduinoPort.write("REL 2 -45\n");
    } else if (theEvent.getController().getName().equals("ArmControlsNeg_4")) {
      arduinoPort.write("REL 2 -90\n");
    }
    else if (theEvent.getController().getName().equals("CamControlsPos_0")) {
      arduinoPort.write("REL 3 1\n");
    } else if (theEvent.getController().getName().equals("CamControlsPos_1")) {
      arduinoPort.write("REL 3 5\n");
    } else if (theEvent.getController().getName().equals("CamControlsPos_2")) {
      arduinoPort.write("REL 3 45\n");
    } else if (theEvent.getController().getName().equals("CamControlsPos_3")) {
      arduinoPort.write("REL 3 90\n");
    } else if (theEvent.getController().getName().equals("CamControlsPos_4")) {
      arduinoPort.write("REL 3 180\n");
    }
    else if (theEvent.getController().getName().equals("CamControlsNeg_0")) {
      arduinoPort.write("REL 3 -1\n");
    } else if (theEvent.getController().getName().equals("CamControlsNeg_1")) {
      arduinoPort.write("REL 3 -5\n");
    } else if (theEvent.getController().getName().equals("CamControlsNeg_2")) {
      arduinoPort.write("REL 3 -45\n");
    } else if (theEvent.getController().getName().equals("CamControlsNeg_3")) {
      arduinoPort.write("REL 3 -90\n");
    } else if (theEvent.getController().getName().equals("CamControlsNeg_4")) {
      arduinoPort.write("REL 3 -180\n");
    } 
    // Home Specimen Height
    else if (theEvent.getController().getName().equals("HomingControls_0")) {
      arduinoPort.write("HOME 1 0\n");
      enableButtons(new String[]{
        "SpecHeightControlsPos_0", "SpecHeightControlsPos_1", "SpecHeightControlsPos_2", "SpecHeightControlsPos_3", "SpecHeightControlsPos_4",
        "SpecHeightControlsNeg_0", "SpecHeightControlsNeg_1", "SpecHeightControlsNeg_2", "SpecHeightControlsNeg_3", "SpecHeightControlsNeg_4"
      });
      isSpecHeightHomed = true;
    }
    // Home Arm
    else if (theEvent.getController().getName().equals("HomingControls_1")) {
      arduinoPort.write("HOME 2 0\n");
      enableButtons(new String[]{
        "ArmControlsPos_0", "ArmControlsPos_1", "ArmControlsPos_2", "ArmControlsPos_3", "ArmControlsPos_4",
        "ArmControlsNeg_0", "ArmControlsNeg_1", "ArmControlsNeg_2", "ArmControlsNeg_3", "ArmControlsNeg_4"
      });
      isArmHomed = true;
    }
    // Home Camera Offset
    else if (theEvent.getController().getName().equals("HomingControls_2")) {
      arduinoPort.write("HOME 3 0\n");
      enableButtons(new String[]{
        "CamControlsPos_0", "CamControlsPos_1", "CamControlsPos_2", "CamControlsPos_3", "CamControlsPos_4",
        "CamControlsNeg_0", "CamControlsNeg_1", "CamControlsNeg_2", "CamControlsNeg_3", "CamControlsNeg_4"
      });
      isCameraHomed = true;
    }
    // Reset Specimen Rotation
    else if (theEvent.getController().getName().equals("SpecRotReset_0")) {
      arduinoPort.write("RESET_SPEC_ROT 0 0\n");
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

// Function to handle incoming serial data
void serialEvent(Serial port) {
  String received = port.readStringUntil('\n'); // Read the incoming data
  if (received != null) {
    received = trim(received); // Remove any leading/trailing whitespace
    println("A: " + received); // Print the received data to the console
    
    if(received.startsWith("0")){
      println("Updating motor positions...");
      String[] positions = split(trim(received), ',');
      for (int i = 1; i < positions.length; i++) { // start at 1, not 0, to skip identifier
        motorPositions[i-1] = int(positions[i]);
      }
    } 
    else if (received.startsWith("1")) {
      println("Updating homing states...");
      String[] positions = split(trim(received), ',');
      for (int i = 1; i < positions.length; i++) { // start at 1, not 0, to skip identifier
        homingStates[i-1] = int(positions[i]);
      }
    } 
    else if (received.startsWith("2")) {
      println("Updating motor degrees...");
      String[] positions = split(trim(received), ',');
      for (int i = 1; i < positions.length; i++) { // start at 1, not 0, to skip identifier
        motorDegrees[i-1] = int(positions[i]);
      }
    }
  }
}
