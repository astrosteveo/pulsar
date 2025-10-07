# Assets

## Recording a quick demo GIF

Goal: a crisp, <15s loop showing “copy Quick Start → first-run auto-clone/load → prompt ready.” Target size <2MB.

What to show

- Temporary config dir (clean env)
- Download pulsar.zsh
- Define PULSAR_* arrays (declarative)
- source pulsar.zsh (first run clones; second run is instant)
- One quick proof the plugin works (e.g., zsh-bench on PATH or prompt init)

General tips

- Use a dark high-contrast theme; font 14–16px; ~900–1100 px width.
- Keep motion minimal; prefer concise commands; remove terminal chrome if possible.
- Looping GIFs should end where they begin (clear screen right before the cut).

Tools (pick one)

- Cross-platform: asciinema + agg (high quality terminal GIF)
- macOS: Kap / CleanShot X
- Linux: Peek / vokoscreenNG / wf-recorder
- Any OS: OBS → MP4 → GIF (gifski/ffmpeg) if you need post-processing

Recipe: asciinema → GIF (recommended)

```bash
# 1) Record a cast of just the terminal text
asciinema rec -c "zsh -f" assets/pulsar-demo.cast

# 2) Render to GIF with agg (https://github.com/asciinema/agg)
#    macOS: brew install asciinema agg
#    Linux: pacman -S asciinema (Arch) and download agg from releases, or use your package manager
#    Note: agg v1.6+ uses positional args: agg <input.cast> <output.gif>
agg assets/pulsar-demo.cast assets/pulsar-demo.gif \
      --font-size 16 \
      --theme dracula

# Optional: if the file is big, optimize
gifsicle -O3 --lossy=20 -o assets/pulsar-demo.gif assets/pulsar-demo.gif
```

Recipe: screen recorder → MP4 → optimized GIF

```bash
# Record ~10–15s at 10–15 fps, crop to the terminal region

# Generate a palette and then a high-quality GIF with ffmpeg
ffmpeg -i demo.mp4 -vf "fps=12,scale=1000:-1:flags=lanczos,palettegen" -y palette.png
ffmpeg -i demo.mp4 -i palette.png -lavfi "fps=12,scale=1000:-1:flags=lanczos[x];[x][1:v]paletteuse" -y assets/pulsar-demo.gif

# Optional: further optimize
gifsicle -O3 --lossy=20 -o assets/pulsar-demo.gif assets/pulsar-demo.gif
```

Suggested recording script (for the session you record)

```zsh
# Clean, reproducible session
TMPDIR=$(mktemp -d)
export ZSH="$TMPDIR/zsh"
mkdir -p "$ZSH/lib"

# Download Pulsar
curl -fsSL -o "$ZSH/lib/pulsar.zsh" \
   https://raw.githubusercontent.com/astrosteveo/pulsar/main/pulsar.zsh

# Declarative config
PULSAR_PLUGINS=(zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting)
PULSAR_AUTOCOMPILE=1

# First run: clones + loads
source "$ZSH/lib/pulsar.zsh"

# Optional: show it’s instant the second time
exec zsh -i
```

Checklist

- Duration 8–15s; readable font; no extraneous motion.
- Verify the loop point looks clean (use `clear` or reset before cut).
- File saved to `assets/pulsar-demo.gif` and referenced in README.

Notes

- If size exceeds ~2MB, prefer optimizing with gifsicle first. If still large, reduce terminal width before recording (cast inherits cols/rows), or re-render at a smaller window size.
- Prefer declarative arrays that yield visible effects (autosuggestions, syntax-highlighting, prompt init).
