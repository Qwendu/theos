
Formosa :: #import "Formosa";
#import "Basic";

main :: () {
    for 1..50 {
        name := tprint("pictures/file_%", it);
        Formosa.create_file(name);
    }
}
