# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION 3.5)

file(MAKE_DIRECTORY
  "/nix/store/8kvdfpnbv55bz6s7gl3bzfqynil85pbp-esp-idf-v5.3.1/components/bootloader/subproject"
  "/var/git/env/esp32Systems/module_test_drivers/build/bootloader"
  "/var/git/env/esp32Systems/module_test_drivers/build/bootloader-prefix"
  "/var/git/env/esp32Systems/module_test_drivers/build/bootloader-prefix/tmp"
  "/var/git/env/esp32Systems/module_test_drivers/build/bootloader-prefix/src/bootloader-stamp"
  "/var/git/env/esp32Systems/module_test_drivers/build/bootloader-prefix/src"
  "/var/git/env/esp32Systems/module_test_drivers/build/bootloader-prefix/src/bootloader-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/var/git/env/esp32Systems/module_test_drivers/build/bootloader-prefix/src/bootloader-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/var/git/env/esp32Systems/module_test_drivers/build/bootloader-prefix/src/bootloader-stamp${cfgdir}") # cfgdir has leading slash
endif()
