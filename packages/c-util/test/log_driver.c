#include "log.h"
#include <stdio.h>
#include <unistd.h>

int main()
{
  LOG("TAG", "Test %d", 0);
  sleep(1);
  LOG("TAG", "Test %d", 1);
  return 0;
}
