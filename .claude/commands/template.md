# create_nixos_server - What you want built

<!-- Brief description of what this command does -->

This command builds a full nixos config with several types of hosts, libraries.

## Context
- **Project type**: Server and home computer configuation
- **Tech stack**: nixos
- **Relevant directories**:
  - I want you to find the best way to structure my nixos config
  - The directory structure should allow for easily adding and removing nixos packages like plex, neovim etc.
- **Key conventions**: make sure to create relevant comments and naming to that it is easy for me to edit it later. You should always find the recommended way of performing a task.
- **Computer spec**: Intel i7-10700 2.90Ghz processor, Integrated graphics, 16GB DDR4 Ram
- **Purpose**: I want to use this nixos config on my home server I have built. I want to use torrent with private torrent tracker website, plex to stream downloaded movies, manage modules/applications like home assistant etc.
## Features

1. A nixos configuration which allows for multiple types of hosts such as home-server, home-computer(This will not be used as of now, but later. so create a skeleton).
2. Have a plex service which provides streaming services over home network.
3. Have media automation through Sonarr(TV) and Radarr(Movies)
4. Have a index manager with Prowlarr
5. Media content requests with overseerr
6. Media should be stored in /srv/media unless a better option is present
7. Perform automatic cleanups of media files if older than 6months and have not been watched. Also cleanup of temporary files
8. Add a VPN Server like Wireguard or Tailscale to access server remotely
9. Add system monitoring with Prometheus. Also include things like Disk health, log management.
10. For user management, create a admin user, a service user(dedicated users for plex, torrent downloader etc)
11. add git
12. For power management, use wake-on-LAN
13. Add GPU Passthrough to allow for Plex hardware transcoding
14. Add homepage-dashboard as a dashboard for the server.
15. Install Neovim on my server, then add the config from my github. https://github.com/pr0tonion/My-Config/tree/main/nvim

## Constraints
- Always use a modern approach
- Do not open up IP to the internet, but make it available on my home network, except to allow for VPN server access.
- Use the most up to date services for the best experience. By up to date i mean the generally best service packages/most popular
- Use nixos flakes whenever possible
- Use nixos modules
- Use default linux directory configurations when possible
- Use the newest available information
- If something does not work or you have issues
## Testing & Validation
- Show me how to test and validate build
- When building, perform tests and try to fix them.
## Generating ios
- Generate an iso i can put on a usb stick and install on my server
## Documentation to create after finishing all tasks.
- Create a concise document .txt document in a /documentation directory on how to do the following:
1. Add a new user
2. How to add a private tracker to the current torrent client
3. How to manage IP's. By this i mean how to set port numbers for services.
4. How to connect to server from outside
5. How to reinstall/redeploy with minimal effort
6. How to test on my main machine before deploying to home server.
7. A document on what to do next, what potential things i need to fix, what might be missing.
