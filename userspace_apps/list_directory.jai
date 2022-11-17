
#import "Formosa";

main :: (dir_name: string) {
    entries := list_directory(dir_name);
    output(entries);
}
