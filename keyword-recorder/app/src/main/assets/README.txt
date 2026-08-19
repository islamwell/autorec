=====================================================================
TENSORFLOW LITE MODEL ASSETS FOLDER
=====================================================================

When you run `python training/train_model.py` on your computer, it will generate a neural network file named:
    straight_row.tflite

To enable offline AI keyword recognition in the Android app:
1. Copy `straight_row.tflite` into this exact directory:
   app/src/main/assets/straight_row.tflite

2. Rebuild and install the Android app. The app will automatically detect the neural network file and switch from classical DTW acoustic matching to real-time Convolutional Neural Network (CNN) keyword spotting!
