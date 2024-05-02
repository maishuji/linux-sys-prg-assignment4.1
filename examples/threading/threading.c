#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // DONE: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    struct thread_data* thdata = (struct thread_data*)thread_param;
    usleep(thdata->wait_to_obtain_ms);

    int ret = pthread_mutex_lock(thdata->mutex);
    if(ret == 0){
        //Critical section

        usleep(thdata->wait_to_release_ms);

        //End critical section
        ret = pthread_mutex_unlock(thdata->mutex);
        if(ret != 0){
            ERROR_LOG("Failed to release mutex");
            thdata->thread_complete_success = false;
        }else{
            thdata->thread_complete_success = true; // Success
        }

    }else{
        ERROR_LOG("Failed to acquire mutex");
        thdata->thread_complete_success = false;
    }
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * DONE: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    struct thread_data *thdata = malloc(sizeof(struct thread_data));
    thdata->mutex = mutex;
    thdata->wait_to_obtain_ms = wait_to_obtain_ms;
    thdata->wait_to_release_ms = wait_to_release_ms;
    thdata->thread_complete_success = false; // true on success

    int ret = pthread_create(thread, NULL, &threadfunc, thdata);
    return ret != 0? false : true;
}

