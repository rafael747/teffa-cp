# teffa-cp

## A simple tool for coping files around

The goal is to send a file to another computer in the lan, as fast as possible


### Dependences

 - pv - for progress bar
 - md5sum - for hashsum check
 - common tools like: dd, awk, nc, etc..

### How to install

 - link the script to your path, for exemple:

  ln -s /home/wharever/teffa-cp/tcp.sh /usr/bin/tcp

### How to use

 - to receive a file in the working directory

  tcp

 - to send a file

  tcp file <host>

> the host can be a IP address or a name, check your DNS configuration


## BUGS and TODO

 - The hosts must be acessible directly, no firewalls or NATs
 - Currently, using only port 2000/tcp
 - Option to GPG encryptation 
 - Option to skip md5sum
 - Bad english
