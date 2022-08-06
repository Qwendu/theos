
#import "Theos";
#import "Basic";

main :: () {
    time := theos_get_time();
    calendar := theos_apollo_to_calendar(<< cast(*Apollo_Time) *time);
    output(tprint("The time is %.\n", calendar_to_string(calendar)));
}


theos_apollo_to_calendar :: (apollo: Apollo_Time) -> Calendar_Time {
    APOLLO_TIME_FOR_JAN_1_1970 :: Apollo_Time.{low=0xdbd87f0edb7c8000, high=0x300};
    milliseconds := to_milliseconds(apollo - APOLLO_TIME_FOR_JAN_1_1970);

    seconds      := milliseconds / 1000;
    minutes      := seconds      / 60;
    hours        := minutes      / 60;
    total_days   := hours        / 24;

    milliseconds -= seconds      * 1000;
    seconds      -= minutes      * 60;
    minutes      -= hours        * 60;
    hours        -= total_days   * 24;

    years := total_days / 365;
    leap_year_count := leap_years_before(years + 2);

    years = (total_days - leap_year_count * 366) / 365;
    years += leap_year_count;

    days := total_days - (years - leap_year_count) * 365;
    days -= leap_year_count * 366;

    years += 1970;
    is_leap_year := (years % 4 == 0) && (!(years % 100 == 0) || (years % 400 == 0));
    if is_leap_year && days < 59 days += 1;

    ct: Calendar_Time;

    days_in_month := int.[
        31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
    ];

    month: int;
    for days_in_month {
        month += 1;

        if days >= it {
            days -= it;
        } else {
            month = xx it_index;
            break;
        }
    }

    ct.year = xx years;
    // is_leap_year := (ct.year % 4 == 0) && (!(ct.year % 100 == 0) || (ct.year % 400 == 0));
    // if is_leap_year && month < 2 month_day += 1;

    ct.day_of_week_starting_at_0 = xx ((4 + total_days) % 7);

    ct.month_starting_at_0 = xx month;
    ct.day_of_month_starting_at_0 = xx days;

    ct.hour = xx hours;
    ct.minute = xx minutes;
    ct.second = xx seconds;
    ct.millisecond = xx milliseconds;
    return ct;
}

leap_years_before :: (year: s64) -> s64 {
    floor_div :: (dividend: int, $ divisor: int) -> int {
        offset := cast(int) (dividend <= 0 && dividend % divisor);
        return dividend / divisor - offset;
    }

    result := floor_div(year, 4) - floor_div(year, 100) + floor_div(year, 400);
    return result;
}
