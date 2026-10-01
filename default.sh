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

apk update
apk add openssh-sftp-server tmux nano pbr tailscale luci-app-tailscale-community wireguard-tools kmod-wireguard luci-proto-wireguard openvpn-openssl luci-app-openvpn

uci add firewall rule
uci set firewall.@rule[-1].name='Allow-WAN-Management'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].dest_port='22 80 443'
uci set firewall.@rule[-1].target='ACCEPT'

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

uci commit wireless
/sbin/wifi reload
uci commit firewall
service firewall restart
uci commit system
/etc/init.d/system reload
