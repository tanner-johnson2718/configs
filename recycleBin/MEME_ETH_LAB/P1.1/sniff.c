// Some C socket code that messes with raw sockets. For now this program is a
// poor mans wire shark and just dumps all frames seen on all interfaces. There
// is an optional hardcoded param that allows one to specify a specific
// interface for which to only display traffic from. 

// |---------------------------------------------------------------------------
// | Key Sys Calls
// | ---------------------------------------------------------------------------
// | 
// | socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
// | recv(sock, buff, max_ethframe_size, 0);
// | bind()
// | ioctl() -> to get interface index off socket
// | send()
// |
// |---------------------------------------------------------------------------

// |---------------------------------------------------------------------------
// | Key Commands
// |---------------------------------------------------------------------------
// | 
// | `ip a`       | Shows all net interfaces, IP, and MAC 
// | `arp`        | Shows all resolved MACs via ARP
// | `man packet` | man page on low level packets
// |
// |---------------------------------------------------------------------------

// |---------------------------------------------------------------------------
// | 802.3 Layer 2 Frame (Non VlAN i.e. 802.1Q)
// |---------------------------------------------------------------------------
// |
// | MAC DST | MAC SRC | TAG | PAYLOAD | CRC | 
// |    6    |    6    |  2  | 46-1500 |  4  |
// |---------------------------------------------------------------------------

// |---------------------------------------------------------------------------
// | Questions 
// |---------------------------------------------------------------------------
// | 
// | Is a call to recv() garmented to return 1 and only 1 packet?
// | Max Lengths w/ and w/out vlan shit??
// | What happens when I dont call recv does that ring buffer fill??
// | How do fd's play a role in sockets?
// | How does the loopback interface work?
// | Address families?
// | when does the crc get injected?
// | Is a crc attached when I read a AF_PACKET frame?
// | What do the different sends and recvs do?
// | 
// |---------------------------------------------------------------------------

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

const int max_ethframe_size = 1522;
const int raw_hex_dump_num_bytes_per_block = 8;

const int mac_len = 6;
const int eth_tag_len = 2;
const int crc_len = 4;
const int mac_dest_off = 0;
const int mac_src_off = 6;
const int eth_tag_offset = 12;
const int payload_offset = 14;

int keep_looping = 1;

char interface_name[16];

const int print_payload = 0;
const int sec_mod_factor = 1000;
const int nsec_div_factor = 1000*1000;     

void raw_hex_dump(int len, unsigned char* buff)
{
    int i;
    for(i = 0; i < len; ++i)
    {

        if(i % raw_hex_dump_num_bytes_per_block != 0)
        {
            printf(" %02x", buff[i]);
            continue;
        }

        if(i != 0)
        {
            printf("\n");
        }

        printf("0x%02x  |  %02x", i, buff[i]);
    }

    printf("\n");
}

void frame_pretty_print(int len, unsigned char* buff, struct timespec time_now)
{
    int i, off = mac_dest_off;
    
    printf("------------------------------------------------------------\n");

    printf("TIME   = %ld.%ld\n", time_now.tv_sec % sec_mod_factor, time_now.tv_nsec / nsec_div_factor);

    printf("PAC LEN = %d\n", len);

    printf("MAC DST = ");
    for(i = 0; i < mac_len; ++i)
    {
        printf("%02x ", buff[off + i]);
    }
    printf("\n");

    off = mac_src_off;
    printf("MAC SRC = ");
    for(i = 0; i < mac_len; ++i)
    {
        printf("%02x ", buff[off + i]);
    }
    printf("\n");

    off = eth_tag_offset;
    printf("ETH TAG = %02x %02x", buff[off], buff[off+1]);
    printf("\n");

    off = len - crc_len;
    printf("CRC     = %02x %02x %02x %02x\n", buff[off], buff[off+1], buff[off+2], buff[off+3]);

    if(print_payload)
    {
        off = payload_offset;
        printf("PAYLOAD = \n\n");
        raw_hex_dump(len - off - crc_len, buff + off);
    }
    

    printf("------------------------------------------------------------\n\n");
}

void sig_int_handler(int num)
{
    keep_looping = 0;
    printf("Killing Sniffer\n");
}

int main(int argc, char** argv)
{
    struct sigaction new_action;
    int ret, sock, i;
    struct sockaddr_ll inner_sockaddr;
    struct ifreq interface_index;
    ssize_t num_read = 0;
    unsigned char* buff = NULL;
    struct timespec time_now = {0};

    // process comannd line args. Expects ./<prog> <if_name>
    if(argc != 2)
    {
        printf("ERROR usage ./%s <if_name>\n", argv[0]);
        exit(1);
    }

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

    // Allocate packet buffer
    buff = malloc(max_ethframe_size);
    if(buff == NULL)
    {
        perror("malloc failed");
        exit(1);
    }

    // register our own signal handler for interrupt
    new_action.sa_handler = sig_int_handler;
    sigemptyset(&new_action.sa_mask);
    new_action.sa_flags = 0;

    ret = sigaction(SIGINT, &new_action, NULL);
    if(ret < 0)
    {
        perror("Failed to register new sig int handler");
        exit(1);
    }
    
    // Open raw socket
    sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if(sock < 0)
    {
        perror("Failed to create socket");
        exit(1);
    }

    // Bind to interface
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

    while(keep_looping)
    {
        num_read = recv(sock, buff, max_ethframe_size, 0);
        clock_gettime(CLOCK_REALTIME, &time_now);
        if(!keep_looping)
        {
            break;
        }

        // recv should only return this in failure as we are using a blocking
        // call to recv
        if(num_read < 0)
        {
            perror("recv failed");
            exit(1);
        }

        if(num_read == max_ethframe_size)
        {
            printf("WARNING, recv packet of max length\n");
        }

        frame_pretty_print(num_read, buff, time_now);
        
    }

    printf("Freeing Up Prog resources\n");
    close(sock);
    free(buff);
    return 0;
}