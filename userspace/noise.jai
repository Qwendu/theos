
width := 1000;
height := 1000;

#import "Formosa";

main :: () {
    window_handle := create_window(width, height);
    window := get_window_buffer(window_handle);
    defer close_window(window_handle);

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
            if message.kind == .KEYBOARD && message.keyboard.key == .ESC {
                return;
            }
        }
        // #asm { hlt; }
    }
}
