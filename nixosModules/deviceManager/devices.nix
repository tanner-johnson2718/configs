[
  (rec {
    name            = "prusa-plug";
    hostname        = name;
    username        = "admin";
    defaultPassword = "";
    ip	            = "192.168.0.160";
    mac             = "D8:BC:38:8B:4E:15";
    url             = "http://${ip}";
    commands        = {
      toggle = "curl -X GET http://${ip}/?m=1&o=1";
    };
  })
  (rec {
    name            = "holodeck-plug";
    hostname        = name;
    username        = "admin";
    defaultPassword = "";
    ip              = "192.168.0.243";
    mac             = "D8:BC:38:8B:4D:B7";
    url             = "http://${ip}";
    commands        = {
      toggle = "curl -X GET http://${ip}/?m=1&o=1";
    };
  })
  (rec {
    name            = "lights-garage";
    hostname        = name;
    username        = "admin";
    defaultPassword = "";
    ip              = "192.168.0.159";
    mac             = "D8:BC:38:8B:48:F2";
    url             = "http://${ip}";
    commands        = {
      toggle = "curl -X GET http://${ip}/?m=1&o=1";
    };
  })
]
