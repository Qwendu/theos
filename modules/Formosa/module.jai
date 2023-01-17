
// This is the formosa system API, kind of like #include "windows.h"

#scope_export

Syscall_Numbers :: enum {
    NONE                    :: 0x00;
    MAP_MEMORY              :: 0x01;
    UNMAP_MEMORY            :: 0x02;
    WRITE_STRING            :: 0x03;
    READ_FILE               :: 0x04;
    WRITE_FILE              :: 0x05;
    CREATE_FILE             :: 0x06;
    STAT_FILE               :: 0x07;
    GET_MESSAGE             :: 0x08;
    CREATE_WINDOW           :: 0x09;
    CLOSE_WINDOW            :: 0x0a;
    REPAINT                 :: 0x0b;
    GET_THEME               :: 0x0c;
    SET_THEME               :: 0x0d;
    INPUT                   :: 0x0e;
    OUTPUT                  :: 0x0f;
    READ_STRING             :: 0x10;
    LIST_DIRECTORY          :: 0x11;
    GET_TIME                :: 0x12;
    GET_SYSTEM_PARAMETERS   :: 0x13;
    WAIT_FOR_MESSAGE        :: 0x14;
    GET_DEVICE_LIST         :: 0x15;
    GET_SPACE_NEEDED_FOR_DEVICE_LIST :: 0x16;
    YIELD                   :: 0x17;
    EXIT                    :: 0x18;
    GET_WINDOW_BUFFER       :: 0x19;
    GET_MOUSE_POSITION      :: 0x1a;
    GET_WINDOW_SIZE         :: 0x1b;
    SLEEP                   :: 0x1c;
    CREATE_THREAD           :: 0x1d;
    JOIN_THREAD             :: 0x1e;

    ACQUIRE_SYSTEM_MIXER_CHANNEL :: 0x3e;
    RELEASE_SYSTEM_MIXER_CHANNEL :: 0x3f;
    CREATE_AUDIO_SOURCE     :: 0x30;
    CREATE_AUDIO_SINK       :: 0x31;
    CONNECT_AUDIO_ENDPOINTS :: 0x32;
    START_AUDIO_SOURCE      :: 0x33;
    STOP_AUDIO_SOURCE       :: 0x34;
    BLOCKING_SUBMIT_AUDIO_BUFFER :: 0x35;
}

#load "formosa.jai";
#load "audio.jai";
#load "posix.jai";
