## TCP Port Migration using FirewallD (DNAT) Example

This description assumes the following configuration on your OEL 8 server:

  * **External Network Interface (VNIC) :** `enp1s0`
  * **Destination Server IP (Port 2225):** `192.168.1.10`


-----

You may find a complete [bash script](files/create.bash) script that creates the port forwarding

### 1\. Enable IP Forwarding Permanently

This ensures the kernel is configured to route packets between the two network interfaces.

```bash
# 1. Edit /etc/sysctl.conf to ensure net.ipv4.ip_forward is set to 1.
# This sed command ensures the line exists and is uncommented.
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sed -i '$ a net.ipv4.ip_forward = 1' /etc/sysctl.conf

# 2. Apply the change immediately
sudo sysctl -p
```

-----

### 2\. Configure FirewallD NAT Rules

Use **FirewallD's rich rules** to apply the Destination Network Address Translation (DNAT).

#### A. Add the Port Redirection Rule (DNAT)

This rule redirects traffic arriving on port **25** on the external interface (`enp1s0`) to port **2225** on the internal destination server (`192.168.1.10`).

```bash
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" \
  in-interface="enp1s0" \
  forward-port port="25" protocol="tcp" \
  to-port="2225" to-addr="192.168.1.10"'
```

#### B. Enable Masquerading (Source NAT)

Enable Masquerading on the external zone to ensure that the destination server's replies are correctly routed back to the original client.

```bash
# Ensure the external interface is in a suitable zone (e.g., 'external')
# If enp1s0 is not already assigned to 'external' zone, use this command:
# sudo firewall-cmd --permanent --zone=external --add-interface=enp1s0

# Enable Masquerading on the zone hosting the external interface
sudo firewall-cmd --permanent --zone=external --add-masquerade
```

-----

### 3\. Activate Changes and Verify

Reload the firewall to activate the new permanent rules.

```bash
sudo firewall-cmd --reload
```

To verify the rich rule was applied correctly, list the rules for the zone hosting your external interface (e.g., `external`):

```bash
sudo firewall-cmd --list-all --zone=external
```

You should see an entry under the **rich rules** section reflecting the DNAT configuration.
