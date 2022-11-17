
#import "Formosa";
#import "Basic";

main :: () {
    context.print_style.default_format_int.base = 16;

    while true {
        msg := wait_for_message();
        if msg.kind != .KEYBOARD continue;

        if msg.key == .ESC return;

        write_string(tprint("Pressed key: %\n", cast(u16) msg.key));
    }
}
