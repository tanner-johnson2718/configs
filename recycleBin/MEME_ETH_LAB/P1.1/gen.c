// gen.c raw ethernet packet generator. Will send packets to a hard coded MAC 
// out a hard coded interface. Will have hard coded params for setting size and
// freq of packet transmits as well as a max number of packets sent

// sniff.c has some better doc and this file is meant to be rather basic.

#define _GNU_SOURCE 

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <errno.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <net/ethernet.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <net/if.h>
#include <linux/if_packet.h>
#include <netinet/ether.h>
#include <sys/ioctl.h>
#include <time.h>

const int num_packets_to_send = 10;
const int delay_ms = 1000;    
const int sec_mod_factor = 1000;
const int nsec_div_factor = 1000*1000;     

const int packet_size = 128;       // includes header, not crc though
const char payload_byte = 0xA5;    // byte repeated to fill packet
const unsigned char mac_src[6];
const unsigned char mac_dst[6];
const unsigned char tag[2] = {0x69, 0x69};

char interface_name[16];

int main(int argc, char** argv)
{
    unsigned char* packet_buffer = NULL;
    int sock = 0, ret = 0, i = 0, num_sent = 0;
    struct sockaddr_ll inner_sockaddr = {0};
    struct ifreq interface_index = {0};
    struct timespec time = {0}, time_now = {0};

    // process comannd line args. Expects ./<prog> <if_name> <mac_dst> <mac_src>
    if(argc != 4)
    {
        printf("ERROR usage ./%s <if_name>\n", argv[0]);
        exit(1);
    }

    // Parse if_name
    if(strlen(argv[1]) > 15)
    {
        printf("ERROR interface name to long\n");
        exit(1);
    }

    i = 0;
    while(argv[1][i] != (char) 0)
    {
        interface_name[i] = argv[1][i];
        ++i;
    }

    interface_name[i] = (char) 0;

    // Parse 
    if(strlen(argv[2]) != 17)
    {
        printf("ERROR, mac_addr must be of xx:xx:xx:xx:xx:xx\n");
        exit(1);
    }
    sscanf();

    time.tv_nsec = (delay_ms % 1000)*1000*1000;
    time.tv_sec = delay_ms / 1000;

    // Allocate Buffer 
    packet_buffer = malloc(packet_size);
    if(packet_buffer == NULL)
    {
        perror("Malloc Failed to Create Packet Buffer");
        exit(1);
    }

    // Populate packet with payload byte
    for(i = 0; i < packet_size; ++i)
    {
        packet_buffer[i] = payload_byte;
    }

    // Fill in eth headers
    for(i = 0; i < 6; ++i)
    {
        packet_buffer[i] = mac_dst[i];
        packet_buffer[i+6] = mac_src[i];
    }
    packet_buffer[12] = tag[0];
    packet_buffer[13] = tag[0];

    // Open a socket
    sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if(sock < 1)
    {
        perror("Failed to create socket");
        exit(1);
    }

    // Bind it to the specified interface
    memset(&inner_sockaddr, 0, sizeof(struct sockaddr_ll));
    memset(&interface_index, 0, sizeof(struct ifreq));

    strncpy(&interface_index.ifr_name, interface_name, strlen(interface_name));
    ret = ioctl(sock, SIOCGIFINDEX, &interface_index);
    if(ret < 0)
    {
        perror("ioctl");
        exit(1);
    }

    inner_sockaddr.sll_family = AF_PACKET;
    inner_sockaddr.sll_protocol = htons(ETH_P_ALL);
    inner_sockaddr.sll_ifindex = interface_index.ifr_ifindex;

    printf("Index of %s = %d\n", interface_name, interface_index.ifr_ifindex);

    ret = bind(sock, (struct sockaddr*) &inner_sockaddr, sizeof(struct sockaddr_ll));
    if(ret < 0)
    {
        perror("bind");
        exit(1);
    }

    // Transmit Data
    for(i = 0 ; i < num_packets_to_send; ++i)
    {
        num_sent = send(sock, packet_buffer, packet_size, 0);
        clock_gettime(CLOCK_REALTIME, &time_now);

        printf("Num Bytes Sent = %d at %ld.%ld\n", num_sent, time_now.tv_sec % sec_mod_factor, time_now.tv_nsec / nsec_div_factor);

        ret = nanosleep(&time, NULL);
        if (ret < 0)
        {
            printf("sleep interrupted\n");
        }
    }

    printf("Exiting...\n");
    free(packet_buffer);
    close(sock);
}