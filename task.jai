
Task_Info :: struct {
    rsp: u64;
    next: *Task_Info;
}

current_task: *Task_Info;
first_task: *Task_Info;

initialize_task_manager :: () {
    task := cast(*Task_Info) map_memory(size_of(Task_Info));

    task_switch :: () #c_call #foreign Interrupts;
    idt_add_handler(xx task_switch, 0x50);
    task.next = task;
    current_task = task;
}

switch_to_task :: (new: *Task_Info) {
    current := *current_task;
    #asm {
        rax: gpr === a;
        rbx: gpr === b;
        mov rax, current;
        mov rbx, new;
        int 0x40;
    }
}

work :: () {
    while true {
        print("Doing work.\n");
        yield();
    }
}

make_task :: (name: string, entry_point: ()) -> *Task_Info {
    task := cast(*Task_Info) map_memory(size_of(Task_Info));

    kernel_stack := map_memory(0x1000);
    stack := cast(*Interrupt_Data) (kernel_stack + 0x1000) - 1;

    stack.rbp = xx kernel_stack;
    stack.ip  = cast(u64) cast(*void) entry_point;
    stack.flags  = 0x200;

    task.rsp = xx stack;
    task.next = current_task.next;
    current_task.next = task;

    return task;
}

yield :: () {
    switch_to_task(current_task.next);
}

exit :: () {

}
