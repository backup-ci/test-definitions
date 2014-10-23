#!/bin/sh
#
# Multiple network interfaces test for ubuntu
#
# Copyright (C) 2013, Linaro Limited.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# Author: Chase Qi <chase.qi@linaro.org>

# Define gateway
GATEWAY=$1
echo "GATEWAY: $GATEWAY"

# Print network interfaces list
echo "================"
echo "Print all network interfaces"
ifconfig -a

# Correction of ARP flux
address_arp_flux(){
    echo "==============="
    echo "Address ARP flux test"
    for Interface in `ifconfig -a |grep eth |awk '{print $1}'`; do
        echo 0 > /proc/sys/net/ipv4/conf/$Interface/rp_filter
        echo "$Interface rp_filter: `cat /proc/sys/net/ipv4/conf/$Interface/rp_filter`"
        echo 1 > /proc/sys/net/ipv4/conf/$Interface/arp_ignore
        echo "$Interface arp_ignore: `cat /proc/sys/net/ipv4/conf/$Interface/arp_ignore`"
        echo 2 > /proc/sys/net/ipv4/conf/$Interface/arp_announce
        echo "$Interface arp_announce: `cat /proc/sys/net/ipv4/conf/$Interface/arp_announce`"
    done

    if [ $? -ne 0 ]; then
        echo "address-arp-flux:" "fail"
        return 1
    else
        echo "address-arp-flux:" "pass"
    fi
}

# Interface enable test
interface_enable_test(){
    local ethx=$1
    echo "========================="
    echo "$ethx interface enable test"
    ifconfig $ethx up

    if [ $? -ne 0 ]; then
        echo "$ethx-interface-enable-test:" "fail"
        return 1
    else
        echo "$ethx-interface-enable-test:" "pass"
    fi
}

# Link detect
link_detect(){
    local ethx=$1
    echo "===================="
    echo "$ethx link detect test"
    link=`cat /sys/class/net/$ethx/carrier`

    if [ $link -ne 1 ]; then
        echo "Please check $ethx LAN cable"
        echo "$ethx-link-detect:" "fail"
        return 1
    else
        echo "$ethx-link-detect:" "pass"
    fi

}

# IP not empty test
ip_not_empty(){
    local ethx=$1
    echo "====================="
    echo "$ethx-ip-not-empty test"
    dhclient $ethx
    IP=$(ifconfig $ethx | grep "inet addr" | awk '{print $2}')

    if [ -z $IP ]; then
        echo "$ethx have no IP address"
        echo "$ethx-ip-not-empty:" "fail"
        return 1
    else
        echo "$ethx IP $IP"
        echo "$ethx-ip-not-empty:" "pass"
    fi
}

# ping test
ping_test(){
    local ethx=$1
    echo "============="
    echo "$ethx ping test"
    ping -c 5 -I $ethx $GATEWAY

    if [ $? -ne 0 ]; then
        echo "Ping test through $ethx failed"
        echo "$ethx-ping-test:" "fail"
        return 1
    else
        echo "$ethx-ping-test:" "pass"
    fi
}

# Run the tests
address_arp_flux
for Interface in `ifconfig -a |grep eth |awk '{print $1}'`; do
  if test "$Interface" = "eth0"
  then
      ping_test $Interface
  else
      interface_enable_test $Interface
      link_detect $Interface
      ip_not_empty $Interface
      ping_test $Interface
  fi
done
    
# clean exit so lava-test can trust the results
exit 0