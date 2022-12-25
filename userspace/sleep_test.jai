
#import "Basic";
#import "Formosa";
#import "Random";

main :: () {
    while true {
        msg := get_message();
        while msg.kind != .NONE {
            if msg.kind == .KEYBOARD && msg.keyboard.key == .ESCAPE  return;
            msg = get_message();
        }

        ms := random_get() % 5000;
        write_string(tprint("Sleeping for % milliseconds\n", ms));
        repaint();

        time := << cast(*Apollo) *milliseconds_to_apollo(cast(s64) ms);
        sleep(time);
    }
}
