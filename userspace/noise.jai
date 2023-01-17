
width := 1000;
height := 1000;

#import "Formosa";

run: bool;

main :: () {
    window_handle := create_window(width, height);
    window := get_window_buffer(window_handle);
    defer close_window(window_handle);

    run = true;
    audio_thread := create_thread(do_audio);

    state: u32 = 2463534242;
    while true {
        for y: 0..height - 1 for x: 0..width - 1 {
            state ^= state << 13;
            state ^= state >> 17;
            state ^= state << 5;
            window[x + y * width] = state;
        }

        repaint();

        while true {
            message := get_message();
            if message.kind == .NONE break;
            if message.kind == .KEYBOARD && message.keyboard.key == .ESCAPE {
                run = false;
                join_thread(audio_thread);
                return;
            }
        }
        // #asm { hlt; }
    }
}

do_audio :: (user: *void) {
    sink := acquire_system_mixer_channel();
    defer release_system_mixer_channel(sink);

    format := get_audio_format(sink);
    source := create_audio_source(format);

    connect_audio_endpoints(source, sink);
    start_audio_source(source);

    samples: *u16 = map_memory(format.block_size * size_of(u16));

    state: u32 = 2463534242;

    while run {
        for 0..format.block_size - 1 {
            state ^= state << 13;
            state ^= state >> 17;
            state ^= state << 5;

            samples[it] = cast(u16) (cast(s16) state / 32);
        }

        blocking_submit_audio_buffer(source, samples);
    }

    stop_audio_source(source);
}
