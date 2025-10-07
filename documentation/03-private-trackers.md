# Adding Private Trackers to Transmission

This guide explains how to configure Transmission for use with private torrent trackers.

## Important Configuration for Private Trackers

Private trackers have specific requirements that differ from public torrents. The Transmission configuration in this setup is already optimized for private trackers.

## Pre-Configured Settings

The following settings are already configured in `modules/services/torrent.nix`:

- **DHT**: Disabled (required for private trackers)
- **PEX**: Disabled (required for private trackers)
- **LPD**: Disabled (required for private trackers)
- **Encryption**: Required (recommended for privacy)
- **UTP**: Disabled (better compatibility)

## Adding Your Private Tracker

### Method 1: Web Interface

1. Access Transmission web UI: `http://server-ip:9091`
2. Log in with your credentials
3. Click "Open Torrent" button
4. Choose "Upload Torrent" or "Paste URL"
5. For URL method:
   - Copy the torrent URL from your private tracker
   - Paste into Transmission
   - Select download location
   - Click "Upload"

### Method 2: Watch Directory

1. Download the .torrent file from your private tracker
2. Copy it to the watch directory on your server:
   ```bash
   scp yourfile.torrent admin@server-ip:/srv/media/downloads/watch/
   ```
3. Transmission will automatically detect and start the download

### Method 3: Transmission Remote

From your local machine:

```bash
# Install transmission-remote
# On NixOS: nix-shell -p transmission
# On Ubuntu: apt install transmission-cli
# On macOS: brew install transmission-cli

# Add torrent
transmission-remote server-ip:9091 \
  --auth admin:password \
  --add /path/to/file.torrent
```

## Configuring Tracker-Specific Settings

### Setting Up Prowlarr with Private Trackers

Prowlarr manages indexers for Sonarr and Radarr:

1. Access Prowlarr: `http://server-ip:9696`

2. Go to **Settings** → **Indexers**

3. Click **Add Indexer** (the + button)

4. Search for your private tracker (e.g., "PassThePopcorn", "BroadcastTheNet")

5. Enter your tracker credentials:
   - Username
   - Password or Passkey
   - Cookie (if required)
   - API Key (if supported)

6. Configure tracker-specific settings:
   - Minimum seeders (recommended: 1)
   - Required flags
   - Categories to include

7. Click **Test** to verify credentials

8. Click **Save**

9. Go to **Settings** → **Apps** to connect Sonarr and Radarr:
   - Add Sonarr: http://localhost:8989
   - Add Radarr: http://localhost:7878
   - Enter the API keys from each app

### Common Private Trackers

Some popular private trackers that work well with this setup:

- **General**: TorrentLeech, IPTorrents
- **Movies**: PassThePopcorn, BroadcastHD
- **TV**: BroadcastTheNet, MoreThanTV
- **Anime**: AnimeTorrents, AnimeBytes

**Note**: You need to be a member of these trackers to use them.

## Maintaining Good Ratio

### Seeding Configuration

Edit `modules/services/torrent.nix` to adjust seeding behavior:

```nix
# Ratio limit settings
ratio-limit = 2.0;  # Stop seeding at 2:1 ratio
ratio-limit-enabled = true;

# Or seed forever (recommended for private trackers)
ratio-limit-enabled = false;
```

After editing:
```bash
sudo nixos-rebuild switch --flake /etc/nixos-config#home-server
```

### Monitor Your Ratio

Check your ratio on each tracker's website regularly. Most private trackers have minimum ratio requirements.

### Improving Upload Speed

1. **Port Forwarding** (if not using VPN):
   - Forward port 51413 (TCP/UDP) on your router
   - Set in Transmission settings

2. **Adjust Upload Limits**:
   - Edit `modules/services/torrent.nix`
   - Set `speed-limit-up` to 0 (unlimited)
   - Or set a specific value in KB/s

3. **Seed Popular Torrents**:
   - New releases tend to have more leechers
   - Seed longer for better ratio

## VPN Configuration for Torrent Traffic

### Why Use a VPN?

Even with private trackers, using a VPN provides additional privacy and security.

### Setting Up VPN with Transmission

If you want to route Transmission through a commercial VPN (like Mullvad, ProtonVPN):

1. **Get VPN Configuration**:
   - Download OpenVPN config from your VPN provider
   - Copy to server: `/etc/openvpn/transmission.conf`

2. **Edit `modules/services/vpn.nix`**:
   ```nix
   services.openvpn.servers = {
     transmission-vpn = {
       config = '' config /etc/openvpn/transmission.conf '';
       autoStart = true;
     };
   };
   ```

3. **Bind Transmission to VPN Interface**:
   Edit `modules/services/torrent.nix`:
   ```nix
   systemd.services.transmission.serviceConfig = {
     BindToDevice = "tun0";  # VPN interface
   };
   ```

4. **Rebuild**:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos-config#home-server
   ```

### VPN Kill Switch

The configuration includes a kill switch - if the VPN disconnects, Transmission will stop working until the VPN reconnects. This prevents IP leaks.

## Tracker Authentication

### Username/Password

Most trackers use simple username/password authentication through the tracker's announce URL embedded in the .torrent file.

### Passkey

Many private trackers use a passkey system:
- Your passkey is embedded in the tracker's announce URL
- Keep your passkey secret (don't share .torrent files)
- You can regenerate your passkey on the tracker website if compromised

### Cookie Authentication

Some trackers (like PTP) use cookies:
1. Log into the tracker website
2. Extract the required cookie from your browser
3. Add to Prowlarr indexer settings

## Troubleshooting

### Downloads not starting

1. Check tracker status on the tracker website
2. Verify your account is in good standing
3. Check Transmission logs:
   ```bash
   sudo journalctl -u transmission -f
   ```

### Not earning upload credit

1. Verify DHT/PEX/LPD are disabled
2. Check if you're connectable (port forwarding)
3. Ensure you're not hitting your upload limit
4. Some trackers don't count certain torrents

### Ratio too low

1. Seed new releases (fresher = more leechers)
2. Use freeleech torrents (download doesn't count)
3. Participate in tracker events
4. Consider a seedbox if your home upload is slow

### Transmission shows "unregistered torrent"

1. Re-download the .torrent file from the tracker
2. Your passkey may have been regenerated
3. Check if the torrent was deleted from the tracker

### VPN keeps disconnecting

1. Check VPN service logs:
   ```bash
   sudo journalctl -u openvpn-transmission-vpn -f
   ```
2. Verify VPN credentials are correct
3. Try a different VPN server
4. Check your internet connection

## Best Practices

1. **Always use the official .torrent file** from the tracker
2. **Seed to at least 1:1 ratio** (many trackers require this)
3. **Keep Transmission running 24/7** for better ratio
4. **Don't modify torrent files** after starting download
5. **Monitor your ratio** on each tracker regularly
6. **Use VPN** for additional privacy
7. **Keep your passkey secret** - treat it like a password
8. **Read tracker rules** - each has different requirements
9. **Participate in the community** - many trackers require forum activity
10. **Backup your torrent files** - helps with tracker migration

## Security Notes

- Never share your passkey or .torrent files from private trackers
- Use different passwords for each tracker
- Enable 2FA on trackers that support it
- Regularly check your tracker profile for unusual activity
- Don't use the same passkey on multiple trackers
- Keep your ratio above minimum requirements to avoid account deletion

## Additional Resources

- Transmission Documentation: https://transmissionbt.com/
- Most trackers have forums with setup guides
- Check tracker IRC/Discord for real-time support
