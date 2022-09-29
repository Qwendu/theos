
main :: () {
    out(0xb004, 0x2000);
    out(0x0604, 0x2000);
    out(0x4004, 0x3400);
}

out :: (port: u16, value: u16) {
    #asm {
        port  === d;
        value === a;
        out.w port, value;
    }
}
