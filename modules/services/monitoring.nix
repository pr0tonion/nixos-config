{ config, pkgs, lib, ... }:

{
  # Prometheus for metrics collection
  services.prometheus = {
    enable = true;
    port = 9090;

    # Exporters for system metrics
    exporters = {
      # Node exporter for system metrics
      node = {
        enable = true;
        port = 9100;
        enabledCollectors = [
          "systemd"
          "cpu"
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "stat"
        ];
      };

      # Smartctl exporter for disk health
      smartctl = {
        enable = true;
        port = 9633;
      };
    };

    # Scrape configurations
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
        scrape_interval = "15s";
      }
      {
        job_name = "smartctl";
        static_configs = [{
          targets = [ "localhost:9633" ];
        }];
        scrape_interval = "60s";
      }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:9090" ];
        }];
      }
    ];

    # Retention period
    retentionTime = "30d";
  };

  # Grafana for visualization
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0"; # Bind to all interfaces (LAN only)
      };
      analytics = {
        reporting_enabled = false;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{/etc/grafana/admin-password}"; # Set password in this file
      };
    };

    # Provision Prometheus as a data source
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }
      ];
      # Pre-configured dashboards
      dashboards.settings.providers = [
        {
          name = "default";
          options.path = "/var/lib/grafana/dashboards";
        }
      ];
    };
  };

  # Loki for log aggregation
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      auth_enabled = false;

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore.store = "inmemory";
            replication_factor = 1;
          };
        };
        chunk_idle_period = "5m";
        chunk_retain_period = "30s";
      };

      schema_config = {
        configs = [{
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };

      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/index";
          cache_location = "/var/lib/loki/cache";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };

      limits_config = {
        retention_period = "744h"; # 31 days
      };
    };
  };

  # Promtail for log shipping to Loki
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/var/lib/promtail/positions.yaml";
      };
      clients = [{
        url = "http://localhost:3100/loki/api/v1/push";
      }];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "home-server";
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }
        {
          job_name = "nginx";
          static_configs = [{
            targets = [ "localhost" ];
            labels = {
              job = "nginx";
              __path__ = "/var/log/nginx/*.log";
            };
          }];
        }
      ];
    };
  };

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [
    9090   # Prometheus
    3000   # Grafana
    3100   # Loki
    9100   # Node Exporter
    9633   # Smartctl Exporter
  ];

  # Create Grafana password file
  systemd.tmpfiles.rules = [
    "d /etc/grafana 0755 grafana grafana -"
    "f /etc/grafana/admin-password 0600 grafana grafana - admin" # Default password, change after setup!
  ];

  # Ensure monitoring user can access logs
  users.users.prometheus.extraGroups = [ "systemd-journal" ];
  users.users.promtail.extraGroups = [ "systemd-journal" ];

  # Resource limits
  systemd.services.prometheus.serviceConfig = {
    MemoryMax = "2G";
    CPUQuota = "200%";
  };

  systemd.services.grafana.serviceConfig = {
    MemoryMax = "1G";
  };

  systemd.services.loki.serviceConfig = {
    MemoryMax = "1G";
  };

  # NOTE: After setup:
  # 1. Access Grafana at: http://<server-ip>:3000
  # 2. Default credentials: admin/admin (change on first login)
  # 3. Prometheus will be auto-configured as a data source
  # 4. Import dashboards from grafana.com:
  #    - Node Exporter Full: Dashboard ID 1860
  #    - Prometheus Stats: Dashboard ID 2
  #    - Loki Logs: Dashboard ID 13639
  # 5. Access Prometheus directly at: http://<server-ip>:9090
}
