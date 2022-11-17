
#import "Formosa";
#import "Formosa_Utilities";

#import "Basic";
#import "Machine_X64";
Compiler :: #import "Compiler";

main :: () {
    builder: String_Builder;

    attr: [..] Rich_Text.Attribute;
    array_reserve(*attr, 300);

    theme := get_theme();

    // add_text("\n%\n\n", TITLE, color = theme.primary);
    add_text("Formosa v0.0.0", color = theme.highlight);
    add_text(" - Hello, sailor\n\n");

    time := formosa_get_time();
    calendar := formosa_apollo_to_calendar(<< cast(*Apollo_Time) *time);
    add_text("The time is %.\n", calendar_to_string(calendar));

    add_text("There are % files in the root directory.\n\n", list_directory("").count);

    cpu := get_cpu_info();

    ti := type_info(x86_Feature_Flag);
    add_text("Supported CPU features: -------------------------------------------");
    flags_on_this_line: int;
    for 0..ti.names.count-1 {
        if check_feature(cpu.feature_leaves, xx ti.values[it]) {
            name := ti.names[it];
            if name.count >= 8 continue;

            if (flags_on_this_line % 7) == 0 add_text("\n");

            add_text("| ");
            add_text(name, color = theme.highlight);
            for 1..8 - name.count  add_text(" ");
            flags_on_this_line += 1;
        }
    }
    add_text("\n-------------------------------------------------------------------\n");

    add_text("Compiled using ", color = theme.primary);
    add_text("Jai %", #run Compiler.compiler_get_version_info(null), color = theme.accent);
    add_text(".\n");
    // print_stack_trace();

    rich: Rich_Text;
    rich.text = builder_to_string(*builder);
    rich.attributes = attr;

    output(rich);

    add_text :: (format: string, args: .. Any, color: u32 = xx,no_check -1) #expand {
        _color := color;
        if _color == xx,no_check -1  _color = theme.foreground;

        a: Rich_Text.Attribute;
        a.start_position = builder_string_length(*builder);
        a.color = _color;

        array_add(*attr, a);
        print_to_builder(*builder, format, .. args);
    }
}


TITLE :: #string END
 /#######                                                             
| ##_____/                                                             
| ##     /######   /######  /######/####   /######   /#######  /###### 
| ##### /##__  ## /##__  ##| ##_  ##_  ## /##__  ## /##_____/ |____  ##
| ##__/| ##  \ ##| ##  \__/| ## \ ## \ ##| ##  \ ##|  ######   /#######
| ##   | ##  | ##| ##      | ## | ## | ##| ##  | ## \____  ## /##__  ##
| ##   |  ######/| ##      | ## | ## | ##|  ######/ /#######/|  #######
|__/    \______/ |__/      |__/ |__/ |__/ \______/ |_______/  \_______/
END;


formosa_apollo_to_calendar :: (apollo: Apollo_Time) -> Calendar_Time {

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
