
Task_Info :: struct {
    rsp: u64;
    next: *Task_Info;
    startup_data: *void;
    entry: (data: *void);
    the_context: *Context;
}

current_task: *Task_Info;

initialize_task_manager :: () {
    task := cast(*Task_Info) map_memory(size_of(Task_Info));

    task_switch :: () #c_call #foreign Interrupts;
    idt_add_handler(xx task_switch, 0x40);
    task.next = task;
    task.the_context = *context;
    current_task = task;
}

switch_to_task :: (new: *Task_Info) {
    current := *current_task;
    #asm {
        mov rbx: gpr === b, new;
        mov rax: gpr === a, current;
        int 0x40;
    }
}

new_task_start :: () #no_context {
    kernel_context: Context;
    kernel_context.allocator.proc = allocate_memory;
    kernel_context.logger = log;
    kernel_context.assertion_failed = assertion_failed;

    push_context kernel_context {
        current_task.the_context = *context;
        current_task.entry(current_task.startup_data);
        exit();
    }
}

make_task :: (entry_point: (data: *void), startup_data: *void = null) -> *Task_Info {
    task := cast(*Task_Info) map_memory(size_of(Task_Info));

    kernel_stack := map_memory(0x1000);
    stack := cast(*Interrupt_Stack_Frame) (kernel_stack + 0x1000) - 1;

    stack.ip = cast(u64) cast(*void) new_task_start;
    stack.flags = 0x200;

    stack.cs = 0x08;
    stack.ss = 0x10;
    stack.sp = xx kernel_stack;

    task.rsp = xx stack;
    task.next = current_task.next;
    current_task.next = task;

    task.entry = entry_point;
    task.startup_data = startup_data;

    return task;
}

yield :: () {
    switch_to_task(current_task.next);
}

exit :: () {
    task := current_task;
    while true {
        if task.next == current_task {
            task.next = task.next.next;
            break;
        }
        task = task.next;
        assert(task != current_task);
    }
    yield();
}

work :: (data: *void) {
    // message := << cast(*string) data;

    printf("[%] Doing work...", "Task 1"); paint_screen();
    sleep(ms = cast(int) rdtsc() % 100);
    print(" done.\n"); paint_screen();
    yield();

    printf("[%] Doing further work...", "Task 1"); paint_screen();
    sleep(ms = cast(int) rdtsc() % 100);
    print(" done.\n"); paint_screen();
    yield();
}
