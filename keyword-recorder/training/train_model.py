import os
import numpy as np
import librosa
import tensorflow as tf

FS = 16000
DURATION = 1.5
MFCC_BANDS = 40

def extract_features(file_path):
    # Load audio
    audio, sr = librosa.load(file_path, sr=FS)
    # Pad or truncate to exact length (1.5s = 24000 samples)
    target_len = int(FS * DURATION)
    if len(audio) < target_len:
        audio = np.pad(audio, (0, target_len - len(audio)))
    else:
        audio = audio[:target_len]
    
    # Extract MFCC
    mfcc = librosa.feature.mfcc(y=audio, sr=FS, n_mfcc=MFCC_BANDS, n_fft=1024, hop_length=512)
    # Transpose to (time_steps, features)
    return mfcc.T

def load_data(dataset_path):
    X = []
    y = []
    classes = ["noise", "straight_row"]
    
    for label, cls in enumerate(classes):
        cls_dir = os.path.join(dataset_path, cls)
        if not os.path.isdir(cls_dir): continue
        for f in os.listdir(cls_dir):
            if f.endswith('.wav'):
                feat = extract_features(os.path.join(cls_dir, f))
                X.append(feat)
                y.append(label)
                
    return np.array(X), np.array(y)

def main():
    print("Loading data and extracting acoustic features...")
    X, y = load_data("dataset")
    if len(X) == 0:
        print("ERROR: No data found! Please run record_samples.py first.")
        return
        
    print(f"Loaded {len(X)} audio samples. Feature shape: {X.shape}")
    
    # Reshape for Convolutional Neural Network (samples, time_steps, n_mfcc, channels)
    X = X[..., np.newaxis]
    
    # Shuffle and split data (80% train, 20% test)
    indices = np.arange(len(X))
    np.random.shuffle(indices)
    X = X[indices]
    y = y[indices]
    
    split = int(0.8 * len(X))
    X_train, X_test = X[:split], X[split:]
    y_train, y_test = y[:split], y[split:]
    
    # Build a lightweight AI Model for Mobile Devices
    input_shape = X_train.shape[1:]
    model = tf.keras.models.Sequential([
        tf.keras.layers.Conv2D(16, (3, 3), activation='relu', input_shape=input_shape),
        tf.keras.layers.MaxPooling2D((2, 2)),
        tf.keras.layers.Conv2D(32, (3, 3), activation='relu'),
        tf.keras.layers.MaxPooling2D((2, 2)),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(2, activation='softmax')
    ])
    
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    
    print("\nTraining AI Model...")
    model.fit(X_train, y_train, epochs=20, batch_size=8, validation_data=(X_test, y_test))
    
    # Test accuracy
    loss, acc = model.evaluate(X_test, y_test)
    print(f"\nFinal Test Accuracy: {acc*100:.2f}%")
    
    # Convert and export for Android
    print("\nConverting model to TensorFlow Lite format...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    with open("straight_row.tflite", "wb") as f:
        f.write(tflite_model)
        
    print("✅ SUCCESS! 'straight_row.tflite' has been generated.")
    print("Hand this file over to the Android App to use for offline keyword spotting!")

if __name__ == "__main__":
    main()
