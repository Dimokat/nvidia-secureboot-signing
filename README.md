# NVIDIA Kernel Module Signing for Secure Boot (Linux)

This repository contains a setup script that automates signing NVIDIA kernel modules for Secure Boot. It generates Machine Owner Keys (MOK), installs a signing service, and enables it at boot to automatically resign modules after updates.

## 🚀 Features

- 📦 Automatically generates and stores signing keys
- 🔐 Signs all critical NVIDIA modules: `nvidia`, `nvidia_drm`, `nvidia_modeset`, `nvidia_uvm`
- 🖥️ Creates and enables a `systemd` service to ensure modules are re-signed on boot
- 📑 Includes logging via `journalctl`
- ✅ Secure Boot compatible

---

## 📋 Requirements

- Secure Boot enabled system
- `mokutil`, `openssl`, `modinfo`, and `systemd`
- NVIDIA proprietary drivers already installed

---

## ⚙️ Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Dimokat/nvidia-secureboot-signing.git
   cd nvidia-secureboot-signing
   ```

2. **Make the script executable and run it:**
   ```bash
   chmod +x setup-nvidia-signing.sh
   sudo ./setup-nvidia-signing.sh
   ```

3. **Enroll the MOK key** (you'll be prompted to set a password):
   ```bash
   sudo mokutil --import /var/lib/nvidia-signing/MOK.crt
   ```

4. **Reboot** your system. During boot, follow the on-screen instructions to enroll the key (you’ll need the password you set).

---

## 🧪 Verify

After reboot, check if the modules were signed:

```bash
dmesg | grep -i nvidia
sudo journalctl -u nvidia-signing.service
```

You should see success messages and no signature verification errors.

---

## 🔄 What Happens on Boot?

The `nvidia-signing.service`:
- Detects installed NVIDIA modules
- Uses the `sign-file` script from your kernel sources
- Signs each module with the MOK private key
- Outputs status to `journalctl -u nvidia-signing.service`

---

## 📂 Files Installed

| File                                  | Purpose                                 |
|---------------------------------------|-----------------------------------------|
| `/usr/local/bin/nvidia-sign.sh`       | Signing logic                           |
| `/etc/systemd/system/nvidia-signing.service` | Systemd service to run at boot     |
| `/var/lib/nvidia-signing/`            | Stores the private key and certificate  |

---

## 🧹 Uninstallation (Manual)

1. Disable the service:
   ```bash
   sudo systemctl disable nvidia-signing.service
   ```

2. Remove installed files:
   ```bash
   sudo rm -f /usr/local/bin/nvidia-sign.sh
   sudo rm -f /etc/systemd/system/nvidia-signing.service
   sudo rm -rf /var/lib/nvidia-signing/
   ```

3. Reload systemd:
   ```bash
   sudo systemctl daemon-reexec
   ```

---

## 📜 License

MIT

(P.S. Do whatever you want with it)
