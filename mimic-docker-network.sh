#!/bin/bash

# *** Should be run as root user (not sudo) ***

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

ip link add docker0 type bridge
ip addr add 172.17.0.1/16 dev docker0
ip link set docker0 up
iptables -t filter -A FORWARD -s 172.17.0.0/16 -j ACCEPT
iptables -t filter -A FORWARD -d 172.17.0.0/16 -j ACCEPT
iptables -t nat -A POSTROUTING -s 172.17.0.0/16 -j MASQUERADE

ip netns add RED
ip link add eth0 netns RED type veth peer name veth0
ip netns exec RED ip addr add 172.17.0.2/16 dev eth0
ip link set veth0 master docker0
ip netns exec RED ip link set eth0 up
ip link set veth0 up
ip netns exec RED ip route add default via 172.17.0.1

ip netns add BLUE
ip link add eth0 netns BLUE type veth peer name veth1
ip netns exec BLUE ip addr add 172.17.0.3/16 dev eth0
ip link set veth1 master docker0
ip netns exec BLUE ip link set eth0 up
ip link set veth1 up
ip netns exec BLUE ip route add default via 172.17.0.1

## Test in RED container
# nsenter --net=/var/run/netns/RED
# ping -c 1 172.17.0.3 # ping to BLUE container
# ping -c 1 <host>     # ping to host
# ping -c 1 8.8.8.8    # ping to outside

## Test in BLUE container
# nsenter --net=/var/run/netns/BLUE
# ping -c 1 172.17.0.2 # ping to RED container
# ping -c 1 <host>     # ping to host
# ping -c 1 8.8.8.8    # ping to outside
