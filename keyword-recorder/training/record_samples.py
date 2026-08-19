import sounddevice as sd
from scipy.io.wavfile import write
import os

FS = 16000
DURATION = 1.5  # 1.5 seconds is perfect for "straight row"

def record_audio(filename):
    print("🟢 RECORDING NOW...")
    recording = sd.rec(int(DURATION * FS), samplerate=FS, channels=1, dtype='int16')
    sd.wait()
    write(filename, FS, recording)
    print(f"✅ Saved to {filename}")

def main():
    keyword = "straight_row"
    os.makedirs(f"dataset/{keyword}", exist_ok=True)
    os.makedirs("dataset/noise", exist_ok=True)
    
    print("===========================================")
    print(f"   VOICE RECORDER FOR '{keyword.upper()}'")
    print("===========================================")
    print("We need 40 samples of you saying the phrase.")
    print("Speak naturally, and vary your distance from the mic slightly.\n")
    
    for i in range(1, 41):
        input(f"Press [ENTER] to record sample {i}/40...")
        record_audio(f"dataset/{keyword}/{i}.wav")
        
    print("\n===========================================")
    print("          BACKGROUND NOISE")
    print("===========================================")
    print("Now we need 10 samples of standard background noise.")
    print("(e.g., Silence, typing on keyboard, breathing, coughing)")
    
    for i in range(1, 11):
        input(f"Press [ENTER] to record noise {i}/10...")
        record_audio(f"dataset/noise/{i}.wav")
        
    print("\n🎉 All done! You are ready to run train_model.py")

if __name__ == "__main__":
    main()
