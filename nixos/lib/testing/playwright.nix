{ config, hostPkgs, lib, ... }:
let
  cfg = config.playwright;
  inherit (lib) mkOption mkEnableOption mkIf types mkForce mkAfter;
in
{
  options = {
    playwright = {
      enable = mkEnableOption "Playwright support";
      proxy = {
        node = mkOption {
          type = types.str;
        };
        port = mkOption {
          default = 3128;
          type = types.int;
        };
      };

    };
  };
  config = mkIf cfg.enable {
    extraDriverEnv = {
      PLAYWRIGHT_BROWSERS_PATH = hostPkgs.playwright-driver.browsers;
    };
    extraPythonPackages = p: [
      p.playwright
    ];
    testscriptPreamble = ''
      from playwright.sync_api import sync_playwright

      ${cfg.proxy.node}.start()
      ${cfg.proxy.node}.wait_for_unit(\"3proxy\")
      ${cfg.proxy.node}.forward_port(${toString cfg.proxy.port}, ${toString cfg.proxy.port})
      browser = sync_playwright().start().firefox.launch(proxy={\"server\":\"http://localhost:${toString cfg.proxy.port}\"})
    '';
    defaults = ({ config, ... }: {
      networking.firewall.allowedTCPPorts = [ 3128 ];
      services._3proxy = mkIf (config.networking.hostName == cfg.proxy.node) {
        enable = true;
        services = [{
          type = "proxy";
          bindAddress = "0.0.0.0";
          bindPort = cfg.proxy.port;
          auth = [ "none" ];
        }];
      };
    });
  };
}
