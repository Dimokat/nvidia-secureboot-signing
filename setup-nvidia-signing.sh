#!/bin/bash

set -e

KEY_DIR="/var/lib/nvidia-signing"
KEY="$KEY_DIR/MOK.key"
CRT="$KEY_DIR/MOK.crt"
SCRIPT_PATH="/usr/local/bin/nvidia-sign.sh"
SERVICE_PATH="/etc/systemd/system/nvidia-signing.service"

echo "[*] Creating signing key..."
sudo mkdir -p "$KEY_DIR"
sudo openssl req -new -x509 -newkey rsa:2048 -keyout "$KEY" -out "$CRT" -nodes -days 36500 -subj "/CN=NVIDIA Secure Boot Module/" || {
    echo "[-] Failed to create keys"
    exit 1
}

echo "[*] Installing signing script..."
sudo tee "$SCRIPT_PATH" > /dev/null << 'EOF'
#!/bin/bash

KEY="/var/lib/nvidia-signing/MOK.key"
CRT="/var/lib/nvidia-signing/MOK.crt"

echo "[ $(date) ] ===== Starting NVIDIA module signing ====="

SIGNFILE=$(find /usr/src -name sign-file | head -n 1)
if [[ ! -x "$SIGNFILE" ]]; then
    echo "[ $(date) ] sign-file not found"
    exit 1
fi

for MOD_NAME in nvidia nvidia_drm nvidia_modeset nvidia_uvm; do
    MOD_PATH=$(modinfo -n $MOD_NAME 2>/dev/null)
    if [[ -f "$MOD_PATH" ]]; then
        echo "[ $(date) ] Signing $MOD_NAME: $MOD_PATH"
        "$SIGNFILE" sha256 "$KEY" "$CRT" "$MOD_PATH" && \
        echo "[ $(date) ] SUCCESS: $MOD_NAME signed" || \
        echo "[ $(date) ] FAILED: $MOD_NAME signing failed"
    fi
done

echo "[ $(date) ] ===== Signing completed ====="
EOF

sudo chmod +x "$SCRIPT_PATH"

echo "[*] Installing systemd service..."
sudo tee "$SERVICE_PATH" > /dev/null << 'EOF'
[Unit]
Description=Resign NVIDIA kernel module for Secure Boot
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nvidia-sign.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "[*] Reloading systemd and enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable nvidia-signing.service

echo "[*] Please run 'sudo mokutil --import $CRT' and reboot to enroll the MOK key."
echo "[*] Setup complete."
