#!/usr/bin/env bash

# this looks so unorganized - Ace
# i either need to get used to bash scripts or just seperate everything - Ace

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

LSB_RELEASE="/etc/lsb-release"

if [[ -r "$LSB_RELEASE" ]]; then
  # shellcheck disable=SC1091
  source "$LSB_RELEASE"
  # so then the shell doesn't piss itself or whatever
else
  echo "ERROR: Cannot read $LSB_RELEASE"
  sleep 2
  exit 1
fi

if [[ -z "${CHROMEOS_RELEASE_CHROME_MILESTONE}" ]]; then
  echo "ERROR: ChromeOS milestone not found!"
  sleep 2
  exit 1
fi

MILESTONE="${CHROMEOS_RELEASE_CHROME_MILESTONE}"

while true; do
  clear
  cat <<'EOF'
  ____       ___  ____    _   _       _____                 _ _ 
 / ___|_ __ / _ \/ ___|  | | | |_ __ |___ / _ __  _ __ ___ | | |
| |   | '__| | | \___ \  | | | | '_ \  |_ \| '_ \| '__/ _ \| | |
| |___| |  | |_| |___) | | |_| | | | |___) | | | | | | (_) | | |
 \____|_|   \___/|____/___\___/|_| |_|____/|_| |_|_|  \___/|_|_|
                     |_____|                                    
By CrOSSploit!
EOF

  echo
  echo "[1] Disable State Determination / Enrollment [NEW: ALL VERSIONS SUPPORTED!]"
  echo "[2] Change GBB Flags to 0x80b1 [WP MUST BE DISABLED]"
  echo
  echo "[Q] Quit | [P] Power Off | [R] Restart"
  echo

  read -rp "> " choice

  case "$choice" in
    1)
      echo "You have selected Disable State Determination / Enrollment."
      echo "Detected ChromeOS Milestone: R${MILESTONE}"
      echo
      echo "Proceed?"

      if confirm; then
        echo "INFO: The UI will restart when finished."
        sleep 2

        if [[ "$MILESTONE" -le 110 ]]; then
          echo "Using R110 and lower method..."
          echo "NOTE: Powerwash is required after this."
          vpd -i RW_VPD -s check_enrollment=0

        elif [[ "$MILESTONE" -ge 111 && "$MILESTONE" -le 124 ]]; then
          echo "Using R111–R124 method..."
          echo "NOTE: Powerwash is required after this."
          vpd -i RW_VPD -s check_enrollment=0
          tpm_manager_client take_ownership
          cryptohome --action=remove_firmware_management_parameters

        elif [[ "$MILESTONE" -ge 125 && "$MILESTONE" -le 135 ]]; then
          echo "Using R125–R135 unified determination method..."
          echo "NOTE: Do NOT reboot until setup is complete."

          echo --enterprise-enable-unified-state-determination=never >/tmp/chrome_dev.conf
          echo --enterprise-enable-forced-re-enrollment=never >>/tmp/chrome_dev.conf
          echo --enterprise-enable-initial-enrollment=never >>/tmp/chrome_dev.conf
          mount --bind /tmp/chrome_dev.conf /etc/chrome_dev.conf
          initctl restart ui

        else
          echo "Using R136+ modern state determination method..."

          echo --enterprise-enable-state-determination=never >/tmp/chrome_dev.conf
          mount --bind /tmp/chrome_dev.conf /etc/chrome_dev.conf
          initctl restart ui
        fi

        echo
        echo "Done."
        sleep 5
      else
        echo "Cancelled."
        sleep 1
      fi
      ;;
    2)
      echo "You have selected Change GBB Flags to 0x80b1."
      echo "WARNING: This WILL fail if Write Protect is ENABLED!"
      echo "Are you sure you want to proceed?"
      sleep 2

      if confirm; then
        echo "Changing GBB Flags to 0x80b1"
        futility gbb -s --flash --flags=0x80b1
        echo "GBB Flags have been changed to 0x80b1!"
        echo "Verify in Recovery (TAB) → gbb.flags"
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
      poweroff # command skidded from mrchromebox's firmware utility script (jk)
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
