import librosa
import sys

# Load the audio file
file_path = sys.argv[1]
y, sr = librosa.load(file_path)

# Detect beats using librosa
tempo, beats = librosa.beat.beat_track(y=y, sr=sr)

# Convert the beat frames to seconds
beat_times = librosa.frames_to_time(beats, sr=sr)

# Output the beat times in seconds
print("\n".join(str(t) for t in beat_times))
