import processing.video.*;
import controlP5.*;

// Set default camera and GUI size
int default_camera = 3; // Default to camera number 4 (0-based index)
int previewWidth = 7680/8; // Fixed preview width
int previewHeight = 4320/8; // Fixed preview height
int highResWidth = 8000; // High-resolution width for saving
int highResHeight = 4500; // High-resolution height for saving

Capture cam; // The camera object
ControlP5 cp5; // GUI library

boolean saveImage = false; // Flag to save the image
String selectedCamera = ""; // Currently selected camera
String[] cameras; // List of available cameras

void setup() {
  // Set the window size (1920 x 1080) for the GUI
  size(1920, 1080);

  // List all available cameras
  cameras = Capture.list();

  if (cameras.length == 0) {
    println("No cameras available!");
    exit();
  } else if (cameras.length <= default_camera) {
    println("Not enough cameras available for the default camera selection!");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i + ": " + cameras[i]);
    }
    // Set the default camera
    selectedCamera = cameras[default_camera];
    initializeCamera(selectedCamera, previewWidth, previewHeight);
  }

  // GUI setup
  cp5 = new ControlP5(this);

  // Add a button to save a high-resolution image
  cp5.addButton("saveImage")
     .setPosition(10, height - 50)
     .setSize(150, 40)
     .setLabel("Save High-Res Image");

  // Add a dropdown menu to select cameras
  cp5.addScrollableList("cameraSelector")
     .setPosition(180, height - 50)
     .setSize(400, 150)
     .setBarHeight(40)
     .addItems(cameras)
     .setOpen(false)
     .setLabel("Select Camera")
     .onChange(event -> {
        String selected = event.getController().getLabel();
        println("Camera selected: " + selected);
        selectedCamera = selected;
        initializeCamera(selectedCamera, previewWidth, previewHeight);
     });
}

void draw() {
  // Set background color
  background(50);

  // Check if the camera feed is available and display it
  if (cam.available()) {
    cam.read();
  }
  
  // Display the live preview scaled to the fixed size (640x480)
  image(cam, 10, 10, previewWidth, previewHeight);

  // Add text to show the preview resolution
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(20);
  text("Preview Resolution: " + previewWidth + " x " + previewHeight, 10, height - 70);

  // Handle saving the high-resolution image
  if (saveImage) {
    saveHighResImage();
    saveImage = false;
  }
}

/**
 * Initializes the camera with the specified resolution and selected camera name.
 */
void initializeCamera(String cameraName, int width, int height) {
  if (cam != null) {
    cam.stop();
  }
  println("Initializing camera: " + cameraName + " at " + width + "x" + height);
  cam = new Capture(this, width, height, cameraName);
  cam.start();
}

/**
 * Saves a high-resolution image using the camera's maximum resolution.
 */
void saveHighResImage() {
  println("Switching to high-resolution capture...");

  // Stop the current camera feed
  if (cam != null) {
    cam.stop();
  }

  // Reinitialize the camera at high resolution
  Capture highResCam = new Capture(this, highResWidth, highResHeight, selectedCamera);
  highResCam.start();

  // Wait until the high-resolution camera feed is available
  while (!highResCam.available()) {
    delay(100); // Wait for the camera to initialize
  }

  // Capture the frame and save it as a high-resolution image
  highResCam.read();
  highResCam.save("high_res_image.jpg");
  highResCam.stop();

  println("High-resolution image saved as high_res_image.jpg");

  // Reinitialize the preview camera
  initializeCamera(selectedCamera, previewWidth, previewHeight);
}
