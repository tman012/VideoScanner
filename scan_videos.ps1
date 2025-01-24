################################################################################
# scan_videos.ps1
# ------------------------------------------------------------------------------
# A PowerShell script to check for video file corruption using ffmpeg.
# - Writes detailed logs to /logs/video_check.log.
# - Creates a dark-themed HTML summary page at /www/index.html.
# - As soon as any error is detected in a file (using the -xerror flag),
#   the file is marked as bad and immediately moved to a designated bad files folder.
################################################################################

# 1) Read configuration from environment variables (or use defaults)
$VideoDir = $env:VIDEO_DIR
if (-not $VideoDir) { $VideoDir = "/videos" }

# Define the directory where bad/corrupted files should be moved.
$BadDir = $env:BAD_DIR
if (-not $BadDir) { $BadDir = "$VideoDir/BadFiles" }

# Assume ffmpeg is available in PATH
$FfmpegExe = "ffmpeg"

# Define log and summary file paths
$LogFile = "/logs/video_check.log"
$SummaryFile = "/www/index.html"

# 2) Ensure the bad files directory exists
if (-not (Test-Path $BadDir)) {
    New-Item -ItemType Directory -Force -Path $BadDir | Out-Null
    "Created bad files directory: $BadDir" | Out-File $LogFile -Append
}

# 3) Build the dark-themed HTML header with a meta refresh of 1800 seconds (30 minutes)
$header = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Video Scan Summary</title>
  <!-- Refresh every 1800 seconds (30 minutes) -->
  <meta http-equiv="refresh" content="1800">
  <style>
    /* Global dark theme styling */
    body {
      font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
      background-color: #1E1E1E;
      color: #E0E0E0;
      margin: 0;
      padding: 0;
    }
    .container {
      width: 90%;
      max-width: 1200px;
      margin: 50px auto;
      background-color: #2D2D2D;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.5);
    }
    header {
      background-color: #3C3C3C;
      color: #E0E0E0;
      padding: 20px;
      text-align: center;
      border-top-left-radius: 8px;
      border-top-right-radius: 8px;
    }
    header h1 {
      margin: 0;
      font-size: 2em;
    }
    header p {
      margin: 5px 0 0;
      font-size: 1.1em;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
    }
    th, td {
      padding: 15px;
      text-align: left;
      border-bottom: 1px solid #444;
    }
    th {
      background-color: #3C3C3C;
    }
    tr:nth-child(even) {
      background-color: #272727;
    }
    tr:hover {
      background-color: #333;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>Video Scan Summary</h1>
      <p>Real-time status update</p>
    </header>
    <table>
      <thead>
        <tr>
          <th>File</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
"@

# 4) Footer to close HTML tags.
$footer = @"
      </tbody>
    </table>
  </div>
</body>
</html>
"@

# 5) Write the header to the summary file (overwriting any existing file)
$header | Out-File $SummaryFile

# Write an initial header to the log file.
"Video Corruption Check - $(Get-Date)" | Out-File $LogFile
"=====================================" | Out-File $LogFile -Append

# 6) Get all video files from the VideoDir.
$videoFiles = Get-ChildItem -Path $VideoDir -Recurse -Include *.mp4, *.mkv, *.avi, *.mov, *.m4v

if (-not $videoFiles) {
    Write-Output "No matching video files found in $VideoDir."
    "No matching video files found in $VideoDir." | Out-File $LogFile -Append
    "<tr><td colspan='2'>No matching video files found in $VideoDir.</td></tr>" | Out-File $SummaryFile -Append
    goto endScript
}

Write-Output "Found $($videoFiles.Count) file(s). Beginning scan..."
"Found $($videoFiles.Count) file(s). Beginning scan..." | Out-File $LogFile -Append
"-----------------------------------------------" | Out-File $LogFile -Append

# 7) Initialize an array to track files with errors (for logging purposes)
$filesWithErrors = @()

# 8) Process each video file sequentially.
foreach ($file in $videoFiles) {
    $filePath = $file.FullName
    
    # Log that the file is being checked.
    Write-Output "Checking $filePath..."
    "Checking $filePath..." | Out-File $LogFile -Append

    # Run ffmpeg in error-only mode with -xerror so it stops at the first error.
    $ffmpegOutput = & $FfmpegExe -xerror -v error -i "$filePath" -f null - 2>&1

    if ([string]::IsNullOrEmpty($ffmpegOutput)) {
        $status = "OK"
        Write-Output "Finished scanning $filePath (NO ERRORS)"
        "Finished scanning $filePath (NO ERRORS)" | Out-File $LogFile -Append
    }
    else {
        $status = "WITH ERRORS"
        Write-Output "Finished scanning $filePath (WITH ERRORS)"
        "Errors found for $($filePath):" | Out-File $LogFile -Append
        # Log only the first error line.
        $firstError = $ffmpegOutput.Split("`n")[0]
        $firstError | Out-File $LogFile -Append
        "Finished scanning $filePath (WITH ERRORS)" | Out-File $LogFile -Append
        $filesWithErrors += $filePath

        # Immediately move the file with errors into the bad files directory.
        try {
            Move-Item -Path $filePath -Destination $BadDir -Force
            $status = "WITH ERRORS (MOVED)"
            Write-Output "Moved $filePath to $BadDir"
            "Moved $($filePath) to $($BadDir)" | Out-File $LogFile -Append
        } catch {
            Write-Output "ERROR moving $($filePath): $($_)"
            "ERROR moving $($filePath): $($_)" | Out-File $LogFile -Append
        }
    }
    Write-Output "" | Out-File $LogFile -Append

    # Append a summary row to the HTML file for this file.
    $summaryRow = "<tr><td>$filePath</td><td>$status</td></tr>"
    $summaryRow | Out-File $SummaryFile -Append
}

:endScript
# 9) Append the footer to close the HTML document.
$footer | Out-File $SummaryFile -Append

Write-Output "-----------------------------------------------" | Out-File $LogFile -Append
if ($filesWithErrors.Count -gt 0) {
    Write-Output "Some files encountered errors. See the detailed log at '$LogFile'."
} else {
    Write-Output "All files scanned without errors."
}
Write-Output "Scan complete! View the summary at http://<YourHostIP>:<HostPort>/"
