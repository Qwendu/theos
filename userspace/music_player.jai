
#import "Formosa";
#import "Basic";
#import "Wav_File";

main :: (filename: string) {
    file := read_file(filename);
    defer unmap_memory(file.count, file.data);

    format, samples, success, extra := get_wav_header(xx file);
    if !success {
        write_string("Failed to parse WAVE file!\n");
        return;
    }

    if format.nSamplesPerSec != 48000 || format.wBitsPerSample != 16 {
        print("Wave file must be 16bit PCM at 48khz! Was % bits at % hz", format.wBitsPerSample, format.nSamplesPerSec);
        return;
    }

    sink := acquire_system_mixer_channel();

    sink_format := get_audio_format(sink);
    source := create_audio_source(sink_format);

    connect_audio_endpoints(source, sink);
    start_audio_source(source);

    bytes_per_block := sink_format.block_size * size_of(u16);

    for 0..samples.count / bytes_per_block  - 1 {
        blocking_submit_audio_buffer(source, samples.data + it * bytes_per_block);
    }

    stop_audio_source(source);
    release_system_mixer_channel(sink);
}
