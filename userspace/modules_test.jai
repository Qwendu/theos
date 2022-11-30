
#import "Formosa";
#import "Formosa_Utilities";
#import "Window_Creation";
// #import "Input";
#import "File";
// #import "Simp";
#import "Basic";

main :: () {
    write_string("The world is yours\n");

    file, success := read_entire_file("pictures/parthenon.ppm");
    assert(success);

    write_string("Parsing\n");
    pnm := parse_pnm(xx file);

    write_string("Creating window\n");
    create_window(pnm.width, pnm.height, "window name");

    while true { yield(); }
}
