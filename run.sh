#!/usr/bin/env bash

rm out* || true

ruby main.rb $1 back.jpg

ruby text.rb $2

ffmpeg -r 5 -i out_%03d.png -i music.m4a -c:v libx264 -vf fps=25 -pix_fmt yuv420p out.mp4

rm out*.png
