# AvatarApp

A lightweight PNGTuber avatar app for Godot 4.7—cross-platform (Windows & macOS), reactive to your microphone, mouse, and keyboard.

## Features
- Idle, talking, writing, and pointing states driven by real input
- Directional look/point animation via an `AnimationTree` state machine
- Transparent, borderless, always-on-top overlay window
- Swappable skins (casual / strategy included)

## How it works
- **Microphone**—reads live input peak volume to detect talking
- **Mouse**—tracks speed/displacement to detect pointing, and position for directional look
- **Keyboard**—a small external Python listener (see below) detects typing activity

## Requirements
- Godot 4.7
- Python 3 (for the keyboard listener)—install `pynput`: `pip install pynput`

## Why an external keyboard listener?
Godot has no built-in way to read global keystrokes when the window isn't focused, so a small Python process listens system-wide and forwards key activity to the app over a local TCP socket. I'd have preferred to keep everything inside Godot, but this was the only reliable cross-platform option I found—happy to hear of alternatives. 🥺

## Platform notes
Windows and macOS handle click-through (mouse passthrough) differently at the OS level; macOS has a better system, and passthrough is as easy as it gets. Then, as most people have Windows, I needed a distinct window-offset workaround to keep the app 'universal' (see `MAIN.gd`). Linux is not currently targeted.

## License
The code is MIT-licensed (see `LICENSE`). **The sprite art is not**—see below.

## Assets & personal likeness
The character art in `assets/` is a personal streaming persona that I designed and use to represent myself. You're welcome to use it to learn from the *code*, but please don't reuse, redistribute, or present the art itself as your own avatar/persona. See `ASSETS_LICENSE.md` for the exact terms.

---
Cheers,
Mars!
