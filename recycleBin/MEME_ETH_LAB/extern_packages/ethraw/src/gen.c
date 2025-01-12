// gen.c raw ethernet packet generator. Will send packets to a hard coded MAC 
// out a hard coded interface. Will have hard coded params for setting size and
// freq of packet transmits as well as a max number of packets sent

// sniff.c has some better doc and this file is meant to be rather basic.

#include "libEth.h" 



int main(int argc, char** argv)
{
    unsigned char* packet_buffer = NULL;
    int sock = 0, ret = 0, num_sent = 0, i = 0;
    struct timespec time_sleep = {SEND_DELAY_MS / 1000, (SEND_DELAY_MS % 1000)*1000*1000};
    struct timespec time_now = {0};

    // Parsed args
    unsigned char mac_src[6];
    unsigned char mac_dst[6];
    int if_index = -1;
    int packet_size;
    unsigned char tag[2];

    // Expects input args ./<prog> <if_name> <mac_dst> <mac_src> <tag> <pack_size>
    if(argc != 6)
    {
        printf("ERROR usage ./%s <if_name>\n", argv[0]);
        exit(1);
    }

    // Open a socket
    sock = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
    if(sock < 1)
    {
        perror("Failed to create socket");
        exit(1);
    }

    // Parse if_name
    if((if_index = parse_if_index(argv[1], sock)) < 0)
    {
        printf("ERROR - if_name too long\n");
    }
    printf("Index of %s = %d\n", argv[1], if_index);

    // Parse mac_dst
    if(parse_mac(argv[2], mac_dst) < 0)
    {
        printf("ERROR -  mac_dst must be of form xx:xx:xx:xx:xx:xx\n");
        exit(1);
    }

    // Parse mac_src
    if(parse_mac(argv[3], mac_src) < 0)
    {
        printf("ERROR - mac_src must be of form xx:xx:xx:xx:xx:xx\n");
        exit(1);
    }

    // Parse Tag
    if(parse_tag(argv[4], tag) < 0)
    {
        printf("ERROR - tag must be of form 0xHHHH\n");
        exit(1);
    }

    // Parse Packet size
    if((packet_size = atoi(argv[5])) < 0)
    {
        printf("ERROR - Packet Size must be positive int\n");
        exit(1);
    }

    // Allocate Buffer and pack it
    packet_buffer = malloc(packet_size);
    if(packet_buffer == NULL)
    {
        perror("Malloc Failed to Create Packet Buffer");
        exit(1);
    }

    ret = pack_frame(packet_buffer, packet_size, mac_src, mac_dst, (unsigned char*) tag);
    if(ret < 0)
    {
        printf("Error Packet size not in [64,1518]\n");
        exit(1);
    }

    // Bind it to the specified interface
    if(libEth_bind(sock, if_index) < 0)
    {
        perror("Bind Failed");
        exit(1);
    }

    // Transmit Data
    for(i = 0 ; i < NUM_PACKETS_TO_SEND; ++i)
    {
        num_sent = send(sock, packet_buffer, packet_size, 0);
        if(num_sent < 0)
        {
            perror("Send Failed");
        }
        else
        {
            clock_gettime(CLOCK_REALTIME, &time_now);
            printf("Num Bytes Sent = %d at %ld.%ld\n", num_sent, time_now.tv_sec % SEC_MOD_FACTOR, time_now.tv_nsec / NSEC_DIV_FACTOR);
        }
        
        ret = nanosleep(&time_sleep, NULL);
        if (ret < 0)
        {
            printf("sleep interrupted\n");
        }
    }

    printf("Exiting...\n");
    free(packet_buffer);
    close(sock);
}