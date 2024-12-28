idf_component_register(
  SRCS "HC_SR04.c"
  INCLUDE_DIRS "."
  REQUIRES esp_driver_gpio esp_timer
)
