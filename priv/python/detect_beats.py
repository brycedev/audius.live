import librosa
import json


def detect(audio_path):
    """Detects the beat of a song"""
    print(audio_path)
    y, sr = librosa.load(audio_path)
    onset_frames = librosa.onset.onset_detect(
        y=y, sr=sr, wait=1, pre_avg=1, post_avg=1, pre_max=1, post_max=1
    )
    onset_times = librosa.frames_to_time(frames=onset_frames)

    onset_time_deltas = []

    for i in range(1, len(onset_times)):
        if i == 0:
            onset_time_deltas.append(onset_times[i])
            continue
        onset_time_deltas.append(onset_times[i] - onset_times[i - 1])

    onset_time_deltas_to_frames = [int(delta * 24) for delta in onset_time_deltas]
    print(onset_time_deltas_to_frames)
    return json.dumps(onset_time_deltas_to_frames)
