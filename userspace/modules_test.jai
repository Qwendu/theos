
/*

#import "Formosa";
#import "Formosa_Utilities";
#import "Window_Creation";
#import "Input";
#import "File";
#import "Simp";
#import "Basic";

main :: () {
    write_string("The world is yours\n");

    file, success := read_entire_file("pictures/parthenon.ppm");
    assert(success);

    write_string("Parsing\n");
    pnm := parse_pnm(xx file);

    write_string("Creating window\n");
    w := create_window(pnm.width, pnm.height, "window name");

    x, y := get_window_size(w);
    write_string(tprint("% %\n", x, y));
    repaint();
    while true { yield(); }
}

*/

main :: () {
    a := 0;
    b := 1 / a;
}
