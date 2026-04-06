# Hyprland configuration for home-manager
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./wayland-common.nix
  ];

  services.kanshi.systemdTarget = "hyprland-session.target";

  home.pointerCursor = {
    name = "Bibata Modern";
    package = pkgs.bibata-cursors;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    systemd = {
      enable = true;
      variables = ["--all"];
    };

    settings = {
      "$mod" = "SUPER";

      bind =
        [
          # Apps
          "$mod, Return, exec, kitty"
          "$mod, E, exec, thunar"
          "$mod, D, exec, noctalia-shell ipc call launcher toggle"
          "$mod, B, exec, zen"

          # Window actions
          "$mod, Q, killactive"
          "$mod, F, fullscreen"
          "$mod, V, togglefloating"
          "$mod, P, pseudo"
          "$mod, T, togglesplit"
          "$mod, W, fullscreen, 1"

          # Move focus
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          "$mod SHIFT, H, movewindow, l"
          "$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"

          # Screenshot
          ",Print, exec, noctalia-shell ipc call plugin:screen-toolkit annotate"
          "SHIFT,Print, exec, noctalia-shell ipc call plugin:screen-toolkit record"

          # Special workspace
          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"

          # Window cycling
          "$mod, Tab, cyclenext"
          "$mod, Tab, bringactivetotop"
          "$mod SHIFT, Tab, cyclenext, prev"
          "$mod SHIFT, Tab, bringactivetotop"

          # App launcher
          "$mod, space, exec, noctalia-shell ipc call launcher toggle"

          # Volume
          ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

          # Resize
          "$mod CTRL, H, resizeactive, -40 0"
          "$mod CTRL, J, resizeactive, 0 40"
          "$mod CTRL, K, resizeactive, 0 -40"
          "$mod CTRL, L, resizeactive, 40 0"
        ]
        ++ (builtins.concatLists (
          lib.lists.imap1 (ws: code: [
            "$mod, ${code}, workspace, ${toString ws}"
            "$mod SHIFT, ${code}, movetoworkspace, ${toString ws}"
          ]) (lib.strings.stringToCharacters "123456789")
        ));

      binde = [
        ",XF86MonBrightnessUp, exec, brightnessctl set 10%+"
        ",XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        vfr = true;
        vrr = 1;
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
        "col.active_border" = "rgb(bb3344) rgb(33bb44) 45deg";
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
        pseudotile = "yes";
        preserve_split = "yes";
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
        repeat_delay = 200;
        repeat_rate = 60;
        follow_mouse = 1;
        mouse_refocus = false;
        accel_profile = "flat";
        sensitivity = 0.4;

        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          disable_while_typing = true;
          clickfinger_behavior = true;
          middle_button_emulation = true;
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

      windowrule = [
        "match:class ^(kitty)$, opacity 0.96 override"
      ];

      exec-once = [
        "hypridle"
      ];

      env = lib.attrsets.mapAttrsToList (name: val: "${name},${toString val}") {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };
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
