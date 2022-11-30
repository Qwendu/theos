
#scope_module

DEFAULT_WINDOW_CREATION_COLOR :: float.[.15,.15,.2];

#scope_export

WT :: #import "Window_Type";
Window_Type :: WT.Window_Type;



create_window :: (width: int, height: int, window_name: string, window_x := -1, window_y := -1, parent: Window_Type = WT.INVALID_WINDOW, background_color_rgb := DEFAULT_WINDOW_CREATION_COLOR) -> Window_Handle {
    handle := create_window(width, height);
    buffer := get_window_buffer(handle);

    pixels := width * height;

    c := background_color_rgb;
    color: u32 = (cast(u32) (c[0] * 255)) << 16
               | (cast(u32) (c[1] * 255)) << 8
               | (cast(u32) (c[2] * 255));

    for 0..pixels-1 {
        buffer[it] = color;
    }

    return handle;
}



Saved_Window_Info :: struct { }

toggle_fullscreen :: (w: Window_Handle, desire_fullscreen: bool, saved: *Saved_Window_Info) -> (succcess: bool, width: s32, height: s32) {
    return false, 0, 0;
}



get_mouse_pointer_position :: inline (right_handed := false) -> x: int, y: int, success: bool {
    x, y := get_mouse_position();
    return x, y, true;
}

get_mouse_pointer_position :: (w: Window_Handle, right_handed: bool) -> (x: int, y: int, success: bool) {
    x, y := get_mouse_position(w);
    return x, y, true;
}

get_dimensions :: (w: Window_Handle, right_handed: bool) -> (x: s32, y: s32, width: s32, height: s32, success := true) {
    return 0, 0, 0, 0, false;
}



#scope_module

#import "Formosa";
