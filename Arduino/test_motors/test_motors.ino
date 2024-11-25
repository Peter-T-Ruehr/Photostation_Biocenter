/* Example sketch to control a stepper motor with 
   DRV8825 stepper motor driver, AccelStepper library 
   and Arduino: continuous rotation. 
   More info: https://www.makerguides.com */

#include "AccelStepper.h"

// Define stepper motor connections and motor interface type. Motor interface type must be set to 1 when using a driver:
#define dirPin_1 2
#define stepPin_1 3
#define dirPin_2 4
#define stepPin_2 5
#define dirPin_3 6
#define stepPin_3 7
#define dirPin_4 8
#define stepPin_4 9
#define motorInterfaceType 1

// Create a new instance of the AccelStepper class:
AccelStepper stepper_1 = AccelStepper(motorInterfaceType, stepPin_1, dirPin_1);
AccelStepper stepper_2 = AccelStepper(motorInterfaceType, stepPin_2, dirPin_2);
AccelStepper stepper_3 = AccelStepper(motorInterfaceType, stepPin_3, dirPin_3);
AccelStepper stepper_4 = AccelStepper(motorInterfaceType, stepPin_4, dirPin_4);

void setup() {
  // Set the maximum speed in steps per second:
  stepper_1.setMaxSpeed(1000);
  stepper_2.setMaxSpeed(1000);
  stepper_3.setMaxSpeed(1000);
  stepper_4.setMaxSpeed(1000);
}

void loop() {
  // Set the speed in steps per second:
  stepper_1.setSpeed(600);
  stepper_2.setSpeed(600);
  stepper_3.setSpeed(600);
  stepper_4.setSpeed(600);
  // Step the motor with a constant speed as set by setSpeed():
  stepper_1.runSpeed();
  stepper_2.runSpeed();
  stepper_3.runSpeed();
  stepper_4.runSpeed();
}