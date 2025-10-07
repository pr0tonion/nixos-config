# What's Next - Improvements and Potential Issues

This document outlines potential improvements, missing features, and things you might want to add or fix.

## Immediate Post-Installation Tasks

After installing your system, you'll need to:

1. **Set SSH Keys**
   - Add your SSH public key to `modules/users.nix`
   - Rebuild the system

2. **Configure Tailscale**
   - Run `sudo tailscale up`
   - Authenticate with your Tailscale account

3. **Claim Plex Server**
   - Access http://server-ip:32400/web
   - Sign in with Plex account
   - Claim your server

4. **Add Media Libraries**
   - In Plex, add libraries pointing to `/srv/media/movies` and `/srv/media/tv`

5. **Configure Prowlarr**
   - Add your private tracker credentials
   - Get API key

6. **Connect Sonarr/Radarr to Prowlarr**
   - Add Prowlarr as indexer source
   - Add Transmission as download client

7. **Set Up Grafana**
   - Change default admin password
   - Import dashboards (IDs in monitoring.nix)

8. **Configure Homepage Dashboard**
   - Create `/etc/homepage/env` with API tokens
   - Restart homepage service

## Potential Issues to Fix

### Hardware-Specific

1. **Network Interface Name**
   - The hardware config uses a placeholder interface name
   - After installation, update with actual interface name
   - Location: `hosts/home-server/hardware-configuration.nix`

2. **Media Disk Configuration**
   - Current config assumes `/dev/disk/by-label/media` exists
   - You may need to adjust based on your actual disk setup
   - Consider using UUIDs instead of labels for stability

3. **GPU Passthrough**
   - Intel iGPU passthrough is configured but may need tweaking
   - Test Plex hardware transcoding after installation
   - May need to adjust `/dev/dri` permissions

### Service Configuration

1. **Transmission Password**
   - Default password needs to be set
   - First login via web UI will prompt for password setup

2. **Homepage Dashboard API Tokens**
   - Tokens need to be manually obtained from each service
   - Create `/etc/homepage/env` file
   - Instructions in `modules/services/dashboard.nix`

3. **Grafana Admin Password**
   - Default is set in `/etc/grafana/admin-password`
   - Change this immediately after first login

4. **Jellyseerr vs Overseerr**
   - Configuration uses Jellyseerr (in nixpkgs)
   - Overseerr may require manual packaging
   - Both serve the same purpose

### Network Configuration

1. **Static IP Not Configured**
   - Currently using DHCP
   - Consider setting static IP (see 04-network-management.md)
   - Or configure DHCP reservation in router

2. **Wake-on-LAN Interface**
   - Needs actual interface name after installation
   - Update `modules/networking.nix`

3. **Firewall Rules**
   - Review and adjust port openings
   - Some services may need additional ports
   - Currently all LAN-only (good for security)

## Recommended Improvements

### Security Enhancements

1. **SSL/TLS Certificates**
   - Add Let's Encrypt support for HTTPS
   - Use Nginx reverse proxy with SSL
   - Implementation:
     ```nix
     services.nginx = {
       enable = true;
       recommendedTlsSettings = true;
       virtualHosts."home-server.local" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass = "http://localhost:3001";
         };
       };
     };
     security.acme = {
       acceptTerms = true;
       defaults.email = "your-email@example.com";
     };
     ```

2. **Fail2Ban**
   - Add fail2ban for SSH protection
   - Location: `modules/security/fail2ban.nix`
   ```nix
   services.fail2ban = {
     enable = true;
     jails = {
       ssh.settings = {
         enabled = true;
         port = "22";
       };
     };
   };
   ```

3. **ClamAV Antivirus**
   - Scan downloaded media files
   - Integration with Transmission

4. **Two-Factor Authentication**
   - Add 2FA for SSH (google-authenticator)
   - Enable on all web services that support it

### Monitoring Enhancements

1. **Alerting**
   - Configure Prometheus Alertmanager
   - Email/SMS notifications for:
     - Service downtime
     - Disk space low
     - High CPU/memory usage
     - Failed logins

2. **Additional Exporters**
   - SMART monitoring for disk health (already included)
   - NVIDIA GPU exporter (if adding discrete GPU)
   - Custom exporters for Plex/Transmission metrics

3. **Log Analysis**
   - Already have Loki, but could add:
   - Log parsing for error detection
   - Anomaly detection
   - Better log retention policies

### Backup Solutions

1. **Automated Backups**
   - Borg Backup for service data
   - Automated media backup (or just keep ISO files)
   - Off-site backup to cloud storage

2. **Backup Module**
   Create `modules/backup.nix`:
   ```nix
   services.borgbackup.jobs.home-server = {
     paths = [
       "/var/lib/plex"
       "/var/lib/sonarr"
       "/var/lib/radarr"
       "/var/lib/transmission"
     ];
     repo = "/backup/borg-repo";
     encryption.mode = "repokey-blake2";
     startAt = "daily";
     prune.keep = {
       daily = 7;
       weekly = 4;
       monthly = 6;
     };
   };
   ```

3. **Snapshot Support**
   - Use BTRFS or ZFS for snapshots
   - Automatic snapshots before updates

### Media Management

1. **Bazarr for Subtitles**
   - Automatic subtitle downloads
   - Integration with Sonarr/Radarr

2. **Tautulli for Plex Statistics**
   - Track what's being watched
   - User statistics
   - Newsletter generation

3. **Organizr or Heimdall**
   - Alternative to Homepage
   - More features and customization

4. **Recyclarr**
   - Automated quality profile sync
   - TRaSH Guides integration

### Storage Improvements

1. **Media Organization**
   - Automatic file naming/organization
   - Filebot integration
   - Duplicate detection

2. **Storage Monitoring**
   - Disk usage alerts
   - Automatic cleanup of old downloads
   - Media library statistics

3. **RAID or ZFS**
   - Data redundancy
   - Automatic scrubbing
   - Snapshot support

### Automation

1. **Automatic Updates**
   - Automatic security updates
   - Service updates with testing
   - Configurable update windows

2. **Media Request Automation**
   - Auto-approve certain requests
   - User quotas in Overseerr
   - Integration with Discord/Telegram

3. **Health Checks**
   - Automated service health monitoring
   - Auto-restart failed services
   - Email notifications

### Additional Services

1. **Nextcloud**
   - Personal cloud storage
   - File sharing
   - Calendar/Contacts sync

2. **Bookstack or Wiki.js**
   - Documentation for your server
   - Knowledge base

3. **Vaultwarden**
   - Self-hosted password manager
   - Bitwarden compatible

4. **AdGuard Home / Pi-hole**
   - Network-wide ad blocking
   - DNS filtering

5. **Paperless-ngx**
   - Document management
   - OCR and tagging

6. **Home Assistant**
   - Smart home integration
   - Automation

7. **Frigate**
   - NVR with object detection
   - Security camera management

8. **Audiobookshelf**
   - Audiobook and podcast server

## Performance Optimizations

1. **Transcoding Optimization**
   - Fine-tune Plex hardware transcoding
   - Test different encoder settings
   - Monitor GPU usage

2. **Database Tuning**
   - PostgreSQL for Sonarr/Radarr (instead of SQLite)
   - Database maintenance scripts
   - Vacuum/optimize schedules

3. **Caching**
   - Redis for service caching
   - Nginx caching for static content
   - CDN for remote access (if needed)

4. **Resource Limits**
   - Fine-tune systemd resource limits
   - Prevent services from consuming too much
   - Currently set conservatively

## Missing Features

1. **Email Notifications**
   - No email configured
   - Services can't send notifications
   - Consider adding msmtp or similar

2. **Automatic Media Cleanup**
   - Script is conservative (doesn't delete)
   - Needs Plex API integration to check watch status
   - Consider JBOPS scripts

3. **UPS Support**
   - No UPS configuration
   - Add NUT (Network UPS Tools) if you have UPS

4. **Docker Support**
   - Currently no Docker
   - Some services might work better in Docker
   - Consider for services not in nixpkgs

5. **IPv6**
   - Not configured
   - May need adjustments for IPv6 networks

## Known Limitations

1. **Overseerr/Jellyseerr**
   - Using Jellyseerr as Overseerr isn't in nixpkgs
   - Functionality is similar but not identical

2. **Commercial VPN for Torrents**
   - Placeholder configuration only
   - Needs actual VPN setup
   - Provider-specific configuration required

3. **Mobile Apps**
   - Server-side only
   - Mobile app setup is manual (via app stores)

4. **Windows/Mac Clients**
   - No native configuration for non-Linux clients
   - Tailscale works, but apps need manual setup

## Documentation to Create

1. **Service Integration Guide**
   - How each service connects to others
   - API key management
   - Troubleshooting connections

2. **Media Workflow Guide**
   - From request to viewing
   - Quality profiles
   - Custom formats

3. **Troubleshooting Guide**
   - Common errors and solutions
   - Log locations
   - Debug procedures

4. **Upgrade Guide**
   - NixOS version upgrades
   - Service updates
   - Breaking changes

## Testing Checklist

After installation, test:

- [ ] SSH access works
- [ ] Tailscale connection established
- [ ] Plex accessible and can play media
- [ ] Sonarr can search and download
- [ ] Radarr can search and download
- [ ] Transmission downloads work
- [ ] Prowlarr indexers connected
- [ ] Jellyseerr requests work
- [ ] Grafana displays metrics
- [ ] Homepage shows all services
- [ ] Automated cleanup runs
- [ ] Wake-on-LAN works
- [ ] GPU transcoding works in Plex
- [ ] Logs are being collected
- [ ] Firewall rules are correct
- [ ] All services start on boot
- [ ] Rollback works

## Long-term Maintenance

1. **Regular Updates**
   - Update flake inputs monthly: `nix flake update`
   - Rebuild and test
   - Keep NixOS stable version current

2. **Security Audits**
   - Review user access quarterly
   - Check service exposure
   - Update passwords

3. **Backup Testing**
   - Test restores monthly
   - Verify backup completeness
   - Check backup retention

4. **Performance Review**
   - Monitor resource usage trends
   - Plan upgrades if needed
   - Optimize bottlenecks

5. **Documentation Updates**
   - Keep docs current with changes
   - Document custom configurations
   - Note lessons learned

## Getting Help

If you encounter issues:

1. **NixOS Community**
   - Discourse: https://discourse.nixos.org/
   - Reddit: r/NixOS
   - IRC: #nixos on Libera.Chat

2. **Service-Specific**
   - Plex Forums
   - Sonarr/Radarr Discord
   - Service GitHub issues

3. **Configuration Examples**
   - NixOS Search: https://search.nixos.org/
   - GitHub: Search for NixOS configurations
   - Wiki: https://nixos.wiki/

## Final Notes

This configuration provides a solid foundation for a home media server. However, every setup is unique. You'll likely need to:

- Adjust for your specific hardware
- Add services you use
- Remove services you don't need
- Tune performance for your use case
- Implement additional security measures
- Set up backups properly

The beauty of NixOS is that you can make these changes declaratively, test them safely, and roll back if needed. Don't be afraid to experiment!

Remember:
- Always commit to git before major changes
- Test in VMs when possible
- Keep backups of important data
- Document your customizations
- Ask for help when stuck

Good luck with your home server! 🚀
