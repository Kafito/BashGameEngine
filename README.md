# Bash game engine
---
**Note**:

This is a project meant for experimentation and it is currently on hold.
Therefore the code is not cleaned nor documented appropriately to support any
curious eyes. You are on your own.

---

TODO: Add animated image sequence of the current state.

## Motivation / Goals

This project was inspired by the series of
[One lone coder](https://www.youtube.com/channel/UC-yuWVUplUJZvieEligKBkA/videos)
about his console game engine (and later pixel game engine).

Seeing how he implemented a simple version of a Wolfenstein-like renderer for
the console, and then built upon this experiment to try out other techniques
and algorithms, up to the implementation of a rudimentary 3D-rasterization
engine with texturing, inspired me to try and so something similar, however
with a different flavor.

So I started this project with the following goals

Goals:
* Implement a Wolfenstein-like renderer in pure bash 
* Experiment and work out algorithms and drawing routines for bashs integer
  based nature myself with my current state of knowledge, i.e. without further
  research.

## State

Currently, the project contains implementations for the following:
* Integer math drawing methods for
  * lines
  * circles (corrected for non-square font geometry)
* Map renderer (including unlimited zooming)
* Ray casting, visualized in the map renderer.
* Simple collision detection between a 'player' and the map.
* Integer-based rescaling of vectors to a specific length.
   TODO: Add octave script for the approximation and images.

## Bash specifics
Bash is a very special beast. Some of its interesting properties, that I needed
to work around, are:
* Only integer math (starting new processes takes too much time, also it is not
  'pure bash' then).
* Performance considerations
  * Calling functions take significantly more time than inlined code.
  * Longer variable names -> less performance.
  * Output is slow. Outputting long strings is significantly faster than
    printing them character by character (Note: in my case I developed and
    therefore optimized for transfer over SSH, might be different locally.)
  * Arrays are incredibly slow.
  * Variable declaration / initialization impacts performance based on how it
    was done.
  * Variable scopes have an impact on performance.


Note: This list has been created from my memory. Since the project has been on
halt for more than a year now, I do not remember exactly every detail and which
approaches worked for me best.

## Readme TODO: 
* Add animation of current state. (LFS?)
* Add matlab document + image (LFS?)

## How to Run:
1. Launch the ./run script (it's a symlink for now).
1. There might be a 'read', before the actual rendering starts. -> Press 'Return'.
1. Keys:
  * Player movement has been implemented with the WASD layout.
  * Camera movement is implemented with a IJKL layout. Camera follow can be toggled with 'f'.
  * For other keys, check the source (search for 'case "$input" in').
