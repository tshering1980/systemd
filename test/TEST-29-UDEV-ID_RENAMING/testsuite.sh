#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
set -ex
set -o pipefail

mkdir -p /run/udev/rules.d/

cat > /run/udev/rules.d/50-testsuite.rules <<EOF
ACTION=="remove", GOTO="lo_end"

SUBSYSTEM=="net", KERNEL=="lo", TAG+="systemd", ENV{SYSTEMD_ALIAS}+="/sys/subsystem/net/devices/lo"

ACTION!="change", GOTO="lo_end"

SUBSYSTEM=="net", KERNEL=="lo", ENV{ID_RENAMING}="1"

LABEL="lo_end"
EOF

udevadm control --log-priority=debug --reload
udevadm trigger --action=add --settle /sys/devices/virtual/net/lo
udevadm info /sys/devices/virtual/net/lo
sleep 1
STATE=$(systemctl show --property=ActiveState --value sys-devices-virtual-net-lo.device)
[[ $STATE == "active" ]] || exit 1

udevadm trigger --action=change --settle /sys/devices/virtual/net/lo
udevadm info /sys/devices/virtual/net/lo
sleep 1
STATE=$(systemctl show --property=ActiveState --value sys-devices-virtual-net-lo.device)
[[ $STATE == "inactive" ]] || exit 1

udevadm trigger --action=move --settle /sys/devices/virtual/net/lo
udevadm info /sys/devices/virtual/net/lo
sleep 1
STATE=$(systemctl show --property=ActiveState --value sys-devices-virtual-net-lo.device)
[[ $STATE == "active" ]] || exit 1

rm -f /run/udev/rules.d/50-testsuite.rules
udevadm control --reload

echo OK > /testok

exit 0
