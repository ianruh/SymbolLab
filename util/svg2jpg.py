#!/usr/bin/env python3
import sys
import os
from tqdm import tqdm

try:
    inkscape_path = os.environ['INKSCAPE_PATH']
except:
    print("Please set the INKSCAPE_PATH environment variable to the inkscape command line utility.")
    exit(1)

if(len(sys.argv) != 4):
    print("Usage: {} [svg dir] [jpg dir] [size]".format(sys.argv[0]))
    exit(1)

svg_dir = sys.argv[1]
jpg_dir = sys.argv[2]
size = sys.argv[3]

svg_files = [f for f in os.listdir(
    svg_dir) if os.path.isfile(os.path.join(svg_dir, f)) and f[-4:] == ".svg"]

files = ""
for f in svg_files:
    files += "{} ".format(os.path.join(svg_dir, f))

os.system("{} --export-type=png --export-background=white --export-background-opacity=255 --export-width={} --export-height={} {} > /dev/null 2>&1".format(inkscape_path, size, size, files))

for f in tqdm(svg_files):
    name = f[:-4]
    pngName = os.path.join(svg_dir, "{}.png".format(name))
    jpgName = os.path.join(jpg_dir, "{}.jpg".format(name))
    os.system("convert {} {} && rm {}".format(pngName, jpgName, pngName))
