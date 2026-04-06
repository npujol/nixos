# Hyprland configuration for home-manager
{
  pkgs,
  lib,
  inputs,
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
          "$mod, D, exec, wofi --show drun"
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
          ",Print, exec, ${lib.getExe pkgs.grimblast} save output - | ${lib.getExe pkgs.swappy} -f -"
          "SHIFT,Print, exec, ${lib.getExe pkgs.grimblast} save area - | ${lib.getExe pkgs.swappy} -f -"

          # Special workspace
          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"

          # Window cycling
          "$mod, Tab, cyclenext"
          "$mod, Tab, bringactivetotop"
          "$mod SHIFT, Tab, cyclenext, prev"
          "$mod SHIFT, Tab, bringactivetotop"

          # App launcher
          "$mod, space, exec, wofi --show drun"

          # Volume
          ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

          # Move to workspace
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"

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
          ]) (lib.strings.stringToCharacters "QWERTYUIO")
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
        gaps_in = 5;
        gaps_out = 10;
        border_size = 0;
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = false;
        "col.active_border" = "rgb(bb3344) rgb(33bb44) 45deg";
      };

      decoration = {
        rounding = 16;
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
        "match:class ^(firefox)$, opacity 1.0 override"
        "match:class ^(google-chrome)$, opacity 1.0 override"
        "match:class ^(chromium)$, opacity 1.0 override"
        "match:class ^(brave)$, opacity 1.0 override"
        "match:class ^(zen-browser)$, opacity 1.0 override"
        "match:class ^(neovide)$, opacity 0.95 override"
        "match:class ^(kitty)$, opacity 0.96 override"
        "match:class ^(Alacritty)$, opacity 0.96 override"
      ];

      exec-once = [
        "waybar"
        "hypridle"
        "hyprctl setcursor macOS-White 24"
      ];

      env = lib.attrsets.mapAttrsToList (name: val: "${name},${toString val}") {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        XDG_SESSION_DESKTOP = "Hyprland";
        XCURSOR_THEME = "macOS-White";
        XCURSOR_SIZE = "24";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };
    };
  };

  home.packages = with pkgs; [
    grim
    slurp
    swappy
    # hyprland
    # hypridle
    # hyprlock

    # Screenshot tools
    # grim
    # slurp
    wl-clipboard
    brightnessctl

    # App launcher
    wofi

    # Status bar
    waybar

    # System tray
    libappindicator-gtk3

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

  # Wofi config
  programs.wofi = {
    enable = true;
    settings = {
      show = "drun";
      prompt = "Search...";
      allow_images = true;
      image_size = "32px";
      width = 600;
      height = 400;
    };
  };

  # Waybar config
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainbar = {
        margin-left = 2;
        margin-right = 2;
        layer = "top";
        modules-left = ["hyprland/workspaces"];
        modules-center = ["hyprland/window"];
        modules-right = [
          "wireplumber"
          "battery"
          "tray"
          "power-profiles-daemon"
          "clock"
          "custom/notification"
        ];

        "hyprland/workspaces" = {
          format = "{name} {icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "urgent" = "";
            "focused" = "";
            "default" = "";
          };
        };

        "hyprland/window" = {
          "rewrite" = {
            "(.*) — Mozilla Firefox" = "🌎 $1";
            "(.*) - fish" = "  [$1]";
          };
        };

        "power-profiles-daemon" = {
          "format" = "{icon}";
          "tooltip-format" = "Power profile= {profile}\nDriver= {driver}";
          "tooltip" = true;
          "format-icons" = {
            "default" = "";
            "performance" = "";
            "balanced" = "";
            "power-saver" = "";
          };
        };

        wireplumber = {
          "format" = "󰕿 {volume}%";
          "format-muted" = "󰝤 ";
          on-click = "pavucontrol";
          on-click-right = "qpwgraph";
          on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        battery = {
          "states" = {
            "warning" = 30;
            "critical" = 15;
          };
          "format" = "{icon} {capacity}%";
          "format-icons" = ["" "" "" "" ""];
        };

        clock = {
          "format" = "{:%H:%M}";
          "format-alt" = "{:%A, %B %d, %Y (%R)}";
          "tooltip-format" = "<tt><small>{calendar}</small></tt>";
          "calendar" = {
            "mode" = "month";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            "format" = {
              "months" = "<span color='#ffead3'><b>{}</b></span>";
              "days" = "<span color='#ecc6d9'><b>{}</b></span>";
              "weeks" = "<span color='#99ffdd'><b>W{}</b></span>";
              "weekdays" = "<span color='#ffcc66'><b>{}</b></span>";
              "today" = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          "actions" = {
            "on-scroll-up" = "shift_up";
            "on-scroll-down" = "shift_down";
          };
        };

        tray = {
          spacing = 2;
        };

        "custom/notification" = {
          "tooltip" = false;
          "format" = "{icon}";
          "format-icons" = {
            "notification" = "<span foreground='red'><sup></sup></span>";
            "none" = "";
            "dnd-notification" = "<span foreground='red'><sup></sup></span>";
            "dnd-none" = "";
            "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
            "dnd-inhibited-none" = "";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          "exec" = "swaync-client -swb";
          "on-click" = "swaync-client -t -sw";
          "on-click-right" = "swaync-client -d -sw";
          "escape" = true;
        };
      };
    };
    style = ''
      * {
          font-size: 13px;
          border: none;
          border-radius: 0;
      }
      window#waybar {
          background-color: rgba(43, 48, 59, 0.5);
          border-bottom: 3px solid rgba(100, 114, 125, 0.5);
          color: #ffffff;
          transition-property: background-color;
          transition-duration: .5s;
      }

      window#waybar.hidden {
          opacity: 0.2;
      }

      #workspaces button {
        padding: 0 2px;
        background: transparent;
        color: white;
        border-bottom: 3px solid transparent;
      }

      #workspaces button.active,
      #workspaces button.focused {
          border-bottom: 2px solid lightblue;
      }

      #workspaces button.urgent {
          border-bottom: 2px solid red;
      }

      #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #mpd {
          padding: 0 0 0 .5rem;
          color: #ffffff;
          font-family: 'monospace';
      }
      #tray > widget {
        padding-left: 2px;
      }
      #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: #eb4d4b;
      }
    '';
  };
}
