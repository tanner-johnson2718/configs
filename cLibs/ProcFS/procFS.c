#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>

#include "procFS.h"

#define INCLUDE_TEST_DRIVER 0
#define MAX_PATH_SIZE 64
#define MAX_PROC_FS_LINE_SZIE 256

void dump_proc()
{
    DIR *d;
    struct dirent *dir;
    d = opendir("/proc");
    if(d)
    {
        while ((dir = readdir(d)) != NULL) {
            printf("%s\n", dir->d_name);
        }
        printf("\n");
        closedir(d);
    }
    else{
        printf("OPEN DIR failed\n");
    }
}

// Read procfs/pid/status. Fill string up until val_len or end of line. Return
// number of byets written.
int query_procFS(int pid, char* key, char* val, int val_len)
{
    char status_path[MAX_PATH_SIZE];
    char* line = NULL;
    size_t len = -1;
    
    sprintf(status_path, "/proc/%d/status", pid);

    FILE* fp = fopen(status_path, "r");
    if(fp == NULL)
    {
        return 0;
    }

    while((getline(&line, &len, fp)) != -1)
    {
        // printf("LINE = %s", line);
        char* ret = strstr(line, key);
        if(ret == line)
        {
            break;
        }
    }

    char* val_string = strchr(line, ':');
    val_string++;

    int n = 0;
    while(n < (val_len-1) && val_string[n] != '\n')
    {
        val[n] = val_string[n];
        ++n;
    }
    val[n] = 0;

    fclose(fp);
    if(line)
    {
        free(line);
    }

    return n;
} 

int query_procFS_int(int pid, char* key)
{
    char val[64];
    if(query_procFS(getpid(), "NStgid", val, 64))
    {
        return strtol(val, NULL, 10);
    }

    return -1;
}

#if INCLUDE_TEST_DRIVER
int main()
{
   printf("%d\n", query_procFS_int(getpid(), "NStgid"));
}
#endif