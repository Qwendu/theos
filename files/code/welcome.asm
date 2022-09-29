
syscall_write :: 0x3;
iterations :: 5;

message: "Hello world: 1"
newline: 10;

mov rax, syscall_write;
mov rbx, message.data;
mov rcx, message.count;
add rcx, 2;

mov rdi, iterations;
mov rdx, message.data + message.count - 1;

loop_start :: #code_offset;

int 0x80;
inc #memory,8 rdx;
dec rdi;
jnz loop_start;

ret;
