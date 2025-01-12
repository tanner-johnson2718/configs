# P1.1 Raw Socket Example

For the very first part of this project we create a raw socket example program. It consists of two programs. First a "poor mans" wireshark where dump all traffic on a specified interface. We use raw sockets so that we can observe the full ethernet frame that each packet consists of. This program is contained in the C file [sniff.c](./sniff.c). We also create a packet generator, [gen.c](./gen.c) that will send packets at a specific interval up to a maximum number packets across a specific interface with a customizable MAC source and destination.

# Key System Calls

```C
sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
```

```C
// interface_index contains the ascii name of the interface for which we want
// to bind our traffic too. IOCTL provides a programattic way of interfacing
// with kernel systems and data structures from userspace. In this case we use
// it to query the internal index of a specified interface.

struct ifreq interface_index = {0};
strncpy(&interface_index.ifr_name, interface_name, strlen(interface_name));
ret = ioctl(sock, SIOCGIFINDEX, &interface_index);
```

```C
struct sockaddr_ll inner_sockaddr = {0};

inner_sockaddr.sll_family = AF_PACKET;
inner_sockaddr.sll_protocol = htons(ETH_P_ALL);
inner_sockaddr.sll_ifindex = interface_index.ifr_ifindex;

ret = bind(sock, (struct sockaddr*) &inner_sockaddr, sizeof(struct sockaddr_ll));
```

```C
num_read = recv(sock, buff, size, 0);
```

```C
num_sent = send(sock, packet_buffer, packet_size, 0);
```

# Key concepts and nomenclature

* socket
* interface
* binding
* Address Families (AF)
* 802.3 Ethernet Frame
* ARP tables
* `ip` command
* `arp` command

# Resources
* `man socket`
* `man bind`
* `man ioctl`
* `man recv`
* `man send`
* `man packet`
* http://www.microhowto.info/howto/capture_ethernet_frames_using_an_af_packet_socket_in_c.html#idm247
* https://en.wikipedia.org/wiki/Ethernet_frame

# Where to go next

## Lab / Coding Next steps
* Run this code on physical hardware
    * Does the CRC get injected?
* Don't call a recv and see if we can overfill the packet buffer
* Get the RPI up
* Get the IEEE standards for this stuff

## Study Questions

* How are sockets implemented at the kernel level
    * How to FDs play a role
* Does a recv return 1 and only 1 packet
* What is the actual no shit max length of an ETH frame
* Address Families?
* What are the different send and recv's
* See if we can get the actual Linux kernel documentation