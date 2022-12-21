
Task_Info :: struct {
    rsp: *void;
    page_table: u64;
    next: *Task_Info;

    stack_bottom: *void;
    stack_size: int;

    thread_storage: *void;
    thread_storage_size: int;

    startup_data: *void;
    entry: (data: *void);
    the_context: *Context;

    state: enum {
        INVALID;
        AWAKE;
        WAITING_FOR_MESSAGE;
        SLEEPING;
        RETIRED;
    };

    parent_process: struct {
        input: Event_Buffer(Keyboard_Event);
        mouse_events: Event_Buffer(Mouse_Event);

        input_data: Any;
        output_data: Any;

        name: string;
    };
}

the_first_task: Task_Info;
current_task: *Task_Info;

initialize_task_manager :: () {
    task_switch :: () #c_call #foreign Interrupts;
    idt_add_handler(xx task_switch, 0x40);

    the_first_task.next = *the_first_task;
    the_first_task.the_context = *context;
    the_first_task.state = .AWAKE;
    the_first_task.page_table = to_physical(pml4.data);
    current_task = *the_first_task;
}

switch_to_task :: (new: *Task_Info) {
    current := *current_task;

    tls := new.thread_storage;
    #asm FSGSBASE {
        wrfsbase tls;
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

make_task :: (entry_point: (data: *void), startup_data: *void = null, stack_size := 0x1_0000) -> *Task_Info {
    task := cast(*Task_Info) map_memory(size_of(Task_Info));

    task.stack_bottom = map_memory(stack_size) + stack_size;
    task.stack_size   = stack_size;

    stack := cast(*Interrupt_Data) task.stack_bottom - 1;
    stack.ip = cast(u64) cast(*void) new_task_start;
    stack.flags = 0x200;
    stack.cs = 0x08;
    stack.ss = 0x10;
    stack.sp = xx (task.stack_bottom - 8);
    task.rsp = xx stack;

    task.next = current_task.next;
    current_task.next = task;

    task.entry = entry_point;
    task.startup_data = startup_data;
    task.state = .AWAKE;

    cr3: u64;
    #asm { get_cr3 cr3; }
    task.page_table = cr3;

    tls := map_memory(0x4000);
    task.thread_storage = tls;
    task.thread_storage_size = 0x4000;

    return task;
}

yield :: () {
    new := current_task.next;
    while new.state != .AWAKE {
        new = new.next;
        if new == current_task.next {
            switch_to_task(*the_first_task);
            return;
        }
    }
    switch_to_task(new);
}

exit :: () {
    task := current_task;
    while true {
        assert(task != null);
        if task.next == current_task {
            task.next = task.next.next;
            task = current_task;
            break;
        }
        task = task.next;
        assert(task != current_task);
    }

    for *windows if it.exists && it.owner == task  close_window(it_index);

    stack_top := task.stack_bottom - task.stack_size;
    // unmap_memory(task.stack_size, cast(u64) stack_top);
    unmap_memory(task.thread_storage_size, cast(u64) task.thread_storage);

    task.state = .RETIRED;
    if shell.foreground_task == task {
        shell.foreground_task = *the_first_task;
    }

    yield();
}

#program_export
pit_interrupt :: (data: *Interrupt_Data) #c_call {
    defer pic_end_of_interrupt(.PIT);
}




valid_alive_and_owned :: (w: Window_Handle) -> bool {
    if w >= 32 || w < 0 return false;
    if !windows[w].exists return false;
    if windows[w].owner != current_task && current_task != *the_first_task return false;

    return true;
}

Window_Handle :: s64;
INVALID_WINDOW_HANDLE : Window_Handle : -1;
MAX_WINDOWS :: 32;

windows: [MAX_WINDOWS] Window;

Window :: struct {
    blitter: Blitter;
    shadow: Solid_Color;

    owner: *Task_Info;
    exists: bool;
}

create_window :: (width: int, height: int) -> Window_Handle {
    for * windows {
        if it.exists continue;

        it.exists = true;
        it.owner = current_task;

        it.shadow = .{};
        it.blitter = .{};

        add_screen_draw_list_entry(*it.shadow, 0, 0, Basic.tprint("shadow %", it_index));
        add_screen_draw_list_entry(*it.blitter, 0, 0, Basic.tprint("window %", it_index));

        it.blitter.source_surface = create_surface(width, height);

        it.blitter.draw.x = graphics.screen.width / 2 - width / 2;
        it.blitter.draw.y = graphics.screen.height / 2 - height / 2;
        it.blitter.draw.width = width;
        it.blitter.draw.height = height;

        it.shadow.color.as_u32 = 0x181818;
        it.shadow.draw.target_rect = it.blitter.draw.target_rect;
        it.shadow.draw.width += 4;
        it.shadow.draw.height += 4;

        return cast(Window_Handle) it_index;
    }

    return INVALID_WINDOW_HANDLE;
}

close_window :: (window: Window_Handle) {
    if window == INVALID_WINDOW_HANDLE return;

    w := *windows[window];

    if !w.exists return;
    if (w.owner != current_task) && (current_task != *the_first_task) return;

    w.shadow.draw.prev.next = w.blitter.draw.next;
    if w.blitter.draw.next {
        w.blitter.draw.next.prev = w.shadow.draw.prev;
    }

    shell.background.draw.dirty = true;
    shell.text.draw.dirty = true;
    shell.command_text.draw.dirty = true;

    destroy_surface(*w.blitter.source_surface);
    w.exists = false;

    paint_screen();
}

move_to_front :: (window: Window_Handle) {
    if window == INVALID_WINDOW_HANDLE return;
    w := *windows[window];
    if !w.exists return;
    if w.blitter.draw.next == null return;

    w.shadow.draw.prev.next = w.blitter.draw.next;
    w.blitter.draw.next.prev = w.shadow.draw.prev;

    entry := graphics.draw_list;
    while entry.next {
        entry = entry.next;
    }

    entry.next = *w.shadow.draw;
    w.shadow.draw.prev = entry;
    w.blitter.draw.next = null;

    paint_screen();
}


MAX_FILE_POINTERS :: 64;
file_pointers: [MAX_FILE_POINTERS] File_Pointer;

File_Pointer :: struct {
    inode_id: int;
    reference_count: int;
}

MAX_FILE_DESCRIPTORS :: 64;
file_descriptors: [MAX_FILE_DESCRIPTORS] File_Descriptor;

File_Descriptor :: struct {
    file_pointer_id: int;
    has_write_access: bool;
}
