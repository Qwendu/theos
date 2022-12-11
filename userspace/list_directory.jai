
#import "Formosa";

main :: (dir_name: string) {
    entries, result := list_directory(dir_name);
    if result == .success {
        output(entries);
    } else if result == .item_is_wrong_kind {
        write_string("That is a file, not a directory!\n");
    }
}

