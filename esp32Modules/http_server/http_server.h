#ifndef __HTTP_SERVER_H__
#define __HTTP_SERVER_H__

// TODO This is retarded lol need to rethink this but for now whatever
//*****************************************************************************
// Basic HTTP Server. The goal here is to have an api here I can just specify
// data and maybe call backs? Unsure for now the component will build a site
// with the following)
//   - "/" root GET will return the main webpage
//   - "/X" sub url GET will be user defined where X will call a user cb and
//     whatever is returned will be returned to via http req.
// The idea is that these "/X"'s are data we want displayed off the device or 
// hooks to actuate features on the device.
//*****************************************************************************

#include <esp_err.h>

// cb allocs, caller frees
typedef esp_err_t (*http_cb_t)(char* data);

//*****************************************************************************
// http_server_init) init the wifi system and an http server
//
// Returns) ESP_OK on success, otherwise wifi / other subsystem error
//*****************************************************************************
esp_err_t http_server_init(void);

//*****************************************************************************
// http_register_cb) Create a uri under the passed string such that when a GET
// is posted on that uri the passed cb is exedcuted.
//
// uri) String idenifiying uri
//
// cb) Callback to be exectued when uri is GET-ed
//*****************************************************************************
esp_err_t http_register_cb(char* uri, http_cb_t cb);
#endif
