#define _GNU_SOURCE
#include <sched.h>
#include <linux/sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <signal.h>

#include "procFS.h"

///////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////
int flags = SIGCHLD | CLONE_NEWPID;
int stack_size = 1024*1024;
int _idx = 0;

///////////////////////////////////////////////////////////////////////////////
// ID Shit
///////////////////////////////////////////////////////////////////////////////

typedef struct _id_t
{
    pid_t pid;
    pid_t ppid;
    pid_t pgid;
    pid_t tid;
    pid_t sid;
    pid_t NStgid;
    pid_t NSpid;
    pid_t NSpgid;
    pid_t NSsid;
} ids_t;

void pull_ids(ids_t* ids)
{
    ids->pid = getpid();
    ids->ppid = getppid();
    ids->pgid = getpgid(0);
    ids->tid = syscall(SYS_gettid);
    ids->sid = getsid(0);
    ids->NStgid = query_procFS_int(ids->pid, "NStgid");
    ids->NSpid = query_procFS_int(ids->pid, "NSpid");
    ids->NSpgid = query_procFS_int(ids->pid, "NSpgid");
    ids->NSsid = query_procFS_int(ids->pid, "NSpgid");
}

void pull_ids_procFS(ids_t* ids, pid_t pid)
{
    ids->pid = query_procFS_int(pid, "Pid");
    ids->ppid = query_procFS_int(pid, "PPid");
    ids->pgid = -1;
    ids->tid = -1;
    ids->sid = -1;
    ids->NStgid = query_procFS_int(pid, "NStgid");
    ids->NSpid = query_procFS_int(pid, "NSpid");
    ids->NSpgid = query_procFS_int(pid, "NSpgid");
    ids->NSsid = query_procFS_int(pid, "NSpgid");
}

void print_ids(char* name)
{
    ids_t ids;
    pull_ids(&ids);
    printf("========== %s ==========\n", name);
    printf("PID     = %d\n", ids.pid);
    printf("PPID    = %d\n", ids.ppid);
    printf("PGID    = %d\n", ids.pgid);
    printf("TID     = %d\n", ids.tid);
    printf("SID     = %d\n", ids.sid);
    printf("NStgid  = %d\n", ids.NStgid);
    printf("NSpid   = %d\n", ids.NSpid);
    printf("NSpgid  = %d\n", ids.NSpgid);
    printf("NSsid   = %d\n", ids.NSsid);
}

void print_ids_procFS(char* name, pid_t pid)
{
    ids_t ids;
    pull_ids_procFS(&ids, pid);
    printf("========== %s ==========\n", name);
    printf("PID     = %d\n", ids.pid);
    printf("PPID    = %d\n", ids.ppid);
    printf("PGID    = %d\n", ids.pgid);
    printf("TID     = %d\n", ids.tid);
    printf("SID     = %d\n", ids.sid);
    printf("NStgid  = %d\n", ids.NStgid);
    printf("NSpid   = %d\n", ids.NSpid);
    printf("NSpgid  = %d\n", ids.NSpgid);
    printf("NSsid   = %d\n", ids.NSsid);
}


///////////////////////////////////////////////////////////////////////////////
// Thread Func
///////////////////////////////////////////////////////////////////////////////

int f(void* in)
{
    int idx = *((int*) in);

    sleep(1);

    int ret = system("mount -t proc proc /proc");
    if(ret < 0)
    {
        printf("Mounting new /proc failed!!");
    }

    print_ids("Child Init (Inner NS)");

    pid_t sub1_pid = fork();
    if(sub1_pid == 0)
    {
        print_ids("Sub 1 (Inner NS)");
        pid_t sub2_pid = fork();
        if(sub2_pid == 0)
        {
            // kill parent and wait
            print_ids("Sub 2 b4 murder (Inner NS)");
            kill(getppid(), 9);

            while(getppid() != 1)
            {
                sleep(1);
            }

            print_ids("Sub 2 after murder (Inner NS)");
            exit(0);
        }   

        waitpid(sub2_pid, NULL, 0);
        exit(0);
    }

    if(waitpid(sub1_pid, NULL, 0) < 0)
    {
        printf("Waitpid FAILED\n");
    }
    printf("Sub 1 Died\n");
    if(waitpid(-1, NULL, 0) < 0)
    {
        printf("Waitpid FAILED\n");
    }
    printf("sub2 died\n");

    
    
    printf("Child Init Exiting\n");
}

///////////////////////////////////////////////////////////////////////////////
// Parent
///////////////////////////////////////////////////////////////////////////////

int main()
{

    print_ids("Parent (Outer NS)");

    void* child_stack = malloc(stack_size);
    int child_tid = clone(&f, child_stack + stack_size, flags ,&_idx);
    if(child_tid < 0)
    {
        printf("CLONE FAILED\n");
        return 1;
    }

    print_ids_procFS("Init (Outer NS)", child_tid);
    kill(child_tid, SIGCONT);

    waitpid(child_tid, NULL, 0);
    free(child_stack);
    printf("Parent Exiting\n");

    // Remount OG PS namesapce
    int ret = system("mount -t proc proc /proc");
    if(ret < 0)
    {
        printf("Mounting new /proc failed!!");
    }


    return 0;
}