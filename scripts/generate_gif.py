#!/usr/bin/env python3
"""
generate_gif.py
Converts a video file to a GIF optimised for iOS/iPhone display using FFmpeg.

Usage:
    python scripts/generate_gif.py <input_video> [options]

Options:
    --output  PATH    Output GIF path (default: output_ios.gif)
    --fps     INT     Frames per second (default: 12)
    --width   INT     Output width in pixels; height auto-scaled (default: 480)
    --max-mb  FLOAT   Abort if output exceeds this size in MB (default: 15)
    --start   TIME    Start time in HH:MM:SS or seconds (optional)
    --duration SECS   Duration in seconds to encode (optional)

Examples:
    # Basic conversion
    python scripts/generate_gif.py clip.mp4

    # Custom frame rate and width
    python scripts/generate_gif.py clip.mp4 --fps 10 --width 360

    # Trim a 5-second clip starting at 00:00:03
    python scripts/generate_gif.py clip.mp4 --start 3 --duration 5

Requirements:
    - FFmpeg must be installed and available on $PATH.
    - Python 3.7+

iOS optimisation notes:
    - fps=12 keeps file size manageable on older iPhones (A12 and earlier).
    - width=480 matches typical Instagram Story display resolution.
    - The lanczos filter produces sharper results than the default bilinear.
    - Two-pass palette generation (palettegen + paletteuse) maximises colour
      fidelity within the 256-colour GIF palette limit.
    - Output must be ≤ 15 MB for GIPHY upload and reliable iOS playback.
"""

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DEFAULT_FPS    = 12
DEFAULT_WIDTH  = 480
DEFAULT_MAX_MB = 15.0
DEFAULT_OUTPUT = 'output_ios.gif'


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def require_ffmpeg():
    """Abort if ffmpeg is not found on PATH."""
    result = subprocess.run(
        ['ffmpeg', '-version'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        sys.exit('ERROR: ffmpeg is not installed or not on PATH.')


def build_filter(fps: int, width: int, palette_path: str, pass_: int) -> str:
    """
    Build the FFmpeg -vf filter chain for two-pass palette GIF encoding.

    pass_=1  generates the palette PNG.
    pass_=2  uses the palette PNG to encode the final GIF.
    """
    scale = f'scale={width}:-1:flags=lanczos'
    fps_f = f'fps={fps}'
    if pass_ == 1:
        return f'{fps_f},{scale},palettegen=max_colors=256:stats_mode=diff'
    # pass 2
    return f'{fps_f},{scale} [x]; [x][1:v] paletteuse=dither=bayer:bayer_scale=5'


def run(cmd: list, label: str):
    """Run a shell command and abort on non-zero exit."""
    print(f'[generate_gif] {label}')
    result = subprocess.run(cmd)
    if result.returncode != 0:
        sys.exit(f'ERROR: {label} failed (exit {result.returncode})')


# ---------------------------------------------------------------------------
# Core conversion
# ---------------------------------------------------------------------------

def convert(input_path: str, output_path: str, fps: int, width: int,
            max_mb: float, start: str = None, duration: str = None):
    require_ffmpeg()

    with tempfile.TemporaryDirectory() as tmpdir:
        palette = os.path.join(tmpdir, 'palette.png')

        # --- Build common seek/trim args ---
        seek_args = []
        if start:
            seek_args += ['-ss', str(start)]
        if duration:
            seek_args += ['-t', str(duration)]

        # --- Pass 1: generate palette ---
        pass1_cmd = (
            ['ffmpeg', '-y']
            + seek_args
            + ['-i', input_path]
            + ['-vf', build_filter(fps, width, palette, pass_=1)]
            + ['-frames:v', '1', palette]
        )
        run(pass1_cmd, 'Pass 1: generating palette')

        # --- Pass 2: encode GIF using palette ---
        pass2_cmd = (
            ['ffmpeg', '-y']
            + seek_args
            + ['-i', input_path, '-i', palette]
            + ['-lavfi', build_filter(fps, width, palette, pass_=2)]
            + ['-loop', '0', output_path]
        )
        run(pass2_cmd, 'Pass 2: encoding GIF')

    # --- Size check ---
    size_mb = Path(output_path).stat().st_size / (1024 * 1024)
    print(f'[generate_gif] Output: {output_path} ({size_mb:.2f} MB)')

    if size_mb > max_mb:
        sys.exit(
            f'ERROR: Output GIF is {size_mb:.2f} MB, exceeding the '
            f'{max_mb} MB limit. Reduce --fps, --width, or --duration.'
        )

    print('[generate_gif] Done.')


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description='Convert a video to an iOS-optimised GIF using FFmpeg.'
    )
    parser.add_argument('input', help='Input video file (mp4, mov, avi, ...)')
    parser.add_argument('--output',   default=DEFAULT_OUTPUT, help='Output GIF path')
    parser.add_argument('--fps',      type=int,   default=DEFAULT_FPS,    help='Frames per second')
    parser.add_argument('--width',    type=int,   default=DEFAULT_WIDTH,  help='Output width (px)')
    parser.add_argument('--max-mb',   type=float, default=DEFAULT_MAX_MB, help='Max output size (MB)')
    parser.add_argument('--start',    default=None, help='Start time (HH:MM:SS or seconds)')
    parser.add_argument('--duration', default=None, help='Duration in seconds')
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    if not os.path.isfile(args.input):
        sys.exit(f'ERROR: Input file not found: {args.input}')
    convert(
        input_path=args.input,
        output_path=args.output,
        fps=args.fps,
        width=args.width,
        max_mb=args.max_mb,
        start=args.start,
        duration=args.duration,
    )
