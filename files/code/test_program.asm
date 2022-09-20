
syscall_write :: 0x3;
message :: "Hello, world! This is a fun message.";

MOV rax, syscall_write;
MOV rbx, message.data;
MOV rcx, message.count;
INT 0x80;
RET;
