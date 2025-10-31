#!/bin/bash

set +e

CURRENT_HOSTNAME="$(cat /etc/hostname | tr -d " \t\n\r")"
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
  /usr/lib/raspberrypi-sys-mods/imager_custom set_hostname "$PI_HOSTNAME"
else
  echo "$PI_HOSTNAME" >/etc/hostname
  sed -i "s/127.0.1.1.*${CURRENT_HOSTNAME}/127.0.1.1\t${PI_HOSTNAME}/g" /etc/hosts
fi
FIRSTUSER="$(getent passwd 1000 | cut -d: -f1)"
FIRSTUSERHOME="$(getent passwd 1000 | cut -d: -f6)"
if [ -f /usr/lib/raspberrypi-sys-mods/imager_custom ]; then
  /usr/lib/raspberrypi-sys-mods/imager_custom enable_ssh -k "$PUBLIC_SSH_KEY" "$PUBLIC_SSH_KEY"
else
  install -o "$FIRSTUSER" -m 700 -d "${FIRSTUSERHOME}/.ssh"
  install -o "$FIRSTUSER" -m 600 <(printf "%s\n%s\n" "$PUBLIC_SSH_KEY" "$PUBLIC_SSH_KEY") "${FIRSTUSERHOME}/.ssh/authorized_keys"
  echo 'PasswordAuthentication no' >>/etc/ssh/sshd_config
  systemctl enable ssh
fi
if [ -f /usr/lib/userconf-pi/userconf ]; then
  /usr/lib/userconf-pi/userconf "$PI_USERNAME" "$PI_PASSWORD_HASH"
else
  echo "${FIRSTUSER}:""${PI_PASSWORD_HASH}" | chpasswd -e
  if [ "$FIRSTUSER" != "$PI_USERNAME" ]; then
    usermod -l "$PI_USERNAME" "$FIRSTUSER"
    usermod -m -d "/home/${PI_USERNAME}" "$PI_USERNAME"
    groupmod -n "$PI_USERNAME" "$FIRSTUSER"
    if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf; then
      sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=${PI_USERNAME}/"
    fi
    if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
      sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/${FIRSTUSER}/${PI_USERNAME}/"
    fi
    if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
      sed -i "s/^${FIRSTUSER} /${PI_USERNAME} /" /etc/sudoers.d/010_pi-nopasswd
    fi
  fi
fi
rm -f /boot/firstrun.sh
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
exit 0
