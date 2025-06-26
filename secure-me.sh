#!/bin/bash

# secure-me.sh – Instant Linux Hardening Script
# Author: Jerad “Jay” [github.com/jeradzackusedevs]
# Logs everything to /var/log/secure-me.log

LOG_FILE="/var/log/secure-me.log"
touch $LOG_FILE

log() {
    echo "[+] $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "Run this script as root!"
        exit 1
    fi
}

update_system() {
    log "Updating packages..."
    apt update && apt upgrade -y
    log "System updated."
}

setup_firewall() {
    log "Installing and configuring UFW firewall..."
    apt install ufw -y
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw --force enable
    log "UFW firewall configured and enabled."
}

install_fail2ban() {
    log "Installing fail2ban..."
    apt install fail2ban -y
    systemctl enable fail2ban
    systemctl start fail2ban
    log "fail2ban installed and running."
}

secure_ssh() {
    log "Securing SSH configuration..."
    sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl reload sshd
    log "SSH hardened: root login and password auth disabled."
}

install_rkhunter() {
    log "Installing rootkit scanner (rkhunter)..."
    apt install rkhunter -y
    rkhunter --update
    rkhunter --propupd -q
    rkhunter --checkall --skip-keypress
    log "rkhunter installed and scanned."
}

enable_auto_updates() {
    log "Enabling unattended upgrades..."
    apt install unattended-upgrades -y
    dpkg-reconfigure --priority=low unattended-upgrades
    log "Automatic updates enabled."
}

setup_login_alerts() {
    log "Adding SSH login alert..."
    cat <<EOF > /etc/profile.d/ssh-alert.sh
#!/bin/bash
IP=\$(who | awk '{print \$5}' | tr -d '()')
echo "SSH login on \$(hostname) from \$IP" | mail -s "SSH Login Alert" root
EOF
    chmod +x /etc/profile.d/ssh-alert.sh
    log "SSH login alert configured."
}

enable_auditd() {
    log "Installing auditd for login tracking..."
    apt install auditd -y
    systemctl enable auditd
    systemctl start auditd
    log "auditd enabled and logging."
}

secure_tmp() {
    log "Securing /tmp and /var/tmp directories..."
    chmod 1777 /tmp
    chmod 1777 /var/tmp
    log "/tmp directories secured."
}

show_menu() {
    clear
    echo "=== Secure-Me – Linux Hardening Tool ==="
    echo "1. Update System"
    echo "2. Set Up Firewall"
    echo "3. Install Fail2Ban"
    echo "4. Harden SSH"
    echo "5. Install rkhunter"
    echo "6. Enable Auto Updates"
    echo "7. Add SSH Login Alerts"
    echo "8. Enable Login Auditing"
    echo "9. Secure /tmp Directories"
    echo "10. Run All"
    echo "0. Exit"
    echo "========================================"
    read -p "Choose an option: " opt

    case $opt in
        1) update_system ;;
        2) setup_firewall ;;
        3) install_fail2ban ;;
        4) secure_ssh ;;
        5) install_rkhunter ;;
        6) enable_auto_updates ;;
        7) setup_login_alerts ;;
        8) enable_auditd ;;
        9) secure_tmp ;;
        10)
            update_system
            setup_firewall
            install_fail2ban
            secure_ssh
            install_rkhunter
            enable_auto_updates
            setup_login_alerts
            enable_auditd
            secure_tmp
            ;;
        0) exit 0 ;;
        *) echo "Invalid option." ;;
    esac
}

# === Main ===
check_root
show_menu

