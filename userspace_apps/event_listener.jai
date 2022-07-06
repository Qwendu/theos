
Theos :: #import "Theos";
#import "Basic";

main :: () {
    while true {
        message := Theos.get_message();
        if message.kind == .NONE {
            Theos.repaint();
            continue;
        }

        context.print_style.default_format_struct.use_long_form_if_more_than_this_many_members = 0;
        notif := tprint("Received message of type %, ", message.kind);
        Theos.write_string(notif);

        if message.kind == .KEYBOARD {
            Theos.write_string(tprint("key: %.\n", message.keyboard_scan_code));
        }

        if message.kind == .MOUSE {
            Theos.write_string(tprint("mouse: %.\n", message.mouse_event));
        }
    }
}
