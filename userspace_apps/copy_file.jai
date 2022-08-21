
#import "Theos";

main :: (existing: string, new: string) {
    e := read_file(existing);
    create_file(new);
    write_file(new, e);
}
