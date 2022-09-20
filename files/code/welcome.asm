
syscall_write :: 0x3;
iterations :: 5;

message := "I am a fun assembly program!";
newline := 10;

mov rax, syscall_write;
mov rbx, message.data;
mov rcx, message.count;
add rcx, 1;

mov rdi, iterations;
loop_start :: #code_offset;

int 0x80;
dec rdi;
jnz loop_start;

ret;
