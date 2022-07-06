
#import "Theos";

main :: () {
    write_string("You are in a field.\n");

    while true {
        message := read_string("What to do?");

        if message == "go east" write_string("You go east.\n");
        else if message == "look around" write_string("You are in a field.\n");
        else if message == "quit" return;
        else write_string("You cannot do that.\n");
    }
}
