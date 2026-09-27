{ config, pkgs, lib, ... }: {
  home.activation.installPlaywrightBrowsers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if "$HOME/.npm-packages/bin/playwright" install chromium 2>&1; then
      echo "Playwright chromium browsers installed."
    else
      echo "Warning: Playwright chromium browsers could not be installed."
    fi
  '';
}
