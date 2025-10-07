# Deployment and Testing Guide

This guide explains how to test your configuration before deploying to your home server, and how to deploy updates.

## Testing on Your Main Machine

Before deploying to your home server, you can test the configuration on your main machine.

### Method 1: NixOS VM (If Running NixOS)

If your main machine runs NixOS:

```bash
# Build a VM from the configuration
nix build .#nixosConfigurations.home-server.config.system.build.vm

# Run the VM
./result/bin/run-home-server-vm
```

This creates a QEMU virtual machine with your configuration.

**Limitations:**
- Hardware-specific features won't work (GPU, actual network interfaces)
- Services will run but may need port adjustments to avoid conflicts

### Method 2: NixOS Container

Create a lightweight container for testing:

1. Create a container configuration in your main system's configuration:

```nix
# In your main system's configuration.nix
containers.home-server-test = {
  autoStart = false;
  config = { config, pkgs, ... }: {
    imports = [
      /path/to/nixos-config/modules/base.nix
      # Import other modules as needed
    ];

    # Minimal configuration for testing
    system.stateVersion = "24.05";
    networking.firewall.enable = true;
  };
};
```

2. Start the container:
```bash
sudo nixos-container start home-server-test
sudo nixos-container root-login home-server-test
```

**Limitations:**
- Limited hardware access
- Network isolation
- Suitable for testing services, not hardware features

### Method 3: Docker/Podman Testing

Test individual services using Docker:

```bash
# Example: Test Plex in Docker
docker run -d \
  --name plex-test \
  -p 32400:32400 \
  -v /path/to/media:/media \
  plexinc/pms-docker
```

**Limitations:**
- Only tests individual services
- Different from NixOS service configuration
- Useful for understanding service behavior

### Method 4: Syntax Checking Only

Check configuration syntax without building:

```bash
# Evaluate the configuration
nix eval .#nixosConfigurations.home-server.config.system.build.toplevel

# Check for syntax errors
nix flake check
```

This validates the configuration syntax but doesn't test actual functionality.

## Deploying to Home Server

### Method 1: SSH Deployment (Recommended)

Deploy from your main machine to the server:

```bash
# Using nixos-rebuild
nixos-rebuild switch --flake .#home-server \
  --target-host admin@home-server \
  --use-remote-sudo

# Or with Tailscale
nixos-rebuild switch --flake .#home-server \
  --target-host admin@100.x.x.x \
  --use-remote-sudo
```

This builds and deploys the configuration remotely.

### Method 2: Git Pull + Local Rebuild

On the home server:

```bash
# Pull latest changes
cd /etc/nixos-config
git pull

# Rebuild
sudo nixos-rebuild switch --flake .#home-server
```

This is simpler but requires direct access to the server.

### Method 3: Build Locally, Deploy Binary

From your main machine:

```bash
# Build the system configuration
nix build .#nixosConfigurations.home-server.config.system.build.toplevel

# Copy to server
nix copy --to ssh://admin@home-server ./result

# Activate on server
ssh admin@home-server "sudo $(readlink ./result)/bin/switch-to-configuration switch"
```

This is useful for slow server CPUs - build on faster machine, deploy to server.

## Rollback Strategies

### Automatic Rollback on Boot

NixOS keeps previous generations in the boot menu:

1. Reboot the server
2. In the boot menu, select a previous generation
3. The system will boot with the old configuration

### Manual Rollback

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or switch to a specific generation
sudo /nix/var/nix/profiles/system-42-link/bin/switch-to-configuration switch
```

### Testing Before Committing

Use `nixos-rebuild test` instead of `switch`:

```bash
# Test without adding to boot menu
sudo nixos-rebuild test --flake .#home-server

# If something breaks, just reboot to rollback
```

The configuration will be active until the next reboot, but won't be added to the boot menu.

## Continuous Deployment

### Automatic Updates from Git

Create a systemd timer for automatic updates:

Create `modules/auto-update.nix`:

```nix
{ config, pkgs, ... }:

{
  systemd.services.auto-update = {
    description = "Auto update NixOS configuration from git";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      cd /etc/nixos-config
      ${pkgs.git}/bin/git pull
      ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake .#home-server
    '';
  };

  systemd.timers.auto-update = {
    description = "Auto update timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
```

**Warning**: This can break your system if you push broken configs. Use with caution.

### Manual Deployment Workflow

1. Make changes on your main machine
2. Commit to git
3. Test locally if possible
4. Push to repository
5. SSH to server and pull changes
6. Run `sudo nixos-rebuild switch`
7. Test services
8. Rollback if needed

## Backup Strategy

### Configuration Backup

Your configuration is in Git - that's your backup!

Additional backup locations:
```bash
# Backup to remote git repository
git remote add backup git@github.com:yourusername/nixos-config-backup.git
git push backup main

# Or backup to another location
tar czf nixos-config-backup-$(date +%Y%m%d).tar.gz /etc/nixos-config
scp nixos-config-backup-*.tar.gz user@backup-server:/backups/
```

### Data Backup

For media and service data:

```bash
# Using rsync
rsync -avz --delete /srv/media/ backup-server:/backup/media/

# Using Borg Backup (recommended)
nix-shell -p borgbackup
borg init --encryption=repokey /path/to/backup/repo
borg create /path/to/backup/repo::backup-$(date +%Y%m%d) /srv/media
```

### Service Data Backup

Important service data locations:
- `/var/lib/plex` - Plex database and metadata
- `/var/lib/sonarr` - Sonarr database
- `/var/lib/radarr` - Radarr database
- `/var/lib/prowlarr` - Prowlarr settings
- `/var/lib/transmission` - Torrent state
- `/var/lib/grafana` - Grafana dashboards and settings

Backup script example:

```bash
#!/usr/bin/env bash
BACKUP_DIR=/backup/services-$(date +%Y%m%d)
mkdir -p $BACKUP_DIR

# Stop services
systemctl stop plex sonarr radarr transmission

# Backup
cp -r /var/lib/plex $BACKUP_DIR/
cp -r /var/lib/sonarr $BACKUP_DIR/
cp -r /var/lib/radarr $BACKUP_DIR/
cp -r /var/lib/transmission $BACKUP_DIR/

# Start services
systemctl start plex sonarr radarr transmission

# Compress
tar czf $BACKUP_DIR.tar.gz $BACKUP_DIR
rm -rf $BACKUP_DIR
```

## Monitoring Deployments

### Deployment Logs

```bash
# View recent changes
journalctl -u nixos-rebuild -n 50

# Monitor in real-time
journalctl -fu nixos-rebuild
```

### Service Health After Deployment

Create a health check script:

```bash
#!/usr/bin/env bash
# health-check.sh

services=(
  "plex"
  "sonarr"
  "radarr"
  "prowlarr"
  "transmission"
  "grafana"
  "prometheus"
  "homepage-dashboard"
  "tailscaled"
)

echo "Checking service health..."
for service in "${services[@]}"; do
  if systemctl is-active --quiet "$service"; then
    echo "✓ $service is running"
  else
    echo "✗ $service is NOT running"
  fi
done
```

Run after deployment:
```bash
./health-check.sh
```

### Automated Health Checks

Add to `modules/monitoring/health-check.nix`:

```nix
{ config, pkgs, ... }:

{
  systemd.services.health-check = {
    description = "Health check all services";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/scripts/health-check.sh";
    };
  };

  systemd.timers.health-check = {
    description = "Run health check every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
    };
  };
}
```

## Reinstall/Redeploy with Minimal Effort

### Complete Reinstall

1. Boot from NixOS USB
2. Partition disks
3. Mount filesystems
4. Clone this repository
5. Run installation:
   ```bash
   nixos-install --flake /mnt/etc/nixos-config#home-server
   ```
6. Reboot
7. Restore service data from backups

### Restore Service Data

```bash
# Stop services
sudo systemctl stop plex sonarr radarr transmission

# Restore from backup
sudo tar xzf services-backup.tar.gz -C /var/lib/

# Fix permissions
sudo chown -R plex:plex /var/lib/plex
sudo chown -R media:media /var/lib/sonarr /var/lib/radarr

# Start services
sudo systemctl start plex sonarr radarr transmission
```

## Migration to New Hardware

1. **Backup everything** (config + data)

2. **Update hardware-configuration.nix**:
   - Install NixOS on new hardware
   - Generate new hardware config
   - Replace `hosts/home-server/hardware-configuration.nix`

3. **Deploy configuration**:
   ```bash
   sudo nixos-rebuild switch --flake .#home-server
   ```

4. **Restore data**:
   - Copy media files to `/srv/media`
   - Restore service databases
   - Restart services

5. **Verify**:
   - Check all services are running
   - Test media playback
   - Test remote access

## Performance Testing

### Before Deployment

Test build time:
```bash
time nix build .#nixosConfigurations.home-server.config.system.build.toplevel
```

### After Deployment

Monitor system resources:
```bash
# CPU usage
htop

# Memory usage
free -h

# Disk usage
df -h

# Service resource usage
systemctl status plex
```

Use Grafana dashboards for detailed metrics.

## Common Issues and Solutions

### Service fails to start after update

1. Check logs:
   ```bash
   sudo journalctl -u <service> -n 50
   ```

2. Try restarting:
   ```bash
   sudo systemctl restart <service>
   ```

3. Rollback if needed:
   ```bash
   sudo nixos-rebuild switch --rollback
   ```

### Out of disk space during build

```bash
# Clean up old generations
sudo nix-collect-garbage --delete-older-than 30d

# Optimize nix store
sudo nix-store --optimize
```

### Network issues after deployment

1. Check network configuration:
   ```bash
   ip addr
   ip route
   ```

2. Restart networking:
   ```bash
   sudo systemctl restart systemd-networkd
   ```

3. Check firewall:
   ```bash
   sudo iptables -L
   ```

### Database corruption

Always backup before major updates:
```bash
# Plex
sudo sqlite3 /var/lib/plex/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db .dump > plex_backup.sql

# Sonarr/Radarr
cp /var/lib/sonarr/sonarr.db /backup/sonarr.db.backup
```

## Best Practices

1. **Test on non-production first** if possible
2. **Always commit to git before deploying**
3. **Backup service data before major updates**
4. **Use `nixos-rebuild test` for risky changes**
5. **Keep at least 3 generations** in case of issues
6. **Monitor logs after deployment**
7. **Document custom changes** in commit messages
8. **Schedule updates during low-usage periods**
9. **Have a rollback plan**
10. **Test restore procedures regularly**

## Automation Tools

### NixOps (Advanced)

For managing multiple NixOS machines:

```bash
# Install NixOps
nix-shell -p nixops

# Create deployment
nixops create -d home-network ./network.nix

# Deploy
nixops deploy -d home-network
```

### Colmena (Alternative)

```bash
# Install Colmena
nix-shell -p colmena

# Deploy
colmena apply
```

Both tools provide more sophisticated deployment capabilities for complex setups.

## Summary

- **Test**: Use VMs or containers when possible
- **Deploy**: SSH deployment or local rebuild
- **Rollback**: Always available via boot menu or `--rollback`
- **Backup**: Configuration in git + periodic data backups
- **Monitor**: Check logs and service health after deployment
- **Automate**: Create scripts for repetitive tasks

With NixOS, deployment and rollback are safe and reproducible. Your entire system configuration is in version control, making it easy to redeploy or migrate to new hardware.
