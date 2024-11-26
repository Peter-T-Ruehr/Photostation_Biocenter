import controlP5.*;
import processing.serial.*;

ControlP5 cp5;
PFont calibriFont;

Serial arduinoPort;
int[] motorPositions = {0, 0, 0, 0};  // Current positions of the motors
int[] homingStates = {1, 0, 0, 0};  // Current Homing states of the motors
int[] targetPositions = {0, 0, 0, 0}; // Slider values (target positions)
int[] MaxmotorPositions = {0, 360, 90, 360, 360};

int motors_to_control = 4;

int windowWidth = 1000;
int windowHeight = 600;
int buttonWidth = 45;    // Button width
int buttonHeight = 25;    // Button height
int marginX = 10;         // Horizontal spacing between buttons
int marginY = 10;         // Vertical spacing between buttons
int labelWidth = 150;     // Width for the label column

void setup() {
  // Set up serial communication with Arduino (adjust COM port as needed)
  arduinoPort = new Serial(this, "COM5", 115200);  // Use the correct port number
  
  size(1000, 600); // Set the window size
  cp5 = new ControlP5(this);

  // Load the Calibri font
  calibriFont = createFont("Calibri", 12); 
  cp5.setFont(calibriFont); // Apply font globally to all buttons

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
  // positive
  String[] specimenHeightButtons_positive = {
     "-0.1 mm", "-0.5 mm", "-1 mm", "-5 mm", "-10 mm", 
  };
  y = addRow("SpecHeightControlsPos", specimenHeightButtons_positive, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // negative
  String[] specimenHeightButtons_negative = {
     "0.1 mm", "0.5 mm", "1 mm", "5 mm", "10 mm", 
  };
  y = addRow("SpecHeightControlsNeg", specimenHeightButtons_negative, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  
  // Arm Buttons
  // positive
  String[] armButtons_positive = {
    //Move Arm to 0°", "Move Arm to 22.5°", "Move Arm to 45°", 
    //"Move Arm to 67.5°", "Move Arm to 90°"
    "1 mm", "5 mm", "10 mm", "45 mm", "90 mm"
  };
  y = addRow("ArmControlsPos", armButtons_positive, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // negative
  String[] armButtons_negative = {
    // "Move Arm to 0°", "Move Arm to 22.5°", "Move Arm to 45°", 
    //"Move Arm to 67.5°", "Move Arm to 90°"
    "-1 mm", "-5 mm", "-10 mm", "-45 mm", "-90 mm"
  };
  y = addRow("ArmControlsNeg", armButtons_negative, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // Camera Buttons
  // positive
  String[] cameraButtons_positive = {
    //Move Arm to 0°", "Move Arm to 22.5°", "Move Arm to 45°", 
    //"Move Arm to 67.5°", "Move Arm to 90°"
    "1 mm", "5 mm", "10 mm", "45 mm", "90 mm"
  };
  y = addRow("CamControlsPos", cameraButtons_positive, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // negative
  String[] cameraButtons_negative = {
    // "Move Arm to 0°", "Move Arm to 22.5°", "Move Arm to 45°", 
    //"Move Arm to 67.5°", "Move Arm to 90°"
    "-1 mm", "-5 mm", "-10 mm", "-45 mm", "-90 mm"
  };
  y = addRow("CamControlsNeg", cameraButtons_negative, x, y, buttonWidth, buttonHeight, marginX, marginY);

  // Homing
  int buttonWidth = 120;    // Button width
  String[] HomingButtons = {
    "Specimen Height", "Arm", "Camera Offset"
  };
  y = addRow("HomingControls", HomingButtons, x, y, buttonWidth, buttonHeight, marginX, marginY);
  
  // Specimen Rot
  String[] SpecimenRotationReset = {
    "Reset"
  };
  y = addRow("SpecRotReset", SpecimenRotationReset, x, y, buttonWidth, buttonHeight, marginX, marginY);

  // Save Button
  String[] saveButton = {
    "Save Setting"
  };
  y = addRow("SaveSettingsControls", saveButton, x, y, buttonWidth, buttonHeight, marginX, marginY);

  // Check if the buttons fit inside the window
  if (y > windowHeight) {
    println("Warning: Buttons may not fit in the current window size.");
  }
  
  //// Disable some buttons initially
  //  disableButtons(new String[]{
  //    "RotControlsSpecimensPos_0", "RotControlsSpecimensPos_1"
  //  });
}

void draw() {
  background(240); // Set a light background
  
  String row_labels[] = {"Rotate Specimen by", "Rotate Specimen by", 
    "Move Specimen Up by", "Move Specimen Down by",
    "Mova Arm Outwards by", "Move Arm Inwards by",
    "Mova Camera Outwards by", "Move Camera Inwards by",
    "Home Motors", "Specimen Rotation",
    "Save Settings"
  };
  
  textSize(13.5);
  fill(0);
  int y = 20;
  int x = 20;
  for (int i = 0; i < row_labels.length; i++) {
    text(row_labels[i], 20, (i+1)*(buttonHeight+marginY));
  }
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
      arduinoPort.write("REL 0 1\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_1")) {
      arduinoPort.write("REL 0 5\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_2")) {
      arduinoPort.write("REL 0 45\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_3")) {
      arduinoPort.write("REL 0 90\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_4")) {
      arduinoPort.write("REL 0 180\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensPos_5")) {
      arduinoPort.write("REL 0 360\n");  // Send homing command
    } 
    else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_0")) {
      arduinoPort.write("REL 0 -1\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_1")) {
      arduinoPort.write("REL 0 -5\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_2")) {
      arduinoPort.write("REL 0 -45\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_3")) {
      arduinoPort.write("REL 0 -90\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_4")) {
      arduinoPort.write("REL 0 -180\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("RotControlsSpecimensNeg_5")) {
      arduinoPort.write("REL 0 -360\n");  // Send homing command
    }
    else if (theEvent.getController().getName().equals("SpecHeightControlsPos_0")) {
      arduinoPort.write("REL 1 1\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("SpecHeightControlsPos_1")) {
      arduinoPort.write("REL 1 5\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("SpecHeightControlsPos_2")) {
      arduinoPort.write("REL 1 45\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("SpecHeightControlsPos_3")) {
      arduinoPort.write("REL 1 90\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("SpecHeightControlsPos_4")) {
      arduinoPort.write("REL 1 180\n");  // Send homing command
    }
    else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_0")) {
      arduinoPort.write("REL 1 -1\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_1")) {
      arduinoPort.write("REL 1 -5\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_2")) {
      arduinoPort.write("REL 1 -45\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_3")) {
      arduinoPort.write("REL 1 -90\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("SpecHeightControlsNeg_4")) {
      arduinoPort.write("REL 1 -180\n");  // Send homing command
    }
    else if (theEvent.getController().getName().equals("ArmControlsPos_0")) {
      arduinoPort.write("REL 2 1\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("ArmControlsPos_1")) {
      arduinoPort.write("REL 2 5\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("ArmControlsPos_2")) {
      arduinoPort.write("REL 2 45\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("ArmControlsPos_3")) {
      arduinoPort.write("REL 2 90\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("ArmControlsPos_4")) {
      arduinoPort.write("REL 2 180\n");  // Send homing command
    }
    else if (theEvent.getController().getName().equals("ArmControlsNeg_0")) {
      arduinoPort.write("REL 2 -1\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("ArmControlsNeg_1")) {
      arduinoPort.write("REL 2 -5\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("ArmControlsNeg_2")) {
      arduinoPort.write("REL 2 -45\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("ArmControlsNeg_3")) {
      arduinoPort.write("REL 2 -90\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("ArmControlsNeg_4")) {
      arduinoPort.write("REL 2 -180\n");  // Send homing command
    }
    else if (theEvent.getController().getName().equals("CamControlsPos_0")) {
      arduinoPort.write("REL 3 1\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("CamControlsPos_1")) {
      arduinoPort.write("REL 3 5\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("CamControlsPos_2")) {
      arduinoPort.write("REL 3 45\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("CamControlsPos_3")) {
      arduinoPort.write("REL 3 90\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("CamControlsPos_4")) {
      arduinoPort.write("REL 3 180\n");  // Send homing command
    }
    else if (theEvent.getController().getName().equals("CamControlsNeg_0")) {
      arduinoPort.write("REL 3 -1\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("CamControlsNeg_1")) {
      arduinoPort.write("REL 3 -5\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("CamControlsNeg_2")) {
      arduinoPort.write("REL 3 -45\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("CamControlsNeg_3")) {
      arduinoPort.write("REL 3 -90\n");  // Send homing command
    } else if (theEvent.getController().getName().equals("CamControlsNeg_4")) {
      arduinoPort.write("REL 3 -180\n");  // Send homing command
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
  }
}
