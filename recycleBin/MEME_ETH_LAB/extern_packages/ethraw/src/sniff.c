// Some C socket code that messes with raw sockets. For now this program is a
// poor mans wire shark and just dumps all frames seen on all interfaces. There
// is an optional hardcoded param that allows one to specify a specific
// interface for which to only display traffic from. 

// |---------------------------------------------------------------------------
// | Key Sys Calls
// | ---------------------------------------------------------------------------
// | 
// | socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
// | recv();
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

#include "libEth.h"

int keep_looping = 1;

void frame_pretty_print(int len, unsigned char* buff, struct timespec time_now)
{
    int i, off = MAC_DST_OFF;
    
    printf("------------------------------------------------------------\n");

    printf("TIME   = %ld.%ld\n", time_now.tv_sec % SEC_MOD_FACTOR, time_now.tv_nsec / NSEC_DIV_FACTOR);

    printf("PAC LEN = %d\n", len);

    printf("MAC DST = ");
    for(i = 0; i < MAC_LEN; ++i)
    {
        printf("%02x ", buff[off + i]);
    }
    printf("\n");

    off = MAC_SRC_OFF;
    printf("MAC SRC = ");
    for(i = 0; i < MAC_LEN; ++i)
    {
        printf("%02x ", buff[off + i]);
    }
    printf("\n");

    off = TAG_OFF;
    printf("ETH TAG = %02x %02x", buff[off], buff[off+1]);
    printf("\n");
    

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
    int ret, sock, i, num_read = 0;
    unsigned char* buff = NULL;
    struct timespec time_now = {0};
    int if_index = -1;

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

    // Allocate packet buffer
    buff = malloc(MAX_FRAME_SIZE);
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
    if_index = parse_if_index(argv[1], sock);
    if(if_index < 0)
    {
        printf("ERROR - failed to parse interface index\n");
        exit(1);
    }
    printf("Index of %s = %d\n", argv[1], if_index);

    if(libEth_bind(sock, if_index) < 0)
    {
        printf("ERROR - failed to bind\n");
        exit(1);
    }

    while(keep_looping)
    {
        num_read = recv(sock, buff, MAX_FRAME_SIZE, 0);
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

        frame_pretty_print(num_read, buff, time_now);   
    }

    printf("Freeing Up Prog resources\n");
    close(sock);
    free(buff);
    return 0;
}