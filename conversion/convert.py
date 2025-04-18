import os
import subprocess

# ffmpeg must be installed as a subfolder in the current directory
ffmpeg_cmd = str("./ffmpeg/bin/ffmpeg.exe")

# Path to the folder containing the audio files
corpus_path = str("D:\Dropbox\Me\Embers Complete")

def scan_folder(folder_path):
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            perform_conversion(root, file)
            
def perform_conversion(root, file):
    file_path = os.path.join(root, file)
    file_without_extension, file_extension = os.path.splitext(file)
    target_filepath = "result/"+file_without_extension+".flac"

    result = subprocess.run(
        [ffmpeg_cmd, "-i", file_path, target_filepath], 
        capture_output=True, text=True)
    print("Saved "+ +"to "+target_filepath)

# Example usage
scan_folder(corpus_path)
