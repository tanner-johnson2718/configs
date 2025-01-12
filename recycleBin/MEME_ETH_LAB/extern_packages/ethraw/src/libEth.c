#include "libEth.h"

int parse_if_index(char* if_str, int sock)
{
    struct ifreq interface_index = {0};
    int ret = 0;
    
    if(strlen(if_str) > 15)
    {
        return -1;
    }

    strncpy((char*) &interface_index.ifr_name, if_str, strlen(if_str));
    ret = ioctl(sock, SIOCGIFINDEX, &interface_index);
    if(ret < 0)
    {
        return -1;
    }

    return interface_index.ifr_ifindex;
}

int parse_mac(char* str, unsigned char* mac)
{
    if(strlen(str) != 17)
    {
        return -1;
    }
    int ret = sscanf(str, "%hhx:%hhx:%hhx:%hhx:%hhx:%hhx", mac, 
                                                       mac + 1, 
                                                       mac + 2, 
                                                       mac + 3, 
                                                       mac + 4, 
                                                       mac + 5);

    if(ret != 6)
    {
        return -1;
    }

    return 0;
}

int parse_tag(char* str, unsigned char* tag)
{
    if(strlen(str) != 6)
    {
        return -1;
    }

    int ret = sscanf(str, "0x%02hhx%02hhx", tag, tag + 1);
    if(ret != 2)
    {
        return -1;
    }

    return 0;
}

int pack_frame(unsigned char* packet_buffer, int len, unsigned char* mac_src, 
                                               unsigned char* mac_dst,
                                               unsigned char* tag)
{
    int i;
    if(len < 64 || len > 1518)
    {
        return -1;
    }

    // Populate packet with payload byte
    for(i = 0; i < len; ++i)
    {
        packet_buffer[i] = PAYLOAD_BYTE;
    }

    // Fill in eth headers
    for(i = 0; i < 6; ++i)
    {
        packet_buffer[i] = mac_dst[i];
        packet_buffer[i+6] = mac_src[i];
    }
    packet_buffer[12] = tag[0];
    packet_buffer[13] = tag[1];

    return 0;
}

int libEth_bind(int sock, int if_index)
{
    int ret = 0;
    struct sockaddr_ll inner_sockaddr = {0};
    
    inner_sockaddr.sll_family = AF_PACKET;
    inner_sockaddr.sll_protocol = htons(ETH_P_ALL);
    inner_sockaddr.sll_ifindex = if_index;

    ret = bind(sock, (struct sockaddr*) &inner_sockaddr, sizeof(struct sockaddr_ll));
    if(ret < 0)
    {
        return -1;
    }

    return 0;
}

void raw_hex_dump(int len, unsigned char* buff)
{
    int i;
    for(i = 0; i < len; ++i)
    {

        if(i % 8 != 0)
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