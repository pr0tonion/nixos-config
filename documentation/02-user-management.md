# User Management Guide

## Current User Structure

The system is configured with the following users:

- **admin**: Primary administrator with sudo access
- **media**: System user for Plex, Sonarr, Radarr, Jellyseerr
- **transmission**: System user for Transmission torrent client
- **vpn**: System user for VPN services
- **monitoring**: System user for Prometheus, Grafana, Loki

## Adding a New Administrator User

### Method 1: Declarative (Recommended)

Edit `modules/users.nix`:

```nix
# Add this to the file
users.users.newadmin = {
  isNormalUser = true;
  description = "New Administrator";
  extraGroups = [ "wheel" "networkmanager" "video" ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3... newadmin@example.com"
  ];
  hashedPassword = null; # Set via passwd command after rebuild
  shell = pkgs.bash;
};
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake /etc/nixos-config#home-server
sudo passwd newadmin
```

### Method 2: Imperative (Temporary)

```bash
# Create user
sudo useradd -m -G wheel -s /bin/bash newadmin

# Set password
sudo passwd newadmin

# Add SSH key
sudo mkdir -p /home/newadmin/.ssh
sudo nano /home/newadmin/.ssh/authorized_keys
# Paste SSH public key
sudo chown -R newadmin:users /home/newadmin/.ssh
sudo chmod 700 /home/newadmin/.ssh
sudo chmod 600 /home/newadmin/.ssh/authorized_keys
```

**Note**: Users created imperatively will be removed on next rebuild unless added to the configuration.

## Adding a Regular User (No Admin Access)

Edit `modules/users.nix`:

```nix
users.users.username = {
  isNormalUser = true;
  description = "Regular User";
  extraGroups = [ ];  # No special groups
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3... user@example.com"
  ];
  shell = pkgs.bash;
};
```

## Removing a User

### Declarative Method:

1. Remove or comment out the user definition in `modules/users.nix`
2. Rebuild the system:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos-config#home-server
   ```

### Imperative Method (Temporary):

```bash
# Remove user and home directory
sudo userdel -r username
```

## Adding Home Manager Configuration for a User

Create a new file `home/username.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  home.username = "username";
  home.homeDirectory = "/home/username";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # User-specific configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -alh";
    };
  };

  home.packages = with pkgs; [
    htop
    vim
  ];
}
```

Then add to `flake.nix`:

```nix
# In the home-server configuration module list:
home-manager.users.username = import ./home/username.nix;
```

## Managing Service Users

Service users (media, transmission, etc.) are system accounts and should not be logged into directly. They are managed in `modules/users.nix`.

### Changing Service User Permissions

If a service user needs access to additional resources:

```nix
# In modules/users.nix
users.users.media.extraGroups = [ "video" "render" "newgroup" ];
```

## User Groups and Permissions

### Important Groups:

- **wheel**: Sudo access (administrators)
- **media**: Access to media files
- **video**: GPU/video device access (for Plex transcoding)
- **transmission**: Torrent download management
- **networkmanager**: Network configuration
- **docker**: Docker access (if Docker is enabled)

### Adding a User to a Group:

```bash
# Temporary (until next rebuild):
sudo usermod -aG groupname username

# Permanent (in modules/users.nix):
users.users.username.extraGroups = [ "groupname" ];
# Then rebuild
```

## SSH Key Management

### Generate SSH Key Pair:

On your local machine:

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

### Add Public Key to Server:

Add the public key content to `modules/users.nix`:

```nix
openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGx... your-email@example.com"
];
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake /etc/nixos-config#home-server
```

## Password Management

### Set User Password:

```bash
sudo passwd username
```

### Using Hashed Passwords in Configuration:

Generate a hashed password:

```bash
mkpasswd -m sha-512
# Enter password when prompted
# Copy the output hash
```

Add to `modules/users.nix`:

```nix
users.users.username = {
  # ... other config ...
  hashedPassword = "$6$rounds=656000$..."; # Paste the hash here
};
```

## Sudo Configuration

### Grant Passwordless Sudo (Not Recommended):

Edit `modules/users.nix`:

```nix
security.sudo.extraRules = [
  {
    users = [ "username" ];
    commands = [
      {
        command = "ALL";
        options = [ "NOPASSWD" ];
      }
    ];
  }
];
```

### Grant Specific Commands Without Password:

```nix
security.sudo.extraRules = [
  {
    users = [ "username" ];
    commands = [
      {
        command = "/run/current-system/sw/bin/systemctl restart plex";
        options = [ "NOPASSWD" ];
      }
    ];
  }
];
```

## Viewing Current Users

```bash
# List all users
cat /etc/passwd

# List users with home directories
ls -la /home

# Show user groups
groups username

# Show all groups
cat /etc/group
```

## Best Practices

1. **Always use SSH keys** for authentication, disable password auth
2. **Use declarative configuration** in `modules/users.nix` for permanence
3. **Minimize sudo access** - only give to trusted administrators
4. **Use service users** for running services, never log in as them
5. **Regular audits** - periodically review user access and permissions
6. **Document users** - add comments in `users.nix` explaining each user's purpose

## Security Notes

- Root login via SSH is disabled by default
- Password authentication via SSH is disabled (keys only)
- New users won't have passwords set unless explicitly configured
- Service users cannot be logged into directly
- All sudo actions require password by default

## Troubleshooting

### Can't SSH as new user

- Check SSH key is correctly added in `modules/users.nix`
- Verify the user was created: `id username`
- Check SSH logs: `sudo journalctl -u sshd -f`
- Test SSH key: `ssh -i ~/.ssh/id_ed25519 username@server`

### User has no home directory

- Ensure `isNormalUser = true` is set
- Rebuild and check: `ls -la /home`

### Sudo not working

- Verify user is in wheel group: `groups username`
- Check sudo configuration: `sudo -l -U username`
- Ensure wheel group has sudo access in `modules/users.nix`
