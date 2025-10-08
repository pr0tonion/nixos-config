{ config, pkgs, lib, ... }:

{
  # Homepage Dashboard for service overview
  services.homepage-dashboard = {
    enable = true;

    # Listen on all interfaces (LAN only due to firewall)
    listenPort = 3001;

    # Service definitions
    services = [
      {
        "Media" = [
          {
            "Plex" = {
              description = "Media Server";
              href = "http://localhost:32400/web";
              icon = "plex.png";
              widget = {
                type = "plex";
                url = "http://localhost:32400";
                key = "{{HOMEPAGE_VAR_PLEX_TOKEN}}"; # Set via environment
              };
            };
          }
          {
            "Overseerr" = {
              description = "Media Requests";
              href = "http://localhost:5055";
              icon = "overseerr.png";
              widget = {
                type = "overseerr";
                url = "http://localhost:5055";
                key = "{{HOMEPAGE_VAR_OVERSEERR_TOKEN}}";
              };
            };
          }
        ];
      }
      {
        "Media Management" = [
          {
            "Sonarr" = {
              description = "TV Shows";
              href = "http://localhost:8989";
              icon = "sonarr.png";
              widget = {
                type = "sonarr";
                url = "http://localhost:8989";
                key = "{{HOMEPAGE_VAR_SONARR_TOKEN}}";
              };
            };
          }
          {
            "Radarr" = {
              description = "Movies";
              href = "http://localhost:7878";
              icon = "radarr.png";
              widget = {
                type = "radarr";
                url = "http://localhost:7878";
                key = "{{HOMEPAGE_VAR_RADARR_TOKEN}}";
              };
            };
          }
          {
            "Prowlarr" = {
              description = "Indexer Manager";
              href = "http://localhost:9696";
              icon = "prowlarr.png";
              widget = {
                type = "prowlarr";
                url = "http://localhost:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_TOKEN}}";
              };
            };
          }
        ];
      }
      {
        "Download" = [
          {
            "Transmission" = {
              description = "BitTorrent Client";
              href = "http://localhost:9091";
              icon = "transmission.png";
              widget = {
                type = "transmission";
                url = "http://localhost:9091";
                username = "admin";
                password = "{{HOMEPAGE_VAR_TRANSMISSION_PASSWORD}}";
              };
            };
          }
        ];
      }
      {
        "Monitoring" = [
          {
            "Grafana" = {
              description = "Metrics Dashboard";
              href = "http://localhost:3000";
              icon = "grafana.png";
            };
          }
          {
            "Prometheus" = {
              description = "Metrics Collection";
              href = "http://localhost:9090";
              icon = "prometheus.png";
            };
          }
        ];
      }
    ];

    # Widgets
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        search = {
          provider = "google";
          target = "_blank";
        };
      }
    ];

    # Bookmarks
    bookmarks = [
      {
        "Documentation" = [
          {
            "NixOS Manual" = [
              {
                href = "https://nixos.org/manual/nixos/stable/";
              }
            ];
          }
          {
            "Tailscale Admin" = [
              {
                href = "https://login.tailscale.com/admin";
              }
            ];
          }
        ];
      }
    ];

    # Settings
    settings = {
      title = "Home Server";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      layout = {
        "Media" = {
          style = "row";
          columns = 3;
        };
        "Media Management" = {
          style = "row";
          columns = 3;
        };
      };
    };
  };

  # Open firewall for homepage
  networking.firewall.allowedTCPPorts = [ 3001 ];

  # Environment file for API tokens
  # Create this file manually with your API tokens
  systemd.services.homepage-dashboard.serviceConfig = {
    EnvironmentFile = lib.mkDefault "/etc/homepage/env";
  };

  # Allow insecure hosts for local services
  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOW_INSECURE_HOSTS = "true";
    HOMEPAGE_ALLOWED_HOSTS = "192.168.1.145";
  };

  # Create environment file directory
  systemd.tmpfiles.rules = [
    "d /etc/homepage 0755 root root -"
    "f /etc/homepage/env 0600 homepage homepage -"
  ];

  # NOTE: After setup:
  # 1. Access Homepage at: http://<server-ip>:3001
  # 2. Create /etc/homepage/env with the following format:
  #    HOMEPAGE_VAR_PLEX_TOKEN=your-plex-token
  #    HOMEPAGE_VAR_OVERSEERR_TOKEN=your-overseerr-token
  #    HOMEPAGE_VAR_SONARR_TOKEN=your-sonarr-api-key
  #    HOMEPAGE_VAR_RADARR_TOKEN=your-radarr-api-key
  #    HOMEPAGE_VAR_PROWLARR_TOKEN=your-prowlarr-api-key
  #    HOMEPAGE_VAR_TRANSMISSION_PASSWORD=your-transmission-password
  # 3. Restart homepage service: sudo systemctl restart homepage-dashboard
}
