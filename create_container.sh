#!/bin/sh

### Loading config file
. $1
echo
echo "=============================="
echo "HOSTNAME will be '$HOSTNAME'"
echo "=============================="
echo

### functions

f() { echo "Failed."; exit; }

setup_net()
{
  echo
  echo "=============================="
  echo "Configuring network"
  echo "=============================="
  echo


  echo ""
  echo "  IP address:        $IP_ADDR"
  echo "  Network:           $NETWORK"
  echo "  Broadcast address: $BROADCAST_ADDR"
  echo "  Netmask:           $NETMASK"
  echo "  Gateway:           $GATEWAY"
  echo ""
}

### our script begins here

if [ "`id -u`" != "0" ]; then
  echo "I won't run as user. I need root."
  exit 1
fi


echo
echo ==============================
echo Creating file system
echo ==============================
echo

mkdir $HOSTNAME || f
# print this so the user does not think that the script is hanging
echo dd if=/dev/zero of=$HOSTNAME/root_fs count=$DISK_SIZE bs=1M
dd if=/dev/zero of=$HOSTNAME/root_fs count=$DISK_SIZE bs=1M || f
/sbin/mke2fs -F $HOSTNAME/root_fs || f
mkdir $HOSTNAME/install || f
mount -o loop $HOSTNAME/root_fs $HOSTNAME/install || f

echo
echo ==============================
echo Installing the base system
echo ==============================
echo
debootstrap wheezy $HOSTNAME/install http://ftp.us.debian.org/debian || f

echo
echo ==============================
echo Configuring the base system
echo ==============================
echo

echo '# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
/dev/ubd0        /             ext2    defaults                 0    0
proc             /proc         proc    defaults                 0    0' \
> $HOSTNAME/install/etc/fstab


echo '# /etc/inittab: init(8) configuration.
# $Id: inittab,v 1.91 2002/01/25 13:35:21 miquels Exp $

# The default runlevel.
id:2:initdefault:

# Boot-time system configuration/initialization script.
# This is run first except when booting in emergency (-b) mode.
si::sysinit:/etc/init.d/rcS

# What to do in single-user mode.
~:S:wait:/sbin/sulogin

# /etc/init.d executes the S and K scripts upon change
# of runlevel.
#
# Runlevel 0 is halt.
# Runlevel 1 is single-user.
# Runlevels 2-5 are multi-user.
# Runlevel 6 is reboot.

l0:0:wait:/etc/init.d/rc 0
l1:1:wait:/etc/init.d/rc 1
l2:2:wait:/etc/init.d/rc 2
l3:3:wait:/etc/init.d/rc 3
l4:4:wait:/etc/init.d/rc 4
l5:5:wait:/etc/init.d/rc 5
l6:6:wait:/etc/init.d/rc 6
# Normally not reached, but fallthrough in case of emergency.
z6:6:respawn:/sbin/sulogin

# What to do when CTRL-ALT-DEL is pressed.
ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

# Action on special keypress (ALT-UpArrow).
#kb::kbrequest:/bin/echo "Keyboard Request--edit /etc/inittab to let this work."

# What to do when the power fails/returns.
pf::powerwait:/etc/init.d/powerfail start
pn::powerfailnow:/etc/init.d/powerfail now
po::powerokwait:/etc/init.d/powerfail stop

# /sbin/getty invocations for the runlevels.
#
# The "id" field MUST be the same as the last
# characters of the device (after "tty").
#
# Format:
#  <id>:<runlevels>:<action>:<process>
#
# Note that on most Debian systems tty7 is used by the X Window System,
# so if you want to add more getty'\''s go ahead but skip tty7 if you run X.
#
0:1235:respawn:/sbin/getty 38400 console linux
#1:2345:respawn:/sbin/getty 38400 tty1
#2:23:respawn:/sbin/getty 38400 tty2
#3:23:respawn:/sbin/getty 38400 tty3
#4:23:respawn:/sbin/getty 38400 tty4
#5:23:respawn:/sbin/getty 38400 tty5
#6:23:respawn:/sbin/getty 38400 tty6

# Example how to put a getty on a serial line (for a terminal)
#
#T0:23:respawn:/sbin/getty -L ttyS0 9600 vt100
#T1:23:respawn:/sbin/getty -L ttyS1 9600 vt100

# Example how to put a getty on a modem line.
#
#T3:23:respawn:/sbin/mgetty -x0 -s 57600 ttyS3' > $HOSTNAME/install/etc/inittab

echo $HOSTNAME > $HOSTNAME/install/etc/hostname

# set up apt
cp /etc/apt/sources.list $HOSTNAME/install/etc/apt/sources.list || f


# install SSH & puppet
chroot $HOSTNAME/install apt-get -y update || f
chroot $HOSTNAME/install apt-get -y install ssh puppet curl || f


#Network configuration
setup_net

echo '# Used by ifup(8) and ifdown(8). See the interfaces(5) manpage or
# /usr/share/doc/ifupdown/examples for more information.
auto lo
iface lo inet loopback

# eth0
auto eth0
iface eth0 inet static
   address '$IP_ADDR'
   netmask '$NETMASK'
   network '$NETWORK'
   broadcast '$BROADCAST_ADDR'
   gateway '$GATEWAY_ADDR > $HOSTNAME/install/etc/network/interfaces
   
echo
echo ==============================
echo Create root password
echo ==============================
echo

chroot $HOSTNAME/install su - root -c "usermod -p `mkpasswd root` root"

echo
echo ==============================
echo Creating user
echo Username: vagrant
echo Password: vagrant
echo ==============================
echo

chroot $HOSTNAME/install su - root -c "groupadd vagrant && useradd -g vagrant -m --home /vagrant -s /bin/bash vagrant && usermod -p `mkpasswd vagrant` vagrant"

if [ -n "$POST_INSTALL_SCRIPT" ]; then

    echo
    echo ==============================
    echo Running post install script at
    echo $POST_INSTALL_SCRIPT
    echo ==============================
    echo

    . $POST_INSTALL_SCRIPT

    echo
    echo ==============================
    echo FINISHED post install script
    echo ==============================
    echo

fi

# clean up
umount $HOSTNAME/install
rmdir $HOSTNAME/install

echo
echo ==============================
echo Creating start script
echo ==============================
echo

#Write start script

echo '#!/bin/sh

linux mem='$MEMORY' eth0=daemon umid='$HOSTNAME > $HOSTNAME/run

chmod +x $HOSTNAME/run

echo
echo ==============================
echo Finished
echo ==============================
echo
echo To launch the container, type:
echo   cd $HOSTNAME
echo   ./run
echo
echo Have a lot of fun!
echo
