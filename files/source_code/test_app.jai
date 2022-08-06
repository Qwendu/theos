
#import "Theos";

Person :: struct {
    Name: string;
    Age: int;

    Sex: enum {
        MALE; FEMALE;
    }

    Something: struct {
        a := 10;
        b := "lol";
    }
}

main :: () {
    people: [] Person = .[
        Person.{ "Maurice",   43, .MALE,   .{} },
        Person.{ "Jon",       20, .MALE,   .{} },
        Person.{ "Anastasia", 75, .FEMALE, .{} },
        Person.{ "Clarence",  25, .MALE,   .{} },
    ];

    output(people);
}
