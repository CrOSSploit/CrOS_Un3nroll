#!/usr/bin/env bash

confirm() {
  while true; do
    read -rp "[Y/N] " yn
    case "$yn" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      *) echo "Please enter Y or N." ;;
    esac
  done
}

get_cb_info() {
  CB_INFO="$(sudo crossystem --all 2>/dev/null)"

  # Parse useful fields
  CB_BOARD="$(echo "$CB_INFO" | grep -E '^platform=' | cut -d= -f2)"
  CB_HWID="$(echo "$CB_INFO" | grep -E '^hwid=' | cut -d= -f2)"
  CB_FWID="$(echo "$CB_INFO" | grep -E '^fwid=' | cut -d= -f2)"
  CB_DEV="$(echo "$CB_INFO" | grep -E '^devsw_boot=' | cut -d= -f2)"
  CB_WP="$(echo "$CB_INFO" | grep -E '^wpsw_cur=' | cut -d= -f2)"
  CB_FWTYPE="$(echo "$CB_INFO" | grep -E '^mainfw_type=' | cut -d= -f2)"
}

while true; do
  clear
  get_cb_info
  cat <<'EOF'
 _   _       _____                 _ _                      _      _   _ _   _ _ _ _         
| | | |_ __ |___ / _ __  _ __ ___ | | |_ __ ___   ___ _ __ | |_   | | | | |_(_) (_) |_ _   _ 
| | | | '_ \  |_ \| '_ \| '__/ _ \| | | '_ ` _ \ / _ \ '_ \| __|  | | | | __| | | | __| | | |
| |_| | | | |___) | | | | | | (_) | | | | | | | |  __/ | | | |_   | |_| | |_| | | | |_| |_| |
 \___/|_| |_|____/|_| |_|_|  \___/|_|_|_| |_| |_|\___|_| |_|\__|___\___/ \__|_|_|_|\__|\__, |
                                                              |_____|                  |___/ 
   /\_/\
  ( 0.0 )
   > ^ <  << helper!!
EOF

  echo
  echo "[1] Disable State Determination/Enrollment [ONLY FOR R136+]"
  echo "[2] Change GBB Flags to 0x80b1 [WP MUST BE DISABLED]"
  echo
  echo "[Q] Quit | [P] Power Off | [R] Restart"
  echo

  read -rp "> " choice

  case "$choice" in
    1)
      echo "You have selected Disable State Determination, Proceed?"
      echo "WARNING: I have not implemented the commands for version milestones lower than R136, so this will only work if your version is above R136!"
      if confirm; then
        echo "TIP: The Terminal will restart once this completes, so don't think something went wrong when the Terminal restarts."
        sleep 3
        echo "Disabling State Determination..."
        echo --enterprise-enable-state-determination=never >/tmp/chrome_dev.conf
        mount --bind /tmp/chrome_dev.conf /etc/chrome_dev.conf
        initctl restart ui
      else
        echo "Cancelled."
        sleep 1
      fi
      ;;
    2)
      echo "You have selected Change GBB Flags to 0x80b1."
      echo "WARNING: This WILL fail if Write Protect is disabled!"
      sleep 1
      echo "Are you sure you want to proceed?"
      sleep 1
      if confirm; then
        echo "Changing GBB Flags to 0x80b1"
        futility gbb -s --flash --flags=0x80b1
        echo "GBB Flags have been changed to 0x80b1! Just to make sure it worked, go into Recovery, press tab, and look on the line gbb.flags"
        sleep 10
      else
        echo "Cancelled."
        sleep 1
      fi
      ;;
    q|Q)
      echo "Exiting..."
      exit 0
      ;;
    p|P)
      echo "Don't panic if your CB seems frozen!"
      poweroff
      ;;
    r|R)
      echo "Don't panic if your CB seems frozen!"
      reboot
      ;;
    *)
      echo "Invalid option"
      sleep 1
      ;;
  esac
done
