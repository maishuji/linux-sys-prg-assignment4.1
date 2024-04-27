#include <syslog.h>
#include <stdio.h>
#include <stdlib.h>

#define NUM_EXPECTED_ARGS 2

void write(const char* filename, const char* content);

int main(int argc, char *argv[]){

    openlog(argv[0], LOG_CONS, LOG_USER);

    if(argc != (NUM_EXPECTED_ARGS + 1) ) {
        syslog(LOG_ERR, "Wrong number of arguments provided. Expected : %d, actual : %d", NUM_EXPECTED_ARGS, argc);
    }

    char* write_file = argv[1];
    char* write_str = argv[2];
    write(write_file, write_str);

    closelog();
    return 0;
}

void write(const char* filename, const char* content){

    syslog(LOG_DEBUG, "Writing %s to %s.", content, filename);
    FILE *file = fopen(filename, "w");
    if(file != NULL) {
        fprintf(file, "%s\n", content);
        syslog(LOG_DEBUG, "Writing successful.");
    }else{
        syslog(LOG_ERR, "Failed to write file");
        exit(1);
    }
    fclose(file);
}