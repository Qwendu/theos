
#import "Formosa";
#import "Basic";

main :: () {
    buffer := map_memory(0x123);
    write_string(tprint("%\n", buffer));

    thing: struct {
        x := 10;
        test := "Hi.";
    };

    output(thing);
}
