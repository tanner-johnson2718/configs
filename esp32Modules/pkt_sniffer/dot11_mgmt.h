#pragma once
#include  <stdint.h>
#include "dot11.h"

//*****************************************************************************
// MGMT Frame Header |
//--------------------
//
// 802.11 frames are broken into 4 main types defined by bits 2-3 of the first
// byte the packet. One of which that is of particular interest is management
// frames. Their header looks like
//
// |--------------------------------------------------------------------------|
// | FCS | Duration | DA | SA | AA | Seq |       Fixed / Tagged Params        |
// |  2  |    2     | 6  | 6  | 6  |  2  |           0-2312                   |
// |--------------------------------------------------------------------------|
//
// FCS      - Frame control sequence contains meta data on the packets
//          - Byte 0 has type and subtype info
//          - Byte 1 has flags   
// Duration - Has to do with access to the wireless media
// DA       - Destination MAC addr
// SA       - Source Mac Addr
// AA       - AP Mac addr
// Seq      - Sequence number
//
// Fixed Params - These are fields of fixed length that appear in every packet
// of the same subtube. Thus parsing these is depedant on the subtype of the
// packet
//
// Tagged Params - Start immediatly after the fixed params and have a two byte
// header of the form id, length
//*****************************************************************************

typedef struct
{
    dot11_header_t mgmt_header;
    uint8_t payload[];
} mgmt_generic_t;

//*****************************************************************************
// Fixed Parameter BitMaps and TypeDefs
//*****************************************************************************
typedef struct
{
    uint8_t ess_capabilities : 1;
    uint8_t ibss_status      : 1;
    uint8_t cfp              : 2;
    uint8_t privacy          : 1;
    uint8_t short_preable    : 1;
    uint8_t pbcc             : 1;
    uint8_t channel_agility  : 1;
    uint8_t : 0;

    uint8_t reserved0        : 2;
    uint8_t short_slot_time  : 1;
    uint8_t reserved1        : 2;
    uint8_t dsss_odfm        : 1;
    uint8_t reserved2        : 2;
} fixed_param_capability_t;

typedef uint16_t   fixed_param_listen_interval_t;
typedef uint64_t   fixed_param_timestamp_t;
typedef uint16_t   fixed_param_beacon_interval_t;
typedef uint16_t   fixed_param_aid_t;
typedef uint16_t   fixed_param_status_code_t;
typedef uint16_t   fixed_param_reason_code_t;
typedef uint16_t   fixed_param_auth_algo_t;
typedef uint16_t   fixed_param_auth_trans_seq_t;
typedef struct {uint8_t mac[6];} fixed_param_current_mac_t;

//*****************************************************************************
// Tagged Param ID defs
//*****************************************************************************
#define TAGGED_PARAM_SSID 0
#define TAGGED_PARAM_SUPPORTED_RATES 1
#define TAGGED_PARAM_FH_PARAM 2
#define TAGGED_PARAM_DS_PARAM 3
#define TAGGED_PARAM_CF_PARAM 4
#define TAGGED_PARAM_IBSS 6
#define TAGGED_PARAM_COUNTRY                7
#define TAGGED_PARAM_HOPPING_PATTERN_PARAMS 8
#define TAGGED_PARAM_HOPPING_PATTERN_TABLE  9
#define TAGGED_PARAM_POWER_CONSTANT        32
#define TAGGED_PARAM_POWER_CAPABILITIES    33
#define TAGGED_PARAM_TPC_REQ               34
#define TAGGED_PARAM_TPC_REPORT            35
#define TAGGED_PARAM_SUPPORTED_CHANNNELS   36
#define TAGGED_PARAM_CHANNEL_SWITCH        37
#define TAGGED_PARAM_QUIET                 40
#define TAGGED_PARAM_IBSS_DFS              41
#define TAGGED_PARAM_ERP                   42
#define TAGGED_PARAM_HT_CAPABILITES        45
#define TAGGED_PARAM_RSN                   48
#define TAGGED_PARAM_EXTENDED_SUPPORTED_RATES 50
#define TAGGED_PARAM_EXTENDED_CAPABILITES 127

typedef struct
{
    uint8_t pre_auth_capable:1;
    uint8_t no_pairwise_capabilities:1;
    uint8_t ptksa_replay_couter_cap:2;
    uint8_t gtksa_replay_counter_cap:2;
    uint8_t mgmt_frame_protect_req:1;
    uint8_t mgmt_frame_protect_cap:1;
    uint8_t :0;

    uint8_t joint_multiband_rsna:1;
    uint8_t peerkey_enabled:1;
    uint8_t res:3;
    uint8_t extended_keyID:1;
    uint8_t res0:2;
    uint8_t :0;
} rsn_cap_t;

//*****************************************************************************
// Assoc Request - This is part of the association process for an STA  
// connecting to an AP. It is a mgmt frame of subtype 0 and It has the 
// follwing fixed fields.
//
// |------------------------------|
// | Capability | Listen Interval |
// |      2     |       2         |
// |------------------------------|
//
// Some tagged parameteres that usually apart of a assoc request are)
//   - SSID            id=0
//   - Supported Rates id=1
//   - RSN             id=48
//*****************************************************************************
typedef struct
{
    dot11_header_t                     mgmt_header;
    fixed_param_capability_t         capabilities;
    fixed_param_listen_interval_t listen_interval;
    uint8_t                       tagged_params[];
} assoc_req_t;

//*****************************************************************************
// Assoc Response - This is a mgmt frame that is sent as a response to a assoc
// request. It has the following fixed params and has a subtybe of 1.
//
// Reassoc Response - Same for an reassoc req.
//
// |-----------------------------------|
// | Cability Info | Status Code | AID |
// |       2       |        2    |  2  |
// |-----------------------------------|
//
// Some tagged params that are usually apart of an assoc response)
//    - Suported Rates id=1
//*****************************************************************************
typedef struct
{
    dot11_header_t              mgmt_header;
    fixed_param_capability_t  capabilities;
    fixed_param_status_code_t  status_code;
    fixed_param_aid_t                  aid;
    uint8_t                tagged_params[];
} assoc_res_t;

typedef assoc_res_t reassoc_re_t;

//*****************************************************************************
// Probe Request - Sent by a STA to an AP requesting a probe response which
// contains info on the AP. This is used when scanning available APs. This is
// a management frame of subtype 4. It has no fixed parameters but must
// contained the following tagged parameteres:
//    - SSID
//    - Supported Rates
//    - Extended Supported Rates
//*****************************************************************************

typedef struct
{
    dot11_header_t mgmt_header;
    uint8_t tagged_params[];
} probe_req_t;

//*****************************************************************************
// Probe Response - Sent by an AP and contains info about the AP. Its is of 
// subtype 5 and contains the following fixed fields)
//
// Beacons - These are sent at regular intervals by the AP to announce its
// presensce. They have same fixed parameters and are of subtype 8.
//
// |---------------------------------------------|
// | Time Stamp | Beacon Interval | Capabilities |
// |     8      |        2        |      2       |
// |---------------------------------------------|
//
// It also contains the following tagged params
//    - SSID
//    - Supported Rates
//    - FH Parameter set
//    - DS Param set
//    - CF param set
//    - IBSS param set
//    - Country info
//    - FH Hopping Param
//    - FH Pattern Table
//    - Power Constant
//    - Channel Switch Announcment
//    - Quiet
//    - IBSS DFS
//    - TPC Report
//    - ERP Info
//    - Exteneded support rates
//    - RSN
//*****************************************************************************
typedef struct
{
    dot11_header_t                     mgmt_header;
    fixed_param_timestamp_t             timestamp;
    fixed_param_beacon_interval_t beacon_interval;
    fixed_param_capability_t         capabilities;
    uint8_t                       tagged_params[];
} probe_res_t;

typedef probe_res_t beacon_t;

//*****************************************************************************
// ATIM frame - This is used in an IBSS network where traffic is sent p2p and
// not through an AP. This packet notifies the recipent that the sender has
// buffered data for it. It is just mgmt header with no body.
//*****************************************************************************
typedef dot11_header_t atim_t;

//*****************************************************************************
// Deauth and Disassoc - these frames are send to end either an association or
// an authentication between and AP and an STA. It contains a single fixed 
// param given the reason code.
//*****************************************************************************
typedef struct
{
    dot11_header_t mgmt_header;
    fixed_param_reason_code_t reason_code;
} disassoc_t;

typedef disassoc_t deauth_t;

//*****************************************************************************
// Reassocation Request - when moving in out of a service set on may need to 
// reassociate if one is already authenticated. This packet is of subtype 2 and
// has the following fixed fields.
//
// |--------------------------------------------------------|
// | Capability info | Listen Interval | Current AP Address |
// |--------------------------------------------------------|
//
// It also contains some of the following tagged fields)
//   - SSID
//   - Supported Rates
//*****************************************************************************
typedef struct
{
    dot11_header_t mgmt_header;
    fixed_param_capability_t capabilities;
    fixed_param_listen_interval_t listen_interval;
    fixed_param_current_mac_t current_ap_mac;
    uint8_t tagged_params[];
} reassoc_req_t;

//*****************************************************************************
// Authentication - This is the first set of packets exchanged when a STA is 
// joining an AP. Legacy networks had the shared password exchnaged here, but
// newer protocols have much stronger security and add psk key exchange till
// later in the process. This packet is of subtype 11 and has the following
// fixed fields.
//
// |------------------------------------|
// | auth algo | Auth Seq | Status Code |
// |------------------------------------|
//
// It should also include a supported rates tagged param
//*****************************************************************************
typedef struct
{
    dot11_header_t mgmt_header;
    fixed_param_auth_algo_t auth_algo;
    fixed_param_auth_trans_seq_t auth_seq;
    fixed_param_status_code_t status_code;
    uint8_t tagged_params[];
} auth_t;