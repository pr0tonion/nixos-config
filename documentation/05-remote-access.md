# Remote Access Guide

This guide explains how to access your home server remotely using Tailscale and other methods.

## Tailscale VPN (Recommended)

Tailscale provides secure, encrypted remote access without port forwarding or complex network configuration.

### Initial Setup

On your home server (already installed via the configuration):

```bash
# Start Tailscale
sudo tailscale up

# Follow the URL to authenticate
# This will open in your browser and connect to your Tailscale account
```

The authentication URL will look like:
```
https://login.tailscale.com/a/xxxxxxxxxxxx
```

### Installing Tailscale on Client Devices

#### macOS / Windows / Linux Desktop

1. Download from: https://tailscale.com/download
2. Install and run
3. Sign in with the same account used for the server
4. Your server will appear in the Tailscale network

#### iOS / Android

1. Install Tailscale app from App Store / Play Store
2. Sign in with your account
3. Connect to your network

#### Another Linux Machine

```bash
# On NixOS
nix-shell -p tailscale
sudo systemctl start tailscaled
sudo tailscale up

# On Ubuntu/Debian
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Accessing Your Server

Once connected to Tailscale:

```bash
# Find your server's Tailscale IP
tailscale ip -4

# Or use MagicDNS (enabled by default)
# Your server is accessible as: home-server
```

#### Access Services:

```
http://home-server:32400/web    # Plex
http://home-server:8989         # Sonarr
http://home-server:7878         # Radarr
http://home-server:9091         # Transmission
http://home-server:3000         # Grafana
http://home-server:3001         # Homepage Dashboard
```

Or using the Tailscale IP:
```
http://100.x.x.x:32400/web
```

### SSH via Tailscale

```bash
ssh admin@home-server

# Or using Tailscale IP
ssh admin@100.x.x.x
```

### Subnet Routing (Access Entire Home Network)

Enable subnet routing to access all devices on your home network:

```bash
# On the home server
sudo tailscale up --advertise-routes=192.168.1.0/24
```

Replace `192.168.1.0/24` with your actual home network subnet.

Then approve the route in Tailscale Admin Console:
1. Go to https://login.tailscale.com/admin/machines
2. Find your home-server
3. Click "..." → "Edit route settings"
4. Approve the subnet route

Now you can access ANY device on your home network via Tailscale:
```
http://192.168.1.1  # Your router
http://192.168.1.x  # Any other device
```

### Exit Node (Use Server as VPN)

Make your home server a Tailscale exit node:

```bash
# On the server
sudo tailscale up --advertise-exit-node
```

Approve in admin console (same process as subnet routing).

Then on client devices:
```bash
# Use home server as exit node
tailscale up --exit-node=home-server
```

All your internet traffic will route through your home server.

### Tailscale Features

- **MagicDNS**: Access devices by hostname instead of IP
- **Encrypted**: All traffic is encrypted end-to-end
- **NAT Traversal**: Works even behind NAT/firewall
- **No Port Forwarding**: No router configuration needed
- **Access Controls**: Fine-grained access control via admin console
- **Multi-Platform**: Works on all major platforms

### Tailscale Admin Console

Manage your network at: https://login.tailscale.com/admin

- View all connected devices
- Manage access controls
- Approve subnet routes and exit nodes
- Share devices with other users
- View connection status and logs

## Alternative: WireGuard VPN

If you prefer WireGuard over Tailscale, uncomment the WireGuard configuration in `modules/services/vpn.nix`.

### Setup WireGuard Server

1. Generate server keys:
   ```bash
   wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key
   sudo chmod 600 /etc/wireguard/private.key
   ```

2. Edit `modules/services/vpn.nix` and uncomment the WireGuard section

3. Configure the server:
   ```nix
   networking.wireguard.interfaces = {
     wg0 = {
       ips = [ "10.100.0.1/24" ];
       listenPort = 51820;
       privateKeyFile = "/etc/wireguard/private.key";

       peers = [
         # Add client configurations here
       ];
     };
   };
   ```

4. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos-config#home-server
   ```

5. Forward port 51820 UDP on your router to the server

### Setup WireGuard Client

1. Generate client keys:
   ```bash
   wg genkey | tee client-private.key | wg pubkey > client-public.key
   ```

2. Add client to server config in `modules/services/vpn.nix`:
   ```nix
   peers = [
     {
       publicKey = "CLIENT_PUBLIC_KEY";
       allowedIPs = [ "10.100.0.2/32" ];
     }
   ];
   ```

3. Create client config:
   ```ini
   [Interface]
   PrivateKey = CLIENT_PRIVATE_KEY
   Address = 10.100.0.2/24
   DNS = 1.1.1.1

   [Peer]
   PublicKey = SERVER_PUBLIC_KEY
   Endpoint = YOUR_PUBLIC_IP:51820
   AllowedIPs = 0.0.0.0/0
   PersistentKeepalive = 25
   ```

4. Import config on client device

**Note**: WireGuard requires port forwarding and doesn't have the NAT traversal capabilities of Tailscale.

## SSH Remote Access

### Via Tailscale (Recommended)

```bash
ssh admin@home-server
```

### Via Dynamic DNS + Port Forward (Not Recommended)

1. Set up dynamic DNS (DuckDNS, No-IP, etc.)
2. Forward port 22 on router (or use a different port)
3. SSH using: `ssh -p PORT admin@your-domain.duckdns.org`

**Security risks**: Exposing SSH to the internet increases attack surface. Use Tailscale instead.

### SSH Hardening (If Exposing to Internet)

Edit `modules/networking.nix`:

```nix
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    AllowUsers = [ "admin" ];  # Only allow specific users
  };
  ports = [ 2222 ];  # Use non-standard port
};

services.fail2ban = {
  enable = true;
  jails = {
    ssh.enabled = true;
  };
};
```

## Plex Remote Access

### Via Plex Relay (Easiest)

Plex includes built-in remote access:

1. Access Plex: http://server-ip:32400/web
2. Go to Settings → Remote Access
3. Enable "Remote Access"
4. Plex will attempt automatic setup

This works through Plex's relay servers (slower but easy).

### Via Tailscale (Best Performance)

Access Plex through Tailscale for full bandwidth:

```
http://home-server:32400/web
```

On mobile apps:
1. Connect to Tailscale
2. Plex will auto-discover the server on the network

### Via Port Forward (Not Recommended)

Forward port 32400 on your router to the server. This exposes Plex to the internet.

## Mobile Apps and Tailscale

### iOS

1. Install Tailscale from App Store
2. Connect to your network
3. Apps (Plex, etc.) will work as if you're on the home network

### Android

Same as iOS - install Tailscale, connect, and apps work normally.

### Always-On VPN

Configure Tailscale to auto-connect:
- iOS: Settings → VPN → Connect On Demand
- Android: Settings → Always-on VPN

## Monitoring Remote Connections

### View Tailscale Status

```bash
# On the server
tailscale status

# View detailed info
tailscale status --json

# View logs
sudo journalctl -u tailscaled -f
```

### View SSH Connections

```bash
# Current SSH sessions
who

# SSH authentication logs
sudo journalctl -u sshd -f

# All authentication attempts
sudo journalctl | grep sshd
```

### Grafana Monitoring

Access Grafana remotely via Tailscale:
```
http://home-server:3000
```

Set up alerts for unusual activity:
- High bandwidth usage
- Failed SSH attempts
- Service downtime

## Bandwidth Considerations

### Plex Streaming Quality

When remote:
1. Adjust quality settings in Plex app
2. Lower quality = less bandwidth
3. Consider using Tailscale subnet routing for better performance

### Tailscale Direct Connections

Tailscale uses direct connections when possible (no relay):
- Check with: `tailscale status`
- "direct" means peer-to-peer connection
- "relay" means going through Tailscale servers

### VPN vs Direct Access Performance

- **Tailscale Direct**: ~90% of native speed
- **Tailscale Relay**: 20-50 Mbps typical
- **WireGuard**: ~95% of native speed
- **Port Forward**: 100% but less secure

## Security Best Practices

1. **Use Tailscale** instead of exposing services to internet
2. **Enable 2FA** on Tailscale account
3. **Use SSH keys** only, no passwords
4. **Keep software updated**: `sudo nixos-rebuild switch`
5. **Monitor access logs** regularly
6. **Use strong passwords** for all service web interfaces
7. **Enable MFA** where available (Plex, etc.)
8. **Limit access** using Tailscale ACLs if sharing with others
9. **Regular security audits**: Review who has access
10. **Backup** your configuration regularly

## Access Control Lists (Tailscale)

Restrict what devices can access what services:

1. Go to https://login.tailscale.com/admin/acls
2. Edit the ACL policy:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["home-server:*"]
    },
    {
      "action": "accept",
      "src": ["user@example.com"],
      "dst": ["home-server:22"]
    }
  ]
}
```

This allows fine-grained control over who can access what.

## Sharing Access with Others

### Sharing Plex

1. Plex has built-in user management
2. In Plex settings, invite users by email
3. They don't need Tailscale access

### Sharing Other Services

Create separate Tailscale users or use sharing:

1. In Tailscale admin console
2. Share specific device with another user
3. They can access only what you share

### Creating Guest Access

For temporary access:

1. Use Tailscale's sharing feature (24 hours)
2. Or create a temporary WireGuard config
3. Revoke when no longer needed

## Troubleshooting

### Can't connect via Tailscale

1. Check Tailscale is running:
   ```bash
   sudo systemctl status tailscaled
   ```

2. Verify logged in:
   ```bash
   tailscale status
   ```

3. Check connectivity:
   ```bash
   tailscale ping home-server
   ```

4. View logs:
   ```bash
   sudo journalctl -u tailscaled -f
   ```

### Slow Performance

1. Check if using relay:
   ```bash
   tailscale status | grep relay
   ```

2. Enable subnet routing for better performance
3. Check local internet speed
4. Reduce streaming quality in apps

### Can't access specific service

1. Verify service is running:
   ```bash
   sudo systemctl status <service>
   ```

2. Check firewall (shouldn't block Tailscale)
3. Test locally first: `curl http://localhost:PORT`
4. Check Tailscale ACLs

### Connection drops frequently

1. Check server's internet connection
2. Verify router isn't blocking VPN traffic
3. Check Tailscale logs for errors
4. Consider using Tailscale subnet routing

### SSH takes long time to connect

1. Disable DNS lookup in SSH:
   ```bash
   ssh -o GSSAPIAuthentication=no admin@home-server
   ```

2. Or add to `~/.ssh/config`:
   ```
   Host home-server
       HostName home-server
       User admin
       GSSAPIAuthentication no
   ```

## Additional Resources

- Tailscale Documentation: https://tailscale.com/kb/
- Tailscale GitHub: https://github.com/tailscale/tailscale
- WireGuard Documentation: https://www.wireguard.com/
- Plex Remote Access: https://support.plex.tv/articles/200289506-remote-access/
