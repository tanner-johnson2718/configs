#ifndef __LIB_ETH_H
#define __LIB_ETH_H

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

// Packet Generator Params
#define NUM_PACKETS_TO_SEND 10
#define SEND_DELAY_MS 1000
#define PAYLOAD_BYTE 0xa5

// Eth Frame Defs
#define MAX_FRAME_SIZE 1514
#define MAC_LEN 6
#define MAC_DST_OFF 0
#define MAC_SRC_OFF 6
#define TAG_OFF 12

// Timespec display formatting params. Use sec_mod_factor and nsec_div_factor
// to shorten a timspec struct in the format <seconds>.<nano seconds>
#define SEC_MOD_FACTOR 1000
#define NSEC_DIV_FACTOR 1000*1000   

int parse_if_index(char* if_str, int sock);
int parse_mac(char* str, unsigned char* mac);
int parse_tag(char* str, unsigned char* tag);
int pack_frame(unsigned char* packet_buffer, int len, unsigned char* mac_src, 
                                                      unsigned char* mac_dst,
                                                      unsigned char* tag);
int libEth_bind(int sock, int if_index);
void raw_hex_dump(int len, unsigned char* buff);

#endif