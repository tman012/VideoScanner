# Use PowerShell base image
FROM mcr.microsoft.com/powershell:latest

# Install ffmpeg, python3, and dos2unix
RUN apt-get update && apt-get install -y ffmpeg python3 dos2unix && apt-get clean

# Create necessary directories
RUN mkdir -p /www /logs

# Copy in our scripts and web files
COPY scan_videos.ps1 /scan_videos.ps1
COPY run.sh /run.sh
COPY index.html /www/index.html

# Convert run.sh to Unix line endings and set as executable
RUN dos2unix /run.sh
RUN chmod +x /run.sh

# Expose the port that our HTTP server will use
EXPOSE 8080

# Set the container's entrypoint to run our script
CMD ["/run.sh"]
