
#import "Formosa";

main :: () {
    write_string("Episode I\n");
    #asm { int3; }

    write_string("Episode II\n");
    #asm { int3; }

    write_string("Episode III\n");
    #asm { int3; }

    write_string("Episode IV\n");
    write_string("Episode V\n");
    write_string("Episode VI\n");
}
