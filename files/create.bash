#!/bin/bash
# Script to configure TCP port forwarding (25 -> 192.168.1.10:2225) using FirewallD

# --- Configuration Variables ---
EXTERNAL_NIC="enp1s0"
DESTINATION_IP="192.168.1.10"
INCOMING_PORT="25"
DESTINATION_PORT="2225"
FIREWALL_ZONE="external"

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

echo "Starting TCP port forwarding configuration..."

# 2. Enable IP Forwarding Permanently in the Kernel
echo "2. Enabling IP forwarding..."
if ! grep -q "^net.ipv4.ip_forward = 1" /etc/sysctl.conf; then
  echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
fi
sysctl -p

# 3. Configure FirewallD Zone for External Interface (optional, but ensures zone is correct)
echo "3. Assigning ${EXTERNAL_NIC} to ${FIREWALL_ZONE} zone..."
firewall-cmd --permanent --zone="${FIREWALL_ZONE}" --add-interface="${EXTERNAL_NIC}"
firewall-cmd --zone="${FIREWALL_ZONE}" --add-interface="${EXTERNAL_NIC}"

# 4. Enable Masquerading (Source NAT) in the Zone
echo "4. Enabling Masquerading (SNAT) on ${FIREWALL_ZONE}..."
firewall-cmd --permanent --zone="${FIREWALL_ZONE}" --add-masquerade

# 5. Add the DNAT (Destination NAT/Port Redirection) Rule
echo "5. Adding DNAT rule: ${INCOMING_PORT} -> ${DESTINATION_IP}:${DESTINATION_PORT}..."

firewall-cmd --permanent --zone="${FIREWALL_ZONE}" --add-rich-rule="rule family=\"ipv4\" \
  in-interface=\"${EXTERNAL_NIC}\" \
  forward-port port=\"${INCOMING_PORT}\" protocol=\"tcp\" \
  to-port=\"${DESTINATION_PORT}\" to-addr=\"${DESTINATION_IP}\""

# 6. Apply the New Rules
echo "6. Reloading FirewallD to apply changes..."
firewall-cmd --reload

# 7. Verification
echo -e "\n--- VERIFICATION ---"
echo "IP forwarding status:"
sysctl net.ipv4.ip_forward

echo "FirewallD ${FIREWALL_ZONE} rules:"
firewall-cmd --list-all --zone="${FIREWALL_ZONE}" | grep "rich rules" -A 4

echo -e "\nConfiguration complete. Traffic on port ${INCOMING_PORT} should now be forwarded to ${DESTINATION_IP}:${DESTINATION_PORT}."
