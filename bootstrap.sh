#!/bin/sh

echo "Installing dependencies..."
apt-get install wget user-mode-linux uml-utilities bridge-utils debootstrap realpath

echo "Setting up the tap0 network device..."
echo "

    auto tap0
    iface tap0 inet static
            address 10.10.10.1
            netmask 255.255.255.0
            tunctl_user uml-net
" > /etc/network/interfaces

echo "Adding the switched device to /etc/defaults/uml-utilities..."
echo 'UML_SWITCH_OPTIONS="-tap tap0"' >> /etc/defaults/uml-utilities

echo "Stopping UML daemon..."
/etc/init.d/uml-utilities stop

echo "Bringing up tap0 adapter..."
ifup tap0

echo "Starting UML daemon..."
/etc/init.d/uml-utilities start

echo "Done."
