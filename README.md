![Video Scanner Icon](images/icon.png) # Video Scanner Docker 




This repository provides a Docker container that scans video files for corruption using **ffmpeg**. It uses a PowerShell script (`scan_videos.ps1`) to:

- Enumerate all video files (`.mp4`, `.mkv`, `.avi`, `.mov`, `.m4v`) in a specified directory.
- Immediately move any file that ffmpeg deems corrupted into a "bad files" directory.
- Write real-time logs to a log file.
- Generate an HTML summary (auto-refresh) for easy viewing in a web browser.

---

## Features

1. **Auto-Move on Error**: If ffmpeg encounters corruption (`-xerror`), the script moves that file into your designated `BAD_DIR`.
4. **No Manual CLI**: If installed on Unraid via the Community Apps plugin, you can easily configure everything (paths, environment variables) through the Unraid UI.

---

## Directory Structure

