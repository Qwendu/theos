
#import "Basic";
#import "Formosa";

main :: () {
    params: System_Params;
    get_system_parameters(*params);
    w := create_window(params.x_resolution / 2, params.y_resolution / 2);
    defer close_window(w);

    while true {
        msg := get_message();
        if msg.kind == {
          case .MOUSE;
            write_string(tprint("x: %, y: %\n", msg.mouse.position_in_window_x, msg.mouse.position_in_window_y));

          case .KEYBOARD;
            if msg.key == .ESC break;

          case .NONE;
            repaint();
            yield();
        }
    }
}
