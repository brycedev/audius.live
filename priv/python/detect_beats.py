import librosa
# from erlport.erlterms import Link
import json

def detect(audio_path):
    """Detects the beat of a song"""
    y, sr = librosa.load(audio_path)
    onset_frames = librosa.onset.onset_detect(
        y=y, sr=sr, wait=1, pre_avg=1, post_avg=1, pre_max=1, post_max=1
    )
    onset_times = librosa.frames_to_time(frames=onset_frames)
    printable_onset_times = ["%.4f" % onset_time for onset_time in onset_times]
    return json.dumps(printable_onset_times)
