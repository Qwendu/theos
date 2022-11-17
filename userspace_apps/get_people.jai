
#import "Formosa";

Person :: struct {
    Name: string;
    Age: int;

    Sex: enum {
        MALE; FEMALE;
    }
}

main :: () {
    people: [] Person = .[
        Person.{ "Maurice", 43, .MALE },
        Person.{ "Jon", 20, .MALE },
        Person.{ "Anastasia", 75, .FEMALE },
        Person.{ "Ivy", 5, .FEMALE },
        Person.{ "Tiberius", 95, .MALE },
        Person.{ "Hua", 26, .MALE },
    ];

    output(people);
}
