#!/bin/sh

printf "Enter hostname: "
read hostname
if [ -z "$hostname" ]; then
    echo "Hostname cannot be empty."
    exit 1
fi
uci set system.@system[0].hostname="$hostname"
uci commit system

uci set system.@system[0].zonename='Asia/Singapore'
uci set system.@system[0].timezone='<+08>-8'

# Network: Tailscale interface
uci set network.TailscaleInt=interface
uci set network.TailscaleInt.proto='none'
uci set network.TailscaleInt.device='tailscale0'
uci set network.TailscaleInt.multipath='off'

uci add firewall rule
uci set firewall.@rule[-1].name='Allow-WAN-Management'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].dest_port='22 80 443'
uci set firewall.@rule[-1].target='ACCEPT'

# Firewall: Tailscale zone
uci add firewall zone
uci set firewall.@zone[-1].name='TailscaleFWZone'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='ACCEPT'
uci set firewall.@zone[-1].masq='1'
uci add_list firewall.@zone[-1].network='TailscaleInt'

# Firewall: forwarding TailscaleFWZone -> lan
uci add firewall forwarding
uci set firewall.@forwarding[-1].src='TailscaleFWZone'
uci set firewall.@forwarding[-1].dest='lan'

# Firewall: forwarding lan -> TailscaleFWZone
uci add firewall forwarding
uci set firewall.@forwarding[-1].src='lan'
uci set firewall.@forwarding[-1].dest='TailscaleFWZone'

#Firewall to allow TS network to remotely access the SSH and LUCI
uci set firewall.allow_luci_ssh_ts=rule
uci set firewall.allow_luci_ssh_ts.name='Allow-LuCI-SSH-LUCI-from-TS'
uci set firewall.allow_luci_ssh_ts.src='TailscaleFWZone'
uci set firewall.allow_luci_ssh_ts.proto='tcp'
uci set firewall.allow_luci_ssh_ts.dest_port='80 443 22'
uci set firewall.allow_luci_ssh_ts.target='ACCEPT'

uci set wireless.AP0=wifi-iface
uci set wireless.AP0.device='radio0'
uci set wireless.AP0.mode='ap'
uci set wireless.AP0.ssid='SOS_SSID'
uci set wireless.AP0.encryption='sae-mixed'
uci set wireless.AP0.key='12345678'
uci set wireless.AP0.network='lan'
uci set wireless.AP0.ieee80211r='1'
uci set wireless.AP0.mobility_domain='4f57'
uci set wireless.AP0.ft_over_ds='0'
uci set wireless.AP0.ft_psk_generate_local='1'

apk update
apk add openssh-sftp-server tmux nano pbr tailscale luci-app-tailscale-community wireguard-tools kmod-wireguard luci-proto-wireguard openvpn-openssl luci-app-openvpn

uci commit wireless
/sbin/wifi reload
uci commit network
uci commit firewall
service network restart
service firewall restart
uci commit system
/etc/init.d/system reload
