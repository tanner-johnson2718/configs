#ifndef __MEME_PROCFS__
#define __MEME_PROCFS__

int query_procFS_int(int pid, char* key);
void dump_proc();

#endif