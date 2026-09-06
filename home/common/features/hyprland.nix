# Hyprland configuration for home-manager
{
  pkgs,
  lib,
  ...
}:
let
  mklua = lib.generators.mkLuaInline;
  luaf = body: lib.generators.mkLuaInline ("function() " + body + " end");

  # Shorthand helper functions for Lua bindings
  exec = cmd: mklua "hl.dsp.exec_cmd('${cmd}')";

  focus = dir: mklua "hl.dsp.focus({ direction = '${dir}' })";
  move = dir: mklua "hl.dsp.window.move({ direction = '${dir}' })";
  close = mklua "hl.dsp.window.close()";
  kill = mklua "hl.dsp.window.kill()";
  exit = mklua "hl.dsp.exit()";
  fullscreen = mklua "hl.dsp.window.fullscreen()";
  toggle_floating = mklua "hl.dsp.window.float({ action = 'toggle' })";
  toggle_pseudo = mklua "hl.dsp.window.pseudo()";
  cyclenext = mklua "hl.dsp.window.cycle_next()";

  workspace_switch = ws: mklua "hl.dsp.focus({ workspace = ${toString ws} })";
  workspace_move = ws: mklua "hl.dsp.window.move({ workspace = ${toString ws} })";

  # Convert bind list to proper Lua table format
  mkBinds = bindList: map (
    item:
    let
      len = builtins.length item;
    in
    if len == 2 then {
      _args = [ (builtins.elemAt item 0) (builtins.elemAt item 1) ];
    } else if len == 3 then {
      _args = [
        (builtins.elemAt item 0)
        (builtins.elemAt item 1)
        (builtins.elemAt item 2)
      ];
    } else
      throw "Invalid bind format: expected 2 or 3 elements"
  ) bindList;

  # Generate workspace bindings
  workspaceBindings = builtins.concatLists (
    lib.lists.imap1 (ws: code: [
      [ "SUPER+${toString ws}" (workspace_switch ws) ]
      [ "SUPER+SHIFT+${toString ws}" (workspace_move ws) ]
    ]) (lib.strings.stringToCharacters "123456789")
  );
in
{
  imports = [
    ./wayland-common.nix
  ];

  services.kanshi.systemdTarget = "hyprland-session.target";

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 16;
    gtk.enable = true;
    x11.enable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    systemd = {
      enable = true;
      variables = [ "--all" ];
    };

    plugins = [ ];

    settings = {
      config = {
        render = {
          direct_scanout = 2; # Enable in games
          cm_sdr_eotf = "srgb";
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
        };

        general = {
          gaps_in = 4;
          gaps_out = 3;
          border_size = 2;
          layout = "dwindle";
          resize_on_border = true;
          allow_tearing = false;
          "col.active_border" = {
            colors = [ "rgb(bb3344)" "rgb(33bb44)" ];
            angle = 45;
          };
        };

        decoration = {
          rounding = 4;
          active_opacity = 1.0;
          inactive_opacity = 0.95;
          shadow.enabled = true;
          shadow.range = 60;
          shadow.render_power = 3;
          shadow.color = "rgba(00000066)";
          shadow.color_inactive = "rgba(00000033)";
          shadow.offset = "0 15";
          blur.enabled = true;
          blur.size = 12;
          blur.passes = 3;
          blur.new_optimizations = true;
          blur.xray = false;
          blur.ignore_opacity = false;
          blur.noise = 0.0117;
          blur.contrast = 1.0;
          blur.brightness = 1.0;
          blur.vibrancy = 0.1696;
          blur.vibrancy_darkness = 0.0;
          blur.popups = true;
          blur.popups_ignorealpha = 0.6;
          dim_inactive = true;
          dim_strength = 0.05;
        };

        animations = {
          enabled = true;
          bezier = [
            "spring, 0.175, 0.885, 0.32, 1.275"
            "whip, 0.05, 0.9, 0.1, 1.1"
            "blackHole, 0.55, 0.085, 0.68, 0.53"
            "linear, 0.0, 0.0, 1.0, 1.0"
          ];
          animation = [
            "windowsIn, 1, 5, spring, popin 50%"
            "windowsOut, 1, 2.5, blackHole, popin 80%"
            "windowsMove, 1, 4, whip, slide"
            "border, 1, 3, whip"
            "borderangle, 1, 30, linear, loop"
            "fadeShadow, 1, 3, blackHole"
            "fade, 1, 3, whip"
            "fadeIn, 1, 3, whip"
            "fadeOut, 1, 3, blackHole"
            "workspaces, 1, 6, whip, slidefade 50%"
            "specialWorkspace, 1, 5, whip, slidevert"
            "layersIn, 1, 4, spring, fade"
            "layersOut, 1, 2.5, blackHole, fade"
          ];
        };

        dwindle = {
          preserve_split = true;
          smart_split = false;
          smart_resizing = true;
          force_split = 2;
        };

        master = {
          new_status = "master";
          new_on_top = false;
        };

        input = {
          kb_layout = "us";
          kb_variant = "altgr-intl";
          repeat_delay = 200;
          repeat_rate = 60;
          follow_mouse = 1;
          mouse_refocus = false;
          accel_profile = "flat";
          sensitivity = 0.4;
          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
          };
        };

        cursor = {
          hide_on_key_press = true;
        };

        gestures = {
          gesture = [
            "3, horizontal, scale: 1.4, workspace"
            "3, down, mod: ALT, close"
            "3, up, mod: SUPER, fullscreen"
            "3, left, mod: SUPER, float"
            "4, swipe, move"
            "4, pinch, resize"
            "3, pinchin, special, scratch"
            "3, pinchout, special, scratch"
          ];
        };

        binds = {
          workspace_back_and_forth = true;
        };

        workspace = [
          "1, default:true"
          "special:magic"
          "special:scratch"
        ];

        xwayland = {
          force_zero_scaling = true;
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
      };

      on = {
        _args = [ "hyprland.start" (luaf "hl.exec_cmd('hypridle')") ];
      };

      window_rule = [
        {
          match.class = "kitty";
          opacity = "0.96 override";
        }
      ];

      env = lib.attrsets.mapAttrsToList (name: val: {
        _args = [ name val ];
      }) {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };

      bind = mkBinds (
        [
          # Apps
          [ "SUPER+Return" (exec "kitty") ]
          [ "SUPER+E" (exec "thunar") ]
          [ "SUPER+D" (exec "noctalia-shell ipc call launcher toggle") ]
          [ "SUPER+B" (exec "zen") ]

          # Window actions
          [ "SUPER+Q" kill ]
          [ "SUPER+F" fullscreen ]
          [ "SUPER+V" toggle_floating ]
          [ "SUPER+P" toggle_pseudo ]
          [ "SUPER+SHIFT+E" exit ]

          # Move focus
          [ "SUPER+H" (focus "l") ]
          [ "SUPER+L" (focus "r") ]
          [ "SUPER+K" (focus "u") ]
          [ "SUPER+J" (focus "d") ]

          # Move window
          [ "SUPER+SHIFT+H" (move "l") ]
          [ "SUPER+SHIFT+L" (move "r") ]
          [ "SUPER+SHIFT+K" (move "u") ]
          [ "SUPER+SHIFT+J" (move "d") ]

          # Screenshot
          [ "Print" (exec "noctalia-shell ipc call plugin:screen-toolkit annotate") { locked = true; } ]
          [ "SHIFT+Print" (exec "noctalia-shell ipc call plugin:screen-toolkit record") { locked = true; } ]

          # Special workspace
          [ "SUPER+S" (exec "hyprctl togglespecialworkspace magic") { locked = true; } ]
          [ "SUPER+SHIFT+S" (exec "hyprctl movetoworkspace special:magic") { locked = true; } ]

          # Window cycling
          [ "SUPER+Tab" (cyclenext) ]
          [ "SUPER+Tab" (mklua "hl.dsp.window.bring_to_top()") ]
          [ "SUPER+SHIFT+Tab" (mklua "hl.dsp.window.cycle_next({ prev = true })") ]
          [ "SUPER+SHIFT+Tab" (mklua "hl.dsp.window.bring_to_top()") ]

          # App launcher
          [ "SUPER+space" (exec "noctalia-shell ipc call launcher toggle") ]

          # Volume
          [ "XF86AudioRaiseVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") { repeating = true; locked = true; } ]
          [ "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") { repeating = true; locked = true; } ]
          [ "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") { locked = true; } ]
          [ "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") { locked = true; } ]

          # Resize
          [ "SUPER+CTRL+H" (mklua "hl.dsp.window.resize({ x = -40, y = 0, relative = true })") ]
          [ "SUPER+CTRL+J" (mklua "hl.dsp.window.resize({ x = 0, y = 40, relative = true })") ]
          [ "SUPER+CTRL+K" (mklua "hl.dsp.window.resize({ x = 0, y = -40, relative = true })") ]
          [ "SUPER+CTRL+L" (mklua "hl.dsp.window.resize({ x = 40, y = 0, relative = true })") ]

          # Brightness
          [ "XF86MonBrightnessUp" (exec "brightnessctl set 10%+") { repeating = true; } ]
          [ "XF86MonBrightnessDown" (exec "brightnessctl set 10%-") { repeating = true; } ]

          # Mouse binds
          [ "SUPER+mouse:272" (mklua "hl.dsp.window.drag()") { mouse = true; } ]
          [ "SUPER+mouse:273" (mklua "hl.dsp.window.resize()") { mouse = true; } ]
        ]
        ++ workspaceBindings
      );
    };
  };

  home.packages = with pkgs; [
    # Screenshot tools
    wl-clipboard
    brightnessctl

    # Wallpaper
    swaybg
  ];

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        grace = 5;
        hide_cursor = true;
        fail_attempts = 3;
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 5;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "250, 50";
          outline_thickness = 2;
          fade_on_empty = false;
          placeholder_text = "Password...";
        }
      ];

      label = [
        {
          text = "Hyprland";
          size = 30;
          color = "rgba(255, 255, 255, 0.8)";
          vertical_align = 0.5;
          horizontal_align = 0.5;
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "brightnessctl -s set 10%";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
        }
      ];
    };
  };

  services.hyprpolkitagent.enable = true;
}
