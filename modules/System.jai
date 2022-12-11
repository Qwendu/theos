
get_passwd_for_user :: (username := "") -> bool, string {
    return true, "";
}

get_username :: () -> string, bool {
    return "Enlightened formosa user", true;
}

get_home_directory :: (useranem := "") -> string, bool {
    return "", true;
}

get_machinename :: () -> string {
    return "<formosa host machine name>";
}

get_path_of_running_executable :: () -> string {
    return "";
}

get_number_of_processors :: ($type: enum { ALL_PHYSICAL; ALL_LOGICAL; PERFORMANCE_PHYSICAL; PERFORMANCE_LOGICAL; } = .PERFORMANCE_LOGICAL) -> s32 {
    return 1;
}
