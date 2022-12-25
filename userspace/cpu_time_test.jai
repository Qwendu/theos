
#import "Basic";
#import "Formosa";

main :: () {
    while true {
        msg := get_message();
        while msg.kind != .NONE {
            if msg.kind == .KEYBOARD && msg.keyboard.key == .ESCAPE  return;
            msg = get_message();
        }

        wait_start := << cast(*Apollo_Time) *formosa_get_time();
        while true {
            now := << cast(*Apollo_Time) *formosa_get_time();
            if now >= wait_start + milliseconds_to_apollo(5) break;
        }

        sleep(<< cast(*Apollo) *milliseconds_to_apollo(5));
    }
}
