
#scope_module

DEFAULT_WINDOW_CREATION_COLOR :: float.[.15,.15,.2];

#scope_export

WT :: #import "Window_Type";  // Define this for the people.
Window_Type :: WT.Window_Type;



create_window :: (width: int, height: int, window_name: string, window_x := -1, window_y := -1, parent: HWND = null, background_color_rgb := DEFAULT_WINDOW_CREATION_COLOR) -> Window_Handle {
    handle := create_window(width, height);
    buffer := get_window_buffer(handle);

    pixels := width * height;

    c := background_color_rgb;
    color: u32 = (cast(u8) (c[0] * 255) << 16)
               | (cast(u8) (c[1] * 255) << 8)
               | (cast(u8) (c[0] * 255));

    for 0..pixels-1 {
        buffer[it] = color;
    }

    return handle;
}

// When toggling fullscreen and back, we want to remember
// the size of our old window... so we use Saved_Window_Info.
Saved_Window_Info :: struct {
    rect: RECT;
    style: s32;
    ex_style: s32;
}

toggle_fullscreen :: (hwnd: Window_Handle, desire_fullscreen: bool, saved: *Saved_Window_Info) -> (succcess: bool, width: s32, height: s32) {
    return false, 0, 0;
}



get_mouse_pointer_position :: inline (right_handed := false) -> x: int, y: int, success: bool {
    return 0, 0, false;
}

get_mouse_pointer_position :: (hwnd: Window_Handle, right_handed: bool) -> (x: int, y: int, success: bool) {
    return 0, 0, false;
}

get_dimensions :: (hwnd: Window_Handle, right_handed: bool) -> (x: s32, y: s32, width: s32, height: s32, success := true) {
    return 0, 0, 0, 0, false;
}



#scope_module

#import "Theos";
