
Audio_Sink           :: #type,distinct s64;
Audio_Source         :: #type,distinct s64;


get_audio_format :: (channel: Audio_Sink) -> Audio_Stream_Format {
    return .{
        block_size = 8192,
        pcm = .{
            channels = 2,
            depth = 16,
            sample_rate = 48_000,
        }
    };
}

acquire_system_mixer_channel :: () -> Audio_Sink {
    handle: Audio_Sink;
    p_handle := *handle;

    #asm {
        mov rbx: gpr === b, p_handle;
        mov rax: gpr === a, ACQUIRE_SYSTEM_MIXER_CHANNEL;
        int 0x80;
    }

    return handle;
}

release_system_mixer_channel :: (handle: Audio_Sink) {
    #asm {
        mov rbx: gpr === b, handle;
        mov rax: gpr === a, RELEASE_SYSTEM_MIXER_CHANNEL;
        int 0x80;
    }
}

create_audio_source :: (format: Audio_Stream_Format) -> Audio_Source {
    handle: Audio_Source;
    p_handle := *handle;

    #asm {
        mov rbx: gpr === b, p_handle;
        mov rax: gpr === a, CREATE_AUDIO_SOURCE;
        int 0x80;
    }

    return handle;
}

connect_audio_endpoints :: (source: Audio_Source, sink: Audio_Sink) {
    #asm {
        mov rbx: gpr === b, source;
        mov rcx: gpr === c, sink;
        mov rax: gpr === a, CONNECT_AUDIO_ENDPOINTS;
        int 0x80;
    }
}

start_audio_source :: (source: Audio_Source) {
    #asm {
        mov rbx: gpr === b, source;
        mov rax: gpr === a, START_AUDIO_SOURCE;
        int 0x80;
    }
}

stop_audio_source :: (source: Audio_Source) {
    #asm {
        mov rbx: gpr === b, source;
        mov rax: gpr === a, STOP_AUDIO_SOURCE;
        int 0x80;
    }
}

blocking_submit_audio_buffer :: (source: Audio_Source, buffer: *void) {
    #asm {
        mov rbx: gpr === b, source;
        mov rcx: gpr === c, buffer;
        mov rax: gpr === a, BLOCKING_SUBMIT_AUDIO_BUFFER;
        int 0x80;
    }
}



Audio_Stream_Format :: struct {
    using pcm: Audio_Pcm_Format;
    block_size: int;
}

Audio_Pcm_Format :: struct {
    channels: int;
    depth: int;
    sample_rate: int;
}

/*

Audio_Sink_Info :: struct {
    name: string;
    available: bool;

    type: enum {
        invalid;
        system_mixer_channel;
        hardware_device;
        user_application;
    }
}

*/

#scope_file
using Syscall_Numbers;
