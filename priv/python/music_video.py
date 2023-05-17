import numpy as np
import random
import cv2
import json
import requests
from OpenGL.GL import *
from OpenGL.GL import shaders
from OpenGL.GLU import *
from PIL import Image
from moviepy.editor import (
    VideoClip,
    AudioFileClip,
    CompositeVideoClip,
    VideoFileClip,
    clips_array,
    concatenate_videoclips,
)
import moviepy.video.fx.all as vfx


def generate(audio_path, beat_times=[]):
    """Generates a music video from a song"""
    folder_path = audio_path.replace("audio.mp3", "")
    final_video_path = audio_path.replace(".mp3", ".mp4").replace("audio", "video")

    beat_times = [
        "2.7167",
        "2.8793",
        "3.3205",
        "5.0155",
        "5.4567",
        "6.2462",
        "8.0341",
        "9.6363",
        "10.1007",
        "10.5419",
        "11.3778",
        "11.7957",
        "11.9815",
        "12.8639",
        "13.0264",
        "14.5125",
        "14.9537",
        "15.6502",
        "16.1843",
        "16.4165",
        "16.8345",
        "17.2756",
        "17.9026",
        "18.1116",
        "18.5295",
        "18.7617",
        "18.9475",
        "19.1797",
        "19.6905",
        "19.8066",
        "20.2246",
        "20.4103",
        "20.6425",
        "20.8747",
        "21.0373",
        "21.2927",
        "21.4785",
        "22.3376",
        "22.9878",
        "23.1735",
        "24.0327",
        "24.8686",
        "25.7277",
        "26.5636",
        "27.4228",
        "28.2587",
        "29.5358",
        "29.6983",
        "32.9027",
        "34.9693",
        "36.2928",
        "36.7107",
        "37.1287",
        "37.9646",
        "39.0327",
        "39.6597",
        "43.2356",
        "44.7216",
        "49.8068",
        "51.4554",
        "51.6412",
        "53.1969",
        "54.8920",
        "56.5638",
        "57.0282",
        "57.8641",
        "58.2589",
        "58.7233",
        "59.5592",
        "59.9307",
        "60.3951",
        "60.8131",
        "61.1846",
        "61.6258",
        "62.2295",
        "62.5313",
        "62.9029",
        "63.3208",
        "63.7620",
        "64.4818",
        "64.6444",
        "65.0159",
        "65.4338",
        "65.7589",
        "66.2698",
        "66.7109",
        "67.1289",
        "67.5701",
        "67.9880",
        "68.3828",
        "68.8239",
        "69.2419",
        "69.6831",
        "70.1010",
        "70.5190",
        "70.9370",
        "71.7729",
        "71.9586",
        "73.4679",
        "73.6537",
        "73.8162",
        "74.3039",
        "74.7450",
        "75.1630",
        "75.5810",
        "75.7899",
        "77.0438",
        "77.1599",
        "77.4850",
        "79.1568",
        "79.3890",
        "79.5980",
        "80.0624",
        "80.2249",
        "80.4107",
        "80.5500",
        "81.7342",
        "81.9200",
        "82.3380",
        "82.5469",
        "82.8024",
        "84.0098",
        "85.7049",
        "85.9138",
        "86.0996",
        "86.3550",
        "86.4943",
        "86.5640",
        "87.4231",
        "87.6089",
        "88.2590",
        "88.6306",
        "89.0021",
        "89.0950",
        "89.8380",
        "89.9541",
        "90.5346",
        "90.7900",
        "91.6492",
        "92.4851",
        "93.3210",
        "94.1801",
        "95.0161",
        "95.8752",
        "96.9201",
        "100.4960",
        "102.5625",
        "103.8861",
        "104.0951",
        "104.7452",
        "105.5579",
        "107.2762",
        "107.6941",
        "109.3892",
        "110.6431",
        "110.8521",
        "112.1059",
        "112.3381",
        "114.0332",
        "114.8923",
        "115.3103",
        "115.7283",
        "116.5177",
        "118.2592",
        "118.7701",
        "119.2345",
        "120.7902",
        "122.4853",
        "123.7624",
        "124.1571",
        "125.0162",
        "125.6432",
        "125.8522",
        "126.0844",
        "126.2701",
        "126.7113",
        "126.9203",
        "127.1293",
        "127.5472",
        "127.7794",
        "127.9884",
        "128.1741",
        "128.3831",
        "128.8243",
        "129.1726",
        "129.2423",
        "129.4745",
        "129.6602",
        "129.8692",
        "130.1014",
        "130.2872",
        "130.4961",
        "130.9141",
        "131.1463",
        "131.3553",
        "131.5643",
        "131.7732",
        "131.9822",
        "132.2144",
        "132.4002",
        "132.5627",
        "132.6324",
        "133.0271",
        "133.4683",
        "133.6773",
        "133.8863",
        "134.3042",
        "134.5364",
        "134.7454",
        "134.9544",
        "135.1634",
        "135.5813",
        "135.9528",
        "135.9993",
        "136.2315",
        "136.4172",
        "136.6494",
    ]
    beat_times = [float(x) for x in beat_times]

    scene_types = ["grid", "reversey"]
    scenes = []

    while len(beat_times) > 0:
        num_beats = random.choice([*range(2, 10)])
        if num_beats > len(beat_times):
            num_beats = len(beat_times)
        scene_type = random.choice(scene_types)
        print(
            f"Generating {scene_type} for {num_beats} beats using {beat_times[:num_beats]}"
        )
        scenes.append(
            globals()[f"create_{scene_type}_scene"](
                folder_path, random.choice(*range(1,6)), beat_times[:num_beats]
            )
        )
        del beat_times[:num_beats]

    final_clip = concatenate_videoclips(scenes)
    final_clip.set_audio(AudioFileClip(audio_path))
    final_clip.write_videofile(final_video_path, fps=24)


def create_reversey_scene(path, gif_index, beat_times):
    offset = beat_times[0]
    beat_times = [float(x) - offset for x in beat_times]
    differentials = [
        beat_times[i + 1] - beat_times[i] for i in range(len(beat_times) - 1)
    ]

    gif_path = f"gifs/{gif_index}.gif"

    gif_clip = (
        VideoFileClip(gif_path)
        .fx(vfx.loop)
        .resize((1280, 720))
        .set_duration(max(differentials))
    )
    reversed_clip = gif_clip.fx(vfx.time_mirror)

    # Create the final clip by alternating between forward, reversed, and frozen frames
    clips = []
    for i in range(0, len(beat_times) - 1):
        if random.choice([0, 1]) == 0:
            clip = gif_clip.set_start(beat_times[i])
            clips.append(clip)
        else:
            clip = reversed_clip.set_start(beat_times[i])
            clips.append(clip)

    return concatenate_videoclips(clips)


def create_grid_scene(path, gif_index, beat_times=[]):
    """Creates a grid scene from a gif"""

    grid_counts = [4, 8, 16]
    grid_count = grid_counts[np.random.randint(0, 3)]

    gif_path = f"gifs/{gif_index}.gif"

    main_clip = VideoFileClip(gif_path).margin(5).fx(vfx.loop)
    main_clip_flipped_x = main_clip.fx(vfx.mirror_x)
    main_clip_flipped_y = main_clip.fx(vfx.mirror_y)
    main_clip_flipped_x_y = main_clip.fx(vfx.mirror_y).fx(vfx.mirror_x)

    offset = beat_times[0]
    beat_times = [float(x) - offset for x in beat_times]
    differentials = [
        beat_times[i + 1] - beat_times[i] for i in range(len(beat_times) - 1)
    ]

    clip_types = [
        main_clip,
        main_clip_flipped_x,
        main_clip_flipped_y,
        main_clip_flipped_x_y,
    ]

    grid_clips = []

    if grid_count == 4:
        grid_clips = [
            [random.choice(clip_types), random.choice(clip_types)],
            [random.choice(clip_types), random.choice(clip_types)],
        ]
    elif grid_count == 8:
        grid_clips = [
            [
                main_clip,
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
            ],
            [
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
            ],
        ]
    elif grid_count == 16:
        grid_clips = [
            [
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
            ],
            [
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
            ],
            [
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
            ],
            [
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
                random.choice(clip_types),
            ],
        ]

    for idx, x in enumerate(grid_clips):
        for idy, y in enumerate(x):
            grid_clips[idx][idy] = grid_clips[idx][idy].set_duration(max(differentials))

    return CompositeVideoClip([clips_array(grid_clips).resize((1280, 720))])


def get_image_from_giphy(keyword):
    """Gets an image from giphy"""
    api_key = "YOUR_API_KEY_HERE"
    query = f"trippy {keyword}"

    url = f"https://api.giphy.com/v1/gifs/search?q={query}&api_key={api_key}"

    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        for gif in data["data"]:
            gif_url = gif["images"]["downsized"]["url"]
            print(gif_url)
    else:
        print(f"Error retrieving GIFs: {response.status_code}")


def main():
    print("Hello World!")


if __name__ == "__main__":
    # get_image_from_giphy("nature")
    generate(
        "/Users/ghost/Code/dexterslab/audius_live/priv/static/tracks/1O4gPv5/audio.mp3"
    )


# def apply_shader(type):
#     """Applies a shader to the current frame"""
#     image = Image.open("path/to/image.png")

#     width, height = image.size

#     # Convert the image to a numpy array
#     image_data = np.array(image.getdata(), np.uint8).reshape(height, width, -1)

#     # Initialize PyOpenGL
#     glutInit()
#     glutInitDisplayMode(GLUT_RGBA)
#     glutInitWindowSize(width, height)
#     glutCreateWindow("OpenGL Window")

#     # Compile and link the shader program
#     vertex_shader = shaders.compileShader(
#         """
#         void main() {
#             gl_Position = ftransform();
#             gl_TexCoord[0] = gl_MultiTexCoord0;
#         }
#     """,
#         GL_VERTEX_SHADER,
#     )

#     fragment_shader = shaders.compileShader(
#         """
#         uniform sampler2D tex;
#         void main() {
#             vec4 texel = texture2D(tex, gl_TexCoord[0].st);
#             gl_FragColor = vec4(1.0 - texel.rgb, texel.a);
#         }
#     """,
#         GL_FRAGMENT_SHADER,
#     )

#     shader_program = shaders.compileProgram(vertex_shader, fragment_shader)

#     # Create a texture from the image data
#     texture_id = glGenTextures(1)
#     glBindTexture(GL_TEXTURE_2D, texture_id)
#     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
#     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
#     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
#     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
#     glTexImage2D(
#         GL_TEXTURE_2D,
#         0,
#         GL_RGBA,
#         width,
#         height,
#         0,
#         GL_RGBA,
#         GL_UNSIGNED_BYTE,
#         image_data,
#     )

#     # Render the texture with the shader program
#     glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
#     glUseProgram(shader_program)
#     glActiveTexture(GL_TEXTURE0)
#     glBindTexture(GL_TEXTURE_2D, texture_id)
#     glUniform1i(glGetUniformLocation(shader_program, "tex"), 0)
#     glBegin(GL_QUADS)
#     glTexCoord2f(0, 0)
#     glVertex3f(-1, -1, 0)
#     glTexCoord2f(1, 0)
#     glVertex3f(1, -1, 0)
#     glTexCoord2f(1, 1)
#     glVertex3f(1, 1, 0)
#     glTexCoord2f(0, 1)
#     glVertex3f(-1, 1, 0)
#     glEnd()
#     glutSwapBuffers()

#     # Save the rendered image to a file
#     pixels = glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE)
#     output_image = Image.frombytes("RGBA", (width, height), pixels)
#     output_image.save("path/to/output.png")


class ShaderClip(VideoClip):
    def __init__(self, clip, shader, duration=None):
        VideoClip.__init__(self, duration=duration)
        self.clip = clip
        self.shader = shader

    def make_frame(self, t):
        # Get the frame of the input clip at time t
        frame = self.clip.get_frame(t)

        # Convert the frame to a numpy array
        frame = np.array(frame)

        # Normalize the pixel values to the range [0, 1]
        frame = frame / 255.0

        # Apply the shader to the frame
        h, w = frame.shape[:2]
        for y in range(h):
            for x in range(w):
                uv = np.array([x / w, y / h])
                color = self.shader(uv, t)
                frame[y, x] = color

        # Convert the pixel values back to the range [0, 255]
        frame = (frame * 255.0).astype(np.uint8)

        return frame
