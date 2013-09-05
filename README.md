usermode-linux-containers
=========================

A script to easily create usermode linux containers

# What's this?
Usermode Linux is lightweight paravirtualization for Linux.

This script allows to easily and quickly create containers based on simple configuration files.

# How to use
First you create a config file for the container, see the ``example-container.conf``:

```
IP_ADDR=10.10.10.2
NETWORK=10.10.10.0
BROADCAST_ADDR=10.10.10.255
NETMASK=255.255.255.0
GATEWAY_ADDR=10.10.10.1

HOSTNAME=test
MEMORY=512M
DISK_SIZE=10240

#POST_INSTALL_SCRIPT=/root/custom_stuff.sh
```

and then pass this file to ``create_container.sh``:
```
# ./create_container.sh ./example-container.conf
==============================
HOSTNAME will be 'test'
==============================

==============================
Creating file system
==============================
dd if=/dev/zero of=test/root_fs count=10240 bs=1M

...

==============================
Finished
==============================

To launch the container, type:
cd test
./run

Have a lot of fun!
```
