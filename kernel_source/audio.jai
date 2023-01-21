
AUDIO_BLOCKSIZE :: 8192; // 512 samples, 256 stereo frames, 1024 bytes
milliseconds_per_block :: AUDIO_BLOCKSIZE / 48;

audio_source_pool: Pool(Audio_Source, 1024);
audio_sink_pool: Pool(Audio_Sink, 1024);

Audio_Source :: struct {
    sink_id: s64 = -1;
    buffer: *u16;
    buffer_consumed: bool;
}

Audio_Sink :: struct {
    source_id: s64 = -1;
    buffer: *u16;
    buffer_consumed: bool;
}

init_audio :: () {
    pool_init(*audio_sink_pool);
    pool_init(*audio_source_pool);

    id: s64;
    id, system_mixer.source = pool_add(*audio_source_pool, .{});

    system_mixer.source.sink_id = ac97.sink_id;
    system_mixer.source.buffer = map_memory(AUDIO_BLOCKSIZE * size_of(u16));
    array_add(*running_sources, system_mixer.source);

    task := make_task(update_audio);
    task.process.name = "audio mixer";
}

system_mixer: struct {
    source: *Audio_Source;
    channels: [..] *Audio_Sink;
};

make_mixer_channel :: () -> s64 {
    sink_id, sink := pool_add(*audio_sink_pool, .{});
    sink.buffer = map_memory(AUDIO_BLOCKSIZE * size_of(u16));
    array_add(*system_mixer.channels, sink);

    return sink_id;
}

running_sources: [..] *Audio_Source;

update_audio :: (user: *void) {
    while true {
        for running_sources {
            if it.buffer_consumed continue;
            sink, occupied := pool_get(*audio_sink_pool, it.sink_id);
            if !occupied continue;
            if !sink.buffer_consumed continue;

            memcpy(sink.buffer, it.buffer, AUDIO_BLOCKSIZE * size_of(u16));

            it.buffer_consumed = true;
            sink.buffer_consumed = false;
        }

        if system_mixer.source.buffer_consumed {
            memset(system_mixer.source.buffer, 0, AUDIO_BLOCKSIZE * size_of(u16));
            for channel: system_mixer.channels {
                for 0..AUDIO_BLOCKSIZE - 1 {
                    system_mixer.source.buffer[it] += cast(u16) (cast(s16) channel.buffer[it]);
                }

                channel.buffer_consumed = true;
            }

            system_mixer.source.buffer_consumed = false;
        }

        kernel_sleep_milliseconds(3);
    }
}





POOL_FREELIST_NONE : s64 : -1;
Pool :: struct(T: Type, capacity: s64, debug := false) {
    Element_Type :: union {
        using #as element: T;
        link: s64;
    };

    data: [] Element_Type;
    occupancy: [] bool;
    used: s64;
    freelist: s64;
}

pool_init :: (using pool: *Pool) {
    freelist  = POOL_FREELIST_NONE;
    data      = NewArray(capacity, Element_Type);
    occupancy = NewArray(capacity, bool);
}

pool_add :: (using pool: *Pool($T, $capacity), element: T) -> (s64, *T) {
    index: s64;
    if freelist == POOL_FREELIST_NONE {
        if used >= capacity {
            return -1, null;
        }
        index = used;
        used += 1;
    } else {
        index = freelist;
        freelist = data[freelist].link;
    }
    data[index].element = element;

    assert(!occupancy[index]);
    occupancy[index] = true;

    return index, *data[index];
}

pool_remove :: (using pool: *Pool($T, $capacity), index: s64) {
    assert(used > 0);
    assert(index < used && index >= 0);

    assert(occupancy[index]);
    occupancy[index] = false;

    data[index].link = freelist;
    freelist = index;
}

pool_get :: (using pool: *Pool($T, $capacity), index: s64) -> *T, bool {
    return *data[index].element, occupancy[index];
}
