{ config, pkgs, lib, ... }:

{
  # Automated media cleanup scripts

  # Script to clean up old unwatched media files
  systemd.services.media-cleanup = {
    description = "Clean up old unwatched media files";

    serviceConfig = {
      Type = "oneshot";
      User = "media";
      Group = "media";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/scripts/cleanup-media.sh";
    };
  };

  # Run cleanup weekly
  systemd.timers.media-cleanup = {
    description = "Run media cleanup weekly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h"; # Random delay to avoid exact scheduled time
    };
  };

  # Script to clean up temporary download files
  systemd.services.downloads-cleanup = {
    description = "Clean up temporary download files";

    serviceConfig = {
      Type = "oneshot";
      User = "transmission";
      Group = "transmission";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/scripts/cleanup-downloads.sh";
    };
  };

  # Run download cleanup daily
  systemd.timers.downloads-cleanup = {
    description = "Run download cleanup daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };

  # Create cleanup scripts directory
  systemd.tmpfiles.rules = [
    "d /etc/nixos/scripts 0755 root root -"
  ];

  # Create the cleanup scripts
  environment.etc."nixos/scripts/cleanup-media.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Cleanup old unwatched media files (older than 6 months)

      set -euo pipefail

      MEDIA_DIR="/srv/media"
      AGE_DAYS=180  # 6 months
      LOG_FILE="/var/log/media-cleanup.log"

      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting media cleanup..." >> "$LOG_FILE"

      # This is a placeholder - actual implementation depends on how you track watched status
      # You could integrate with Plex API to check watch status

      # Example: Find files older than 6 months (modify as needed)
      # find "$MEDIA_DIR" -type f -mtime +$AGE_DAYS -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" | while read -r file; do
      #   # Check if file has been watched using Plex API
      #   # If not watched, delete it
      #   echo "Would delete: $file" >> "$LOG_FILE"
      #   # rm "$file"  # Uncomment to actually delete
      # done

      # For now, just log what would be cleaned
      find "$MEDIA_DIR/movies" "$MEDIA_DIR/tv" -type f -mtime +$AGE_DAYS \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" \) 2>/dev/null | while read -r file; do
        echo "File older than $AGE_DAYS days: $file" >> "$LOG_FILE"
      done

      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Media cleanup completed" >> "$LOG_FILE"
    '';
    mode = "0755";
  };

  environment.etc."nixos/scripts/cleanup-downloads.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Cleanup temporary download files

      set -euo pipefail

      DOWNLOADS_DIR="/srv/media/downloads"
      LOG_FILE="/var/log/downloads-cleanup.log"

      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting downloads cleanup..." >> "$LOG_FILE"

      # Clean up incomplete downloads older than 7 days
      if [ -d "$DOWNLOADS_DIR/incomplete" ]; then
        find "$DOWNLOADS_DIR/incomplete" -type f -mtime +7 -delete 2>/dev/null || true
        find "$DOWNLOADS_DIR/incomplete" -type d -empty -delete 2>/dev/null || true
        echo "Cleaned incomplete downloads" >> "$LOG_FILE"
      fi

      # Clean up .part files
      find "$DOWNLOADS_DIR" -name "*.part" -mtime +7 -delete 2>/dev/null || true

      # Clean up empty directories
      find "$DOWNLOADS_DIR" -type d -empty -delete 2>/dev/null || true

      # Clean up old torrent files from watch directory
      if [ -d "$DOWNLOADS_DIR/watch" ]; then
        find "$DOWNLOADS_DIR/watch" -name "*.torrent" -mtime +30 -delete 2>/dev/null || true
        echo "Cleaned old torrent files" >> "$LOG_FILE"
      fi

      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Downloads cleanup completed" >> "$LOG_FILE"
    '';
    mode = "0755";
  };

  # Create log directory
  systemd.tmpfiles.rules = [
    "d /var/log 0755 root root -"
    "f /var/log/media-cleanup.log 0644 media media -"
    "f /var/log/downloads-cleanup.log 0644 transmission transmission -"
  ];

  # Log rotation for cleanup logs
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/media-cleanup.log" = {
        frequency = "weekly";
        rotate = 4;
        compress = true;
        missingok = true;
        notifempty = true;
      };
      "/var/log/downloads-cleanup.log" = {
        frequency = "weekly";
        rotate = 4;
        compress = true;
        missingok = true;
        notifempty = true;
      };
    };
  };

  # NOTE: The media cleanup script is conservative by default
  # It only logs what would be deleted without actually deleting
  # To enable actual deletion:
  # 1. Review the logs at /var/log/media-cleanup.log
  # 2. Modify the script to uncomment the deletion commands
  # 3. Consider integrating with Plex API to check watch status
  #    using tools like: https://github.com/blacktwin/JBOPS
}
