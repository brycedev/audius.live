import os
import random
import subprocess
import requests
import json
import cv2
import pytesseract
import PIL


def fetch():
    api_key = "AIzaSyDUdj1ECjDHaunxmfzVP6Gtq5gylrHrXfs"
    limit = 15
    client_key = "audius_live"

    gif_object = json.loads(open("priv/static/gifs.json", "r").read())

    search_terms = [
        "music video dancing",
        "music video dance",
        "music video singing",
        "retro music video",
        "trippy loop",
        "psychedelic loop",
        "perfect loop",
        "vaporwave",
        "dance",
    ]

    random_term = random.choice(search_terms)

    r = requests.get(
        "https://tenor.googleapis.com/v2/search?q=%s&key=%s&client_key=%s&limit=%s&random=true&media_filter=mp4&ar_range=wide&contentfilter=high"
        % (random_term, api_key, client_key, limit)
    )

    files = []
    temp_urls = gif_object["urls"].copy()

    if r.status_code == 200:
        results = json.loads(r.content)["results"]
        for file in results:
            file_id = file["id"]
            file_url = file["media_formats"]["mp4"]["url"]

            if not file_url in temp_urls:
                gif_data = requests.get(file_url)

                directory = f"priv/static/gifs/{file_id}"

                subprocess.call(["mkdir", "-p", directory])

                gif_path = f"priv/static/gifs/{file_id}/gif.mp4"

                with open(gif_path, "wb") as gif_file:
                    gif_file.write(gif_data.content)

                    files.append(file_url)

                    subprocess.call(
                        ["ffmpeg", "-i", gif_path, f"{directory}/frame-%04d.jpg"]
                    )

                    frame_paths = []
                    for i in range(1, len(os.listdir(directory))):
                        frame_path = os.path.join(directory, f"frame-{i:04d}.jpg")
                        frame_paths.append(frame_path)

                    for path in frame_paths:
                        image = PIL.Image.open(path)
                        image.save(path, "JPEG")
                        if frame_contains_text(path):
                            files.remove(file_url)
                            break
                    # delete the gif folder
                    subprocess.call(["rm", "-rf", directory])

        for file in files:
            temp_urls.append(file)

        gif_object["urls"] = list(set(temp_urls))

        with open("priv/static/gifs.json", "w") as outfile:
            json.dump(gif_object, outfile)

        return
    else:
        return


def frame_contains_text(frame_path):
    image = cv2.imread(frame_path)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    text = pytesseract.image_to_string(gray)
    return len(text.strip()) > 0
