
#import "Theos";
#import "Basic";

main :: (milliseconds: int) {
    start := << cast(*Apollo_Time) *theos_get_time();
    while true {
        current := << cast(*Apollo_Time) *theos_get_time();
        if to_milliseconds(current - start) > milliseconds break;
    }
}
