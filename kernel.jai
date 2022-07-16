
Basic  :: #import "Basic";
String :: #import "String";

#import "Machine_X64";
#import,file "modules/Elf.jai";
#import,file "modules/Theos_Filesystem.jai";

#load "pci.jai";
#load "graphics.jai";
#load "config.jai";
#load "keyboard.jai";
#load "shell.jai";
#load "task.jai";

cpu: Cpu_X86;

Bios_Memory_Map_Entry :: struct {
    base: u64;
    limit: u64;
    type: enum u32 {
        NONE         :: 0x0;
        AVAILABLE    :: 0x1;
        RESERVED     :: 0x2;
        ACPI_RECLAIM :: 0x3;
        ACPI_NVS     :: 0x4;
        BAD          :: 0x5;
    };
    _: u32;
}

#assert(size_of(Bios_Memory_Map_Entry) == 24);

Boot_Data :: struct {
    vesa_framebuffer: u32;
    boot_drive_number: u8;
    memory_map_size: u16;
    memory_map: *Bios_Memory_Map_Entry;

    boot_drive_parameters: struct {
        buffer_size:      u16;
        info_flags:       u16;
        num_cylinders:    u32;
        num_heads:        u32;
        num_sectors:      u32;
        sector_count:     u64;
        bytes_per_sector: u16;

        edd_config_params: u32 #align 2;

        device_path_info_is_present_signature: u16; // 0xbedd
        device_path_info_length: u8;
        reserved: [3] u8;

        host_bus_name: enum u32 {
            ISA :: 0x20415349;
            PCI :: 0x20494350;
        };

        interface_type_name: [8] u8;

        interface_path: union {
            isa_base_address: u16;
            pci_address: struct { bus, device, func: u8; };
            _padding: [8] u8;
        };
        device_path: u64;

        reserved_2: u8;
        checksum: u8;
    } #no_padding
}

#assert(size_of(type_of(boot_data.boot_drive_parameters)) == 0x42);
#assert(size_of(Boot_Data) < BOOT_DATA_SIZE / 2);

boot_data: Boot_Data;
boot_drive: *Mass_Storage_Device;

global_kernel_context: *Context;

#program_export
kernel_entry :: () {
    kernel_context: Context;
    kernel_context.allocator.proc = allocate_memory;
    kernel_context.logger = log;
    kernel_context.assertion_failed = assertion_failed;

    push_context kernel_context {
        boot_data = << cast(*Boot_Data) BOOT_DATA_AREA;

        global_kernel_context = *context;
        idt_init();
        gdt_init();
        pic_init();
        cmos_init();

        cpu = get_cpu_info();
        init_physical_allocator();
        page_table_init();
        enable_ps2();
        cmos_enable_irq(true);
        cmos_set_rate(15);
        enable_simd(cpu);

        acpi_init();
        hpet_init();

        pci_scan_all_devices();
        discover_mass_storage_devices();
        assert(disks.count == 1);
        boot_drive = *disks[0];
        // shutdown_emulator();

        read_block = (block_index: int, block: *Disk_Block, *void) {
            location := FS_BASE_ADDRESS + block_index * FS_BLOCKSIZE;
            read_mass_storage(boot_drive, block, FS_BLOCKSIZE, location);
        };

        write_block = (block_index: int, block: *Disk_Block, *void) {
            location := FS_BASE_ADDRESS + block_index * FS_BLOCKSIZE;
            write_mass_storage(boot_drive, block, FS_BLOCKSIZE, location);
        };

        // read_extent = (block_index: int, block_count: int, data: *void, user_data: *void) {
        //     buffer := map_memory(block_count * FS_BLOCKSIZE, physically_contiguous = true);
        //     location := FS_BASE_ADDRESS + block_index * FS_BLOCKSIZE;
        //     ide_bus_master_transfer(.READ, buffer, xx (block_count * FS_BLOCKSIZE), xx location);
        //     memcpy(data, buffer, block_count * FS_BLOCKSIZE);
        // };

        get_time = (user: *void) -> Basic.Apollo_Time {
            return get_system_time();
        };

        assert(initialize_filesystem());

        font_file := read_file("system/font.pgm");
        font: Pnm = parse_pnm(font_file);

        ct := cmos_get_calendar_time();
        boot_time = theos_calendar_to_apollo(ct);

        initialize_task_manager();

        #if !ENABLE_VESA {
            print("This is where we start entering the shell.\n");
            print("However, we're in VGA debugging mode from where we can't draw anything, so we're going to halt.\n");
            while true #asm { hlt; }
        }

        init_graphics(*boot_data);
        init_shell(font);

        make_task(work, *"Task 1");
        yield();

        startup := read_file("system/startup.shell");
        commands := String.split(cast(string) startup, "\n");
        for commands shell_run_command(it);

        paint_screen();

        while true {
            #asm {
                hlt;
            }

            handle_keyboard_events();
            update_shell();
        }
    }
}

tlb_flush :: () {
    #asm {
        get_cr3 cr3:;
        set_cr3 cr3;
    }
}

#add_context printing_stack_trace: bool;

print_stack_trace :: (stack := context.stack_trace) {
    if context.printing_stack_trace return;
    context.printing_stack_trace = true;
    print("Stack trace:\n", theme.accent);

    node := stack;
    while node {
        if node.info != null {
            filename := String.path_filename(node.info.location.fully_pathed_filename);
            printf("   | %:% in ", filename, node.line_number);
            printf("%", node.info.name, color = theme.primary);
            print("()\n");

        }
        node = node.next;
    }
    print("\n");
    context.printing_stack_trace = false;
}

allocate_memory :: (mode: Allocator_Mode, size: s64, old_size: s64, old_buffer: *void, user_data: *void) -> *void {
    if mode == .FREE {
        unmap_memory(size, xx old_buffer);
        return null;
    }

    if mode == .RESIZE && old_size {
        if size < old_size || size < 4096 {
            return old_buffer;
        }
    }

    return map_memory(size);
}

log :: (message: string, data: *void, info: Log_Info) {
    print(message);
    print("\n");
    paint_screen();
}

assertion_failed :: (location: Source_Code_Location, message: string) {
    print("\nAssertion failure!\n  -> ");
    print(location.fully_pathed_filename, theme.accent);
    print(":");
    print(location.line_number, theme.accent);

    if message.count {
        print("\n     ");
        print(message);
    }
    print("\n\n");

    paint_screen();
    print_stack_trace();
    paint_screen();

    while true {
        #asm { hlt; }
    }
}

min :: (a: $T, b: T) -> T { if a < b return a; return b; }
max :: (a: $T, b: T) -> T { if a > b return a; return b; }

crt_memset :: (target: *u8, value: s32, count: u64) -> *void #c_call {
    #asm {
        cld;

        count  === c;
        target === di;
        value  === a;
        rep_stos.b target, value, count;
    }

    return target;
}

crt_memcpy :: (dst: *void, src: *void, count: u64) -> *void #c_call {
    #asm {
        cld;

        src   === si;
        dst   === di;
        count === c;
        rep_movs.b dst, src, count;
    }

    return dst;
}

crt_memcmp :: (a: *u8, b: *u8, count: u64) -> s32 #c_call {
    for 0..(cast(s64) count)-1 {
        if a[it] != b[it] {
            return a[it] - b[it];
        }
    }
    return 0;
}

assert :: (condition: bool, message: string = "", call_site := #caller_location) {
    if !condition {
        assertion_failed(call_site, message);
    }
}

shutdown_emulator :: () #no_context {
    out(0xb004, cast(u16) 0x2000);
    out(0x0604, cast(u16) 0x2000);
    out(0x4004, cast(u16) 0x3400);
}

out :: (port: u16, value: $T) #no_context {
    #asm {
        port  === d;
        value === a;
    }

    #if      T == u8  #asm { out.b port, value; }
    else #if T == u16 #asm { out.w port, value; }
    else #if T == u32 #asm { out.d port, value; }
    else #assert(false);
}

in :: (port: u16, $T: Type = u32) -> T {
    value: T;    
    #asm {
        port  === d;
        value === a;
    }

    #if      T == u8  #asm { in.b value, port; }
    else #if T == u16 #asm { in.w value, port; }
    else #if T == u32 #asm { in.d value, port; }
    else #assert(false);

    return value;
}

port_write :: (_port: $P, _value: $V) #no_context {
    port  := cast(u16) _port;
    value := cast(u8)  _value;
    #asm {
        port  === d;
        value === a;
        out.b port, value;
    }
}

port_read :: (_port: $P) -> u8 #no_context {
    port := cast(u16) _port;
    value: u8;
    #asm {
        port  === d;
        value === a;
        in.b value, port;
    }
    return value;
}

io_delay :: () #no_context {
    #asm {
        zero: gpr === a;
        xor zero, zero;
        out.b 0x80, zero;
    }
}

divru :: (dividend: $T, $$ divisor: T) -> T {
    return (dividend + (divisor - 1)) / divisor;
}

enable_simd :: (cpu: Cpu_X86) {
    CR0_MP         ::   1 << 1;
    CR0_EM_CLEAR   := ~(1 << 2);
    CR4_OSFXSR     ::   1 << 9;
    CR4_OSXMMEXCPT ::   1 << 10;
    CR4_OSXSAVE    ::   1 << 18;
    CR4_FSGSBASE   ::   1 << 16;

    if check_feature(cpu.feature_leaves, .SSE) #asm {
        get_cr0 cr0:;
        and cr0, CR0_EM_CLEAR;
        or  cr0, CR0_MP;
        set_cr0 cr0;

        get_cr4 cr4:;
        or  cr4, CR4_OSFXSR;
        or  cr4, CR4_OSXMMEXCPT;
        set_cr4 cr4;
    }

    if check_feature(cpu.feature_leaves, .FSGSBASE) #asm {
        get_cr4 cr4:;
        or  cr4, CR4_FSGSBASE;
        set_cr4 cr4;
    }

//    if check_feature(cpu.feature_leaves, .OSXSAVE) #asm {
//        get_cr4 cr4:;
//        or  cr4, CR4_OSXSAVE;
//        set_cr4 cr4;
//    }
//
    if check_feature(cpu.feature_leaves, .AVX) #asm XSAVE {
        index: gpr === c;

        xgetbv xcr0_h:, xcr0_l:, index;
        or xcr0_l, 7;
        xsetbv xcr0_h, xcr0_l, index;
    }
}

BochsBreak :: () #expand {
    #asm {
        bx: gpr === b;
        xchg.w bx, bx;
    }
}

sleep :: (ms: int) {
    time := get_system_time();
    while true {
        #asm { hlt; }

        elapsed := Basic.operator-(get_system_time(), time);
        if Basic.to_milliseconds(elapsed) > ms break;
    }
}



gdt: [10] u64 #align 0x80;

Gdt_Entry_Flags :: enum {
    LONG_MODE_CODE  :: 0x02 << 52;
    SIZE            :: 0x04 << 52;
    GRANULARITY     :: 0x08 << 52;
    ACCESSED        :: 0x01 << 40;
    READ_WRITE      :: 0x02 << 40;
    DIRECTION       :: 0x04 << 40;
    EXECUTABLE      :: 0x08 << 40;
    DESCRIPTOR_TYPE :: 0x10 << 40;
    PRIVILEGE0      :: 0x20 << 40;
    PRIVILEGE1      :: 0x40 << 40;
    PRESENT         :: 0x80 << 40;
}

make_gdt_entry :: (base: u64, limit: u32, flags: u64) -> u64 {
    entry: u64;

    target := cast(*u8) *entry;
    target[0] = xx ((limit & 0xff));
    target[1] = xx ((limit >> 8) & 0xff);
    target[6] = xx ((limit >> 16) & 0x0f);

    target[2] = xx (base & 0xff);
    target[3] = xx ((base >> 8) & 0xff);
    target[4] = xx ((base >> 16) & 0xff);
    target[7] = xx ((base >> 24) & 0xff);

    entry = << cast(*u64) target;
    entry |= flags;
    return entry;
}

gdt_init :: () {
    using Gdt_Entry_Flags;

    gdt[0] = 0x0;
    gdt[1] = xx (READ_WRITE | PRESENT | DESCRIPTOR_TYPE | LONG_MODE_CODE | EXECUTABLE);
    gdt[2] = xx (READ_WRITE | PRESENT | DESCRIPTOR_TYPE);

    gdtr: struct {
        limit: u16;
        base: u64 #align 2;
    }

    gdtr.limit = 0x28;
    gdtr.base = xx gdt.data;

    gdtrp := *gdtr;

    #asm {
        lgdt [gdtrp];
    }
}




Interrupt_Stack_Frame :: struct {
    ip:    u64;
    cs:    u64;
    flags: u64;
    sp:    u64;
    ss:    u64;
}

Interrupt_Data :: struct {
    r15:  u64;
    r14:  u64;
    r13:  u64;
    r12:  u64;
    r11:  u64;
    r10:  u64;
    r9:   u64;
    r8:   u64;
    rbp:  u64;
    rdi:  u64;
    rsi:  u64;
    rdx:  u64;
    rcx:  u64;
    rbx:  u64;
    rax:  u64;
    using interrupt_frame: Interrupt_Stack_Frame;
}

Idt_Entry :: struct {
    offset_1: u16;
    selector: u16;
    ist:      u8;
    flags:    u8;
    offset_2: u16;
    offset_3: u32;
    reserved: u32;
}

idt_desc: struct {
    limit: u16;
    base:  u64 #align 2;
}

#assert(size_of(Idt_Entry)          == 16);
#assert(size_of(type_of(idt_desc))  == 10);

idt: [0x100] Idt_Entry #align 0x1000;

idt_add_handler :: (address: *void, index: int) {
    _address := cast(u64) address;

    entry: Idt_Entry;
    entry.offset_1  = xx  _address        & 0xffff;
    entry.offset_2  = xx (_address >> 16) & 0xffff;
    entry.offset_3  = xx (_address >> 32) & 0xffffffff;
    entry.selector  = 0b00001000;
    entry.ist       = 0x0;
    entry.flags     = 0x8e;
    entry.reserved  = 0x0;

    idt[index] = entry;
}

idt_init :: () {
    idt_desc.limit = 0x100 * size_of(Idt_Entry);
    idt_desc.base = xx idt.data;

    register_generated_isrs();
    idt_add_handler(xx page_fault_handler, 0x0e);

    address := *idt_desc;
    #asm {
        lidt [address];
    }
}

Interrupts :: #foreign_library,no_dll ".build/interrupt";


Pic_Port :: enum u16 {
    MASTER_CMD  :: 0x20;
    MASTER_DATA :: 0x21;
    SLAVE_CMD   :: 0xa0;
    SLAVE_DATA  :: 0xa1;
}

Pic_Command :: enum u8 {
    INITIALIZE       :: 0x11;
    END_OF_INTERRUPT :: 0x20;
}

PIC_BASE_OFFSET :: 0x20;

PIC_ICW4_uPM  :: 0x1;
PIC_ICW4_AEOI :: 0x2;
PIC_ICW4_M_S  :: 0x4;
PIC_ICW4_BUF  :: 0x8;
PIC_ICW4_SFMN :: 0x10;

pic_end_of_interrupt :: (irq: Pic_Request_Line) #c_call {
    using Pic_Port;
    using Pic_Command;

    if irq >= 8 {
        port_write(SLAVE_CMD, END_OF_INTERRUPT);
    }
    port_write(MASTER_CMD, END_OF_INTERRUPT);
}

pic_init :: () {
    using Pic_Port;
    using Pic_Command;

    SLAVE_ADDRESS :: 0b0000_0100;

    port_write(MASTER_CMD,  INITIALIZE);
    port_write(MASTER_DATA, PIC_BASE_OFFSET);
    port_write(MASTER_DATA, SLAVE_ADDRESS);
    port_write(MASTER_DATA, PIC_ICW4_uPM);
    port_write(MASTER_DATA, 0xff);

    port_write(SLAVE_CMD,  INITIALIZE);
    port_write(SLAVE_DATA, PIC_BASE_OFFSET + 0x8);
    port_write(SLAVE_DATA, 0x2);
    port_write(SLAVE_DATA, PIC_ICW4_uPM);
    port_write(SLAVE_DATA, 0xff);

    pic_enable_irq(.CASCADE);

    #asm { sti; }
}

pic_enable_irq :: (irq: Pic_Request_Line) {
    using Pic_Port;
    port := MASTER_DATA;

    if irq >= 8 {
        irq -= 8;
        port = SLAVE_DATA;
    }

    mask:  u8 = xx ~(1 << cast(u8) irq);
    value: u8 = port_read(port) & mask;
    port_write(port, value);
}

Pic_Request_Line :: enum {
    PROGRAMMABLE_INTERRUPT_TIMER :: 0x0;
    PS2_KEYBOARD                 :: 0x1;
    CASCADE                      :: 0x2;
    COM2                         :: 0x3;
    COM1                         :: 0x4;
    LPT2                         :: 0x5;
    FLOPPY_DISK                  :: 0x6;
    SPURIOUS                     :: 0x7;
    CMOS_RTC                     :: 0x8;
    PS2_MOUSE                    :: 0xc;
    FPU                          :: 0xd;
    PRIMARY_ATA                  :: 0xe;
    SECONDARY_ATA                :: 0xf;
}

#program_export
pit_interrupt :: () #c_call {

}



cmos_format: struct {
    bcd_mode: bool;
    twenty_four_h: bool;
    rate: int;
}

Cmos_Port :: enum u16 {
    ADDRESS :: 0x70;
    DATA    :: 0x71;
}

Cmos_Register :: enum u8 {
    SECONDS          :: 0x00;
    SECONDS_ALARM    :: 0x01;
    MINUTES          :: 0x02;
    MINUTES_ALARM    :: 0x03;
    HOURS            :: 0x04;
    HOURS_ALARM      :: 0x05;
    WEEKDAY          :: 0x06;
    DAY_OF_THE_MONTH :: 0x07;
    MONTH            :: 0x08;
    YEAR             :: 0x09;
    CENTURY          :: 0x32;
    STATUS_REG_A     :: 0x0a;
    STATUS_REG_B     :: 0x0b;
    STATUS_REG_C     :: 0x0c;
}

Cmos_Status_B :: enum_flags u8 {
    _24H_CLOCK                :: 0x01;
    BCD_MODE                  :: 0x02;
    INTERRUPT_UPDATE_COMPLETE :: 0x10;
    INTERRUPT_ALARM           :: 0x20;
    INTERRUPT_PERIODIC        :: 0x40;
}

cmos_init :: () {
    using Cmos_Status_B;

    status := cmos_read(.STATUS_REG_B);
    cmos_format.bcd_mode      = status & xx BCD_MODE   > 0;
    cmos_format.twenty_four_h = status & xx _24H_CLOCK > 0;
}

cmos_read :: ($register: Cmos_Register) -> u8 #c_call {
    using Cmos_Port;

    port_write(ADDRESS, register);
    io_delay();
    result := port_read(DATA);
    while true {
        port_write(ADDRESS, register);
        io_delay();
        new := port_read(DATA);

        if new == result break;
        result = new;
    }

    #if register < .STATUS_REG_A {
        if cmos_format.bcd_mode {
            result = (result & 0xf) + (result / 16) * 10;
        }
    }

    return result;
}

cmos_write :: ($register: Cmos_Register, value: u8) {
    using Cmos_Port;

    port_write(ADDRESS, register);
    io_delay();
    port_write(DATA, value);
}

cmos_enable_irq :: (periodic: bool, alarm := false, update := false) {
    using Cmos_Port;
    using Cmos_Register;

    #asm { cli; }
    
    cmos_set_rate(4);
    pic_enable_irq(.CMOS_RTC);

    port_write(ADDRESS, STATUS_REG_B | 0x80);
    cmos_b := port_read(Cmos_Port.DATA);

    using Cmos_Status_B;
    if periodic  cmos_b |= xx INTERRUPT_PERIODIC;
    if update    cmos_b |= xx INTERRUPT_UPDATE_COMPLETE;
    if alarm     cmos_b |= xx INTERRUPT_ALARM;

    port_write(ADDRESS, STATUS_REG_B | 0x80);
    port_write(DATA, cmos_b);

    #asm { sti; }
    cmos_read(.STATUS_REG_C);
}

cmos_set_rate :: (rate: u8) {
    using Cmos_Port;
    using Cmos_Register;
    assert((rate & 0xf) == rate);

    cmos_format.rate = rate;

    #asm { cli; }
    port_write(ADDRESS, STATUS_REG_A | 0x80);
    cmos_a := port_read(Cmos_Port.DATA);

    port_write(ADDRESS, STATUS_REG_A | 0x80);
    port_write(DATA, (cmos_a & 0xf0) | rate);
    #asm { sti; }
}

cmos_get_calendar_time :: () -> Basic.Calendar_Time {
    cal: Basic.Calendar_Time;
    cal.time_zone = .UTC;

    cal.month\      _starting_at_0 = cast(s8) cmos_read(.MONTH) - 1;
    cal.day_of_month_starting_at_0 = cast(s8) cmos_read(.DAY_OF_THE_MONTH) - 1;
    cal.day_of_week\_starting_at_0 = cast(s8) cmos_read(.WEEKDAY) - 1;

    cal.year   = cast(s32) cmos_read(.YEAR) + 2000;
    cal.hour   = cast(s8)  cmos_read(.HOURS);
    cal.minute = cast(s8)  cmos_read(.MINUTES);
    cal.second = cast(s8)  cmos_read(.SECONDS);

    return cal;
}

theos_calendar_to_apollo :: (ct: Basic.Calendar_Time) -> Basic.Apollo_Time {
    using Basic;
    leap_year_count := leap_years_before(cast(s64) ct.year - 1) - leap_years_before(1970);
    year_difference := cast(s64) ct.year - 1970;

    seconds := 31536000 * (year_difference - leap_year_count);
    seconds += 31622400 * leap_year_count;

    for 0..ct.month_starting_at_0 - 1 {
        days :: int.[
            31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
        ];

        if it == days.count break;
        seconds += 86400 * days[it];
    }

    is_leap_year := (ct.year % 4 == 0) && (!(ct.year % 100 == 0) || (ct.year % 400 == 0));
    if ct.month_starting_at_0 > 1 && is_leap_year {
        seconds += 86400;
    }

    seconds += 86400 * cast(int) ct.day_of_month_starting_at_0;
    seconds += cast(int) ct.hour * 60 * 60 + cast(int) ct.minute * 60 + cast(int) ct.second;

    APOLLO_TIME_FOR_JAN_1_1970 :: Basic.Apollo_Time.{low=0xdbd87f0edb7c8000, high=0x300};

    apollo := Basic.seconds_to_apollo(seconds);
    apollo += Basic.milliseconds_to_apollo(ct.millisecond);
    apollo += APOLLO_TIME_FOR_JAN_1_1970;
    return apollo;
}

theos_apollo_to_calendar :: (apollo: Basic.Apollo_Time) -> Basic.Calendar_Time {
    using Basic;
    APOLLO_TIME_FOR_JAN_1_1970 :: Basic.Apollo_Time.{low=0xdbd87f0edb7c8000, high=0x300};
    milliseconds := Basic.to_milliseconds(apollo - APOLLO_TIME_FOR_JAN_1_1970);

    seconds      := milliseconds / 1000;
    minutes      := seconds      / 60;
    hours        := minutes      / 60;
    total_days   := hours        / 24;

    milliseconds -= seconds      * 1000;
    seconds      -= minutes      * 60;
    minutes      -= hours        * 60;
    hours        -= total_days   * 24;

    years := total_days / 365;
    leap_year_count := leap_years_before(years + 2);

    years = (total_days - leap_year_count * 366) / 365;
    years += leap_year_count;

    days := total_days - (years - leap_year_count) * 365;
    days -= leap_year_count * 366;

    years += 1970;
    is_leap_year := (years % 4 == 0) && (!(years % 100 == 0) || (years % 400 == 0));
    if is_leap_year && days < 59 days += 1;

    ct: Basic.Calendar_Time;

    days_in_month := int.[
        31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
    ];

    month: int;
    for days_in_month {
        month += 1;

        if days >= it {
            days -= it;
        } else {
            month = xx it_index;
            break;
        }
    }

    ct.year = xx years;
    // is_leap_year := (ct.year % 4 == 0) && (!(ct.year % 100 == 0) || (ct.year % 400 == 0));
    // if is_leap_year && month < 2 month_day += 1;

    ct.day_of_week_starting_at_0 = xx ((4 + total_days) % 7);

    ct.month_starting_at_0 = xx month;
    ct.day_of_month_starting_at_0 = xx days;

    ct.hour = xx hours;
    ct.minute = xx minutes;
    ct.second = xx seconds;
    ct.millisecond = xx milliseconds;
    return ct;
}

leap_years_before :: (year: s64) -> s64 {
    floor_div :: (dividend: int, $ divisor: int) -> int {
        offset := cast(int) (dividend <= 0 && dividend % divisor);
        return dividend / divisor - offset;
    }

    result := floor_div(year, 4) - floor_div(year, 100) + floor_div(year, 400);
    return result;
}


#program_export
cmos_interrupt :: () #c_call {
    cmos_read(.STATUS_REG_C);
    timer_ticks_elapsed += 1;

    pic_end_of_interrupt(.CMOS_RTC);
}

get_system_time :: () -> Basic.Apollo_Time {
    using Basic;

    ticks := read(Hpet_Register.COUNTER);

    elapsed: Apollo_Time;
    elapsed.low = ticks;
    elapsed *= cast(s64) hpet.base_period;

    return elapsed + boot_time;
}

boot_time: Basic.Apollo_Time;

timer_ticks_elapsed: u64;
timer_ticks_target: u64;

CMOS_BASE_FREQ :: 32768;

time_difference :: (ticks_a: u64, ticks_b: u64) -> float {
    frequency := (CMOS_BASE_FREQ >> (cmos_format.rate - 1));
    return cast(float) (ticks_b - ticks_a) / cast(float) frequency;
}

wait_for_seconds :: (seconds: float) {
    timer_ticks_target = cast(u64) (seconds * (CMOS_BASE_FREQ >> (cmos_format.rate - 1)));
    timer_ticks_target += timer_ticks_elapsed;

    while true {
        #asm { sti; hlt; }
        if timer_ticks_elapsed >= timer_ticks_target {
            break;
        }
    }

    timer_ticks_target = 0;
}



acpi: struct {
    root_table: *Acpi_Table_Header;
    version: int;
}

Acpi_Root_Pointer :: struct {
    signature: [8] u8;
    checksum: u8;
    oem_id: [6] u8;
    revision: u8;
    rsdt_address: u32;

    length: u32;
    xsdt_address: u64 #align 4;
    checksum_2: u8;
    reserved: [3] u8;
}

#assert (size_of(Acpi_Root_Pointer) == 36);

Acpi_Table_Header :: struct {
    signature: [4] u8;
    length: u32;
    revision: u8;
    checksum: u8;
    oem_id: [6] u8;
    oem_table_id: [8] u8;
    oem_revision: u32;
    creator_id: u32;
    creator_revision: u32;
}

acpi_init :: () {
    rsdp := acpi_find_root_table();
    assert(rsdp != null, "Could not find ACPI root system description pointer (RSDP)");
    assert(acpi_validate_pointer(rsdp));

    acpi.version = rsdp.revision;

    phys := cast(u64) rsdp.rsdt_address;
    if acpi.version == 2  phys = rsdp.xsdt_address;

    offset_in_page := phys % 0x1000;
    virt := map_memory(0x4000, physical_address = phys);

    rsdt: *Acpi_Table_Header = virt + offset_in_page;

    assert(acpi_validate_table(rsdt));
    acpi.root_table = rsdt;
}

acpi_get_table_by_signature :: (sig: string) -> *Acpi_Table_Header {
    table_size := acpi.root_table.length - size_of(Acpi_Table_Header);

    pointer_size := cast(u64) (ifx acpi.version then 8 else 4);
    pointer_count := table_size / pointer_size;

    table_base := cast(u64) (acpi.root_table + 1);

    for 0..pointer_count - 1 {
        header: *Acpi_Table_Header;

        phys: u64;
        if acpi.version == 0 {
            phys = cast(u64) << cast(*u32) (it * 4 + table_base);
        }

        else if acpi.version == 2 {
            phys = << cast(*u64) (it * 8 + table_base);
        }

        else assert(false);

        virt := map_memory(0x1000, physical_address = phys);
        offset_in_page := phys % 0x1000;

        header = cast(*Acpi_Table_Header) (virt + offset_in_page);

        if cast(string) header.signature == sig {
            assert(acpi_validate_table(header));
            return header;
        }
    }

    return null;
}

acpi_find_root_table :: () -> *Acpi_Root_Pointer {
    EBDA_BASE := KERNEL_BASE + 0x9fc00;
    EBDA_SIZE := 0x400;

    for 0..EBDA_SIZE / 16 - 1 {
        address := xx EBDA_BASE + 16 * it;
        signature := cast(string) << cast(*[8] u8) address;

        if signature == "RSD PTR " return xx address;
    }

    BDA_BASE := 0xe_0000 + KERNEL_BASE;
    BDA_SIZE := 0xf_ffff - 0xe_0000;

    for 0..BDA_SIZE / 16 - 1 {
        address := xx BDA_BASE + 16 * it;
        signature := cast(string) << cast(*[8] u8) address;

        if signature == "RSD PTR " return xx address;
    }

    return null;
}

acpi_validate_pointer :: (rsdp: *Acpi_Root_Pointer) -> bool {
    array: [] u8;
    array.data = xx rsdp;
    array.count = ifx rsdp.revision 36 else 20;

    sum: u8;
    for array sum += it;

    return !sum;
}

acpi_validate_table :: (header: *Acpi_Table_Header) -> bool {
    sum: u8;
    for 0..header.length - 1 {
        sum += (cast(*u8) header)[it];
    }
    return !sum;
}



Hpet_Acpi_Table :: struct {
    #as header: Acpi_Table_Header;
    hardware_revision: u8;
    flags: u8;
    vendor: u16 #align 1;
    address_space: enum u8 { MAIN_MEMORY :: 0; IO :: 1; };
    some_stuff: [3] u8;
    base_address: u64 #align 1;
}

Hpet_Register :: enum u64 {
    CAPABILITIES :: 0x0;
    CONFIG       :: 0x10;
    STATUS       :: 0x20;
    COUNTER      :: 0xf0;
}

write :: (reg: Hpet_Register, value: u64) {
    << cast(*u64) (hpet.base_address + cast(u64) reg) = value;
}

read :: (reg: Hpet_Register) -> u64 {
    return << cast(*u64) (hpet.base_address + cast(u64) reg);
}

hpet: struct {
    acpi_table: Hpet_Acpi_Table;
    base_period: u64; // Femtoseconds
    base_address: *void;
}

hpet_init :: () {
    hpet_acpi_header := acpi_get_table_by_signature("HPET");
    assert(hpet_acpi_header != null, "HPET is not available");

    hpet.acpi_table = cast(*Hpet_Acpi_Table) hpet_acpi_header;
    assert(hpet.acpi_table.address_space == .MAIN_MEMORY);

    virt := map_memory(0x1000, physical_address = hpet.acpi_table.base_address);
    offset_in_page := hpet.acpi_table.base_address % 0x1000;
    hpet.base_address = xx (virt + offset_in_page);

    capabilities := read(Hpet_Register.CAPABILITIES);
    hpet.base_period = capabilities >> 32;
    assert(hpet.base_period > 0 && hpet.base_period < 100_000_000);

    write(Hpet_Register.COUNTER, 0);

    ENABLE_CNF :: 1;
    LEG_RT_CNF :: 2;
    write(.CONFIG, read(.CONFIG) | ENABLE_CNF);
}

hpet_get_ticks :: () -> u64 {
    return read(Hpet_Register.COUNTER);
}



get_memory_map :: () -> [] Bios_Memory_Map_Entry {
    memory_map: [] Bios_Memory_Map_Entry;
    memory_map.count = xx boot_data.memory_map_size;
    memory_map.data = boot_data.memory_map;

    return memory_map;
}

Virtual_Address_Space :: struct {
    root_page_table: u64;
#place root_page_table;
    pml4: u64;
    virtual_page_watermark: int;
}

kernel_address_space: Virtual_Address_Space;

PAGE_TABLE_RANGE :: 0x200_000;

page_dir: [0x200] u64 #align 0x1000;
pdpt:     [0x200] u64 #align 0x1000;
pml4:     [0x200] u64 #align 0x1000;

Page_Flags :: enum_flags u64 {
    PRESENT         :: 1 << 0;
    READ_WRITE      :: 1 << 1;
    USER_SUPERVISOR :: 1 << 2;
    WRITE_THROUGH   :: 1 << 3;
    CACHE_DISABLE   :: 1 << 4;
    ACCESSED        :: 1 << 5;
    AVAILABLE       :: 1 << 6;
    PAGE_SIZE       :: 1 << 7;
    EXECUTE_DISABLE :: 1 << 63;
}

VIRTUAL_MIRROR : u64 : 0xffff_ffff_c000_0000;
KERNEL_BASE    : u64 : 0xffff_ffff_8000_0000;

to_virtual :: (phys: u64) -> *u64 {
    return cast(*u64) (phys + VIRTUAL_MIRROR);
}

to_physical :: (virt: *void) -> u64 {
    return cast(u64) (virt - KERNEL_BASE);
}

mirror_pd:   [0x200] u64 #align 0x1000;

ONE_GB : u64 : 0x4000_0000;

page_table_init :: () {
    using Page_Flags;
    kernel_address_space.root_page_table = to_physical(pml4.data);
    kernel_address_space.virtual_page_watermark = 0xffff_ffff_80c0_0000 / 0x1000;

    pml4[0x1ff] = to_physical(pdpt.data)      | xx PRESENT | READ_WRITE;
    pdpt[0x1ff] = to_physical(mirror_pd.data) | xx PRESENT | READ_WRITE;
    for 0..0x200-1 {
        address := it * PAGE_TABLE_RANGE;
        mirror_pd[it] = cast(u64) (xx address) | PRESENT | READ_WRITE | PAGE_SIZE;
    }

    pdpt[0x1fe] = to_physical(page_dir.data) | xx PRESENT | READ_WRITE;
    page_dir[0] = 0x000_000 | cast(u64) PRESENT | READ_WRITE | PAGE_SIZE;
    page_dir[1] = 0x200_000 | cast(u64) PRESENT | READ_WRITE | PAGE_SIZE;
    page_dir[2] = 0x400_000 | cast(u64) PRESENT | READ_WRITE | PAGE_SIZE;

    pml4_base := to_physical(pml4.data);
    #asm {
        get_cr4 cr4:;
        or cr4, 0x10;
        set_cr4 cr4;

        set_cr3 pml4_base;
    }

    IA32_PAT :: 0x277;
    mask: u64 = ~0xf;
    #asm {
        msr_name: gpr === c;
        mov msr_name, IA32_PAT;
        rdmsr high:, low:, msr_name;
        and high, mask;
        or high, 0x1;
        wrmsr high, low, msr_name;
    }
}

get_or_create_page_table :: (table: *u64, entry: u64) -> *u64 {
    using Page_Flags;

    if table[entry] & xx PRESENT {
        phys := table[entry] & (~0xfff);
        return xx (xx phys + VIRTUAL_MIRROR);
    }

    phys := get_new_page_frame();
    table[entry] = phys | xx PRESENT | READ_WRITE;
    return cast(*u64) (xx phys + VIRTUAL_MIRROR);
}

unmap_memory :: (size_bytes: int, virtual_address: u64) {
    page_count := (size_bytes + (0x1000 - 1)) / 0x1000;
    for 0..page_count-1 {
        offset := cast(u64) it * 4096;
        unmap_page(virtual_address + offset);
    }
}

unmap_page :: (virtual_address: u64) {
    // pg := *virtual_address;
    // #asm { invlpg [pg]; }

    using Page_Flags;

    mask: u64 = 0b111111111;
    pml4_offset := (virtual_address >> 39) & mask;
    pdpt_offset := (virtual_address >> 30) & mask;
    pd\ _offset := (virtual_address >> 21) & mask;
    pt\ _offset := (virtual_address >> 12) & mask;

    root_table := to_virtual(kernel_address_space.root_page_table);

    pdpt := get_or_create_page_table(root_table, pml4_offset);
    pd   := get_or_create_page_table(pdpt, pdpt_offset);
    pt   := get_or_create_page_table(pd,   pd_offset);

    release_page_frame(pt[pt_offset] & ~0xfff);
    pt[pt_offset] = 0;
}

map_memory :: (size_bytes: int, virtual_address: u64 = xx,no_check -1, physical_address: u64 = xx,no_check -1, flags := Page_Flags.PRESENT | .READ_WRITE, space := *kernel_address_space, physically_contiguous := false, loc := #caller_location) -> *void {
    page_count := (size_bytes + (0x1000 - 1)) / 0x1000;

    source := virtual_address;
    if source == xx,no_check -1 {
        source = get_new_virtual_page(page_count, space);
    }
    target := physical_address;

    if physically_contiguous {
        assert(target == xx,no_check -1);
        target = get_contiguous_page_frames(page_count);
    }

    assert(address_is_page(source), "Not a page", loc);
    for 0..page_count-1 {
        offset := cast(u64) it * 4096;

        phys: u64;
        if target == xx,no_check -1  phys = get_new_page_frame();
        else phys = target + offset;

        map_page(source + offset, phys, flags, space, loc);
    }

    return xx source;
}

map_page :: (virtual_address: u64, physical_address: u64, flags := Page_Flags.PRESENT | .READ_WRITE, space := *kernel_address_space, loc := #caller_location) {
    using Page_Flags;

    mask: u64 = 0b111111111;
    pml4_offset := (virtual_address >> 39) & mask;
    pdpt_offset := (virtual_address >> 30) & mask;
    pd\ _offset := (virtual_address >> 21) & mask;
    pt\ _offset := (virtual_address >> 12) & mask;

    root_table := to_virtual(space.root_page_table);

    pdpt := get_or_create_page_table(root_table, pml4_offset);
    pd   := get_or_create_page_table(pdpt, pdpt_offset);
    pt   := get_or_create_page_table(pd,   pd_offset);

    if pt[pt_offset] & xx PRESENT {
        print("Attempting to map a virtual page that is already present.\n");
        print("The virtual address is "); print_hex(virtual_address); print("\n");
        print("The physical address is "); print_hex(physical_address); print("\n");
    }

    pt[pt_offset] = physical_address | cast(u64) flags;

    pg := *virtual_address;
    #asm { invlpg [pg]; }
}

address_is_page :: (address: u64) -> bool {
    if !address return false;
    if (address >> 48 != 0xffff) && (address >> 48 != 0x0) return false;
    return address % 0x1000 == 0;
}

get_new_virtual_page :: (count: int = 1, map: *Virtual_Address_Space) -> u64 {
    address := map.virtual_page_watermark * 0x1000;
    map.virtual_page_watermark += count;
    return xx address;
}

get_physical_address :: (virtual_address: *void, address_space := *kernel_address_space) -> u64, present: bool {
    using Page_Flags;
    x := cast(u64) virtual_address;

    mask: u64 = 0b111111111;

    pml4_offset := (x >> 39) & mask;
    pdpt_offset := (x >> 30) & mask;
    pd\ _offset := (x >> 21) & mask;
    pt\ _offset := (x >> 12) & mask;
    page_offset := x & 0xfff;

    ReadTableEntry :: (index: u64, table_address: u64) -> entry: u64 #expand {
        if !((xx table_address) & PRESENT) `return 0, false; //`

        table := cast(*u64) (table_address & (~0xfff) + VIRTUAL_MIRROR);
        return table[index];
    }

    root_table := to_virtual(address_space.root_page_table);
    pml4e := root_table[pml4_offset];

    pdpte := ReadTableEntry(pdpt_offset, pml4e);
    if pdpte & xx PAGE_SIZE {
        assert(check_feature(cpu.feature_leaves, .PDPE1GB));
        page_offset := x & 0x3fff_ffff;
        return (pdpte & ~0xfff) + page_offset, true;
    }

    pde   := ReadTableEntry(pd_offset, pdpte);
    if pde & xx PAGE_SIZE {
        page_offset := x & 0x1f_ffff;
        return (pde & ~0xfff) + page_offset, true;
    }

    pte   := ReadTableEntry(pt_offset, pde);
    return (pte & ~0xfff) + page_offset, true;
}

page_fault_handler :: () #no_call {
    #asm {
        rsp: gpr === sp;
        sub rsp, 0x200;
        cli;
    }

    error_code: *u64;
    stack_data: *Interrupt_Stack_Frame;

    #asm {
        mov stack:, rsp;
        add stack, 0x200;
        mov error_code, stack;
        add stack, 0x8;
        mov stack_data, stack;
    }

    push_context Context.{} {
        print("An exception has occurred:  ");
        print("Page fault\n\n", theme.accent);

        cr2: u64;
        #asm {
            get_cr2 cr2;
        }
        print("CR2 contains       "); print_hex(cr2); print(".\n");
        // print("VESA buffer        "); print_hex(cast(u64) graphics.vesa_framebuffer); print(".\n\n");
        // print("Last gotted page:  "); print_hex(last_gotted_page_frame); print(".\n");

        phys, present := get_physical_address(xx cr2);
        // if present {
        //     print("The page is present.\nIt is mapped to    "); print_hex(phys); print(".\n\n");
        // } else {
        //     print("The page is not present.\n\n");
        // }

        // print("The error code is  "); print_hex(cast(u32) << error_code); print(".\n");
        print("\nInterrupt frame:\n");
        print("RIP:    "); print_hex(stack_data.ip);    print("\n");
        // print("CS:     "); print_hex(stack_data.cs);    print("\n");
        print("FLAGS:  "); print_hex(stack_data.flags); print("\n");
        print("SP:     "); print_hex(stack_data.sp);    print("\n");
        // print("SS:     "); print_hex(stack_data.ss);    print("\n");

        paint_screen();
#asm { hlt; }

        #if PAGE_FAULT_STACK_TRACE {
            print("\nStack trace:\n");
            node := global_kernel_context.stack_trace;
            while node {
                if node.info != null {
                    print("In file \"");
                    print(node.info.location.fully_pathed_filename);
                    print("\" -> in proc \"");
                    print(node.info.name);
                    print("\" on line ");
                    print(node.line_number);
                    print("\n");
                }
    
                node = node.next;
            }
            paint_screen();
        }
    }

    #asm {
        add rsp, 0x200;
    }

    while true #asm { hlt; }
}



bitmap_space: [ONE_GB / 0x1000 / 64] u64;

#import "Bit_Array";
pm_bitmap: Bit_Array;

bitmap_entries_for_limit :: (limit: u64) -> u64 {
    return limit / 0x1000 / 64;
}

reserve_physical_region :: (base: u64, limit: u64) {
    if base > ONE_GB return;

    start_bit := base / 0x1000;
    end_bit := (base + limit) / 0x1000;

    for start_bit..end_bit {
        assert(pm_bitmap[xx it] == false);
        set_bit(*pm_bitmap, xx it);
    }
}

init_physical_allocator :: () {
    for 0..bitmap_entries_for_limit(0xa00_000) - 1 {
        bitmap_space[it] = 0xffff_ffff_ffff_ffff;
    }

    pm_bitmap.allocator.proc = (mode: Allocator_Mode, size: s64, old_size: s64, old_buffer: *void, user_data: *void) -> *void {
        return bitmap_space.data;
    };

    init_bit_array(*pm_bitmap, xx ONE_GB / 0x1000);
    lowest_free_bit = 0xa00_000 / 0x1000;
    memory_map := get_memory_map();

    for memory_map {
        if  it.type == .NONE continue;
        if  it.base < 0x100_000 continue;
        if (it.base % 0x1000 != 0) || (it.limit % 0x1000 != 0) continue;

        if  it.type != .AVAILABLE {
            reserve_physical_region(it.base, it.limit);
        }
    }
}

lowest_free_bit: u64;
last_gotted_page_frame: u64;

get_new_page_frame :: () -> u64 {
    address: u64;
    bit := lowest_free_bit;

    while true {
        if !pm_bitmap[xx bit] {
            address = bit * 0x1000;
            set_bit(*pm_bitmap, xx bit);
            break;
        }
        bit += 1;
    }

    lowest_free_bit = bit + 1;

    last_gotted_page_frame = address;

    memset(xx (address + VIRTUAL_MIRROR), 0, 0x1000);
    return address;
}

get_contiguous_page_frames :: (page_count: int) -> u64 {
    assert(xx page_count);
    bit := cast(int) lowest_free_bit;
    contiguous_bits_found: int;

    while true {
        if !pm_bitmap[xx bit] {
            contiguous_bits_found += 1;
        } else {
            contiguous_bits_found = 0;
        }
        bit += 1;

        if contiguous_bits_found == xx page_count {
            for bit - page_count..bit - 1 {
                set_bit(*pm_bitmap, xx it);
            }
            return cast(u64) (bit - contiguous_bits_found) * 0x1000;
        }
    }
    return 0;
}

release_page_frame :: (address: u64) {
    assert(address_is_page(address));

    bit := address / 0x1000;
    assert(pm_bitmap[xx bit]);
    clear_bit(*pm_bitmap, xx bit);

    if bit < lowest_free_bit {
        lowest_free_bit = bit;
    }
}




Executable_Format_Header :: struct {
    magic: int;
    input_parameter_count: int;
    type_table_offset: int;
    type_table_virtual_address: u64;
    elf_offset: int;
}

parameters_base_address: *void;

load_and_run_program :: (file: [] u8, parameters: .. Any) -> bool {
    if file.count < size_of(Executable_Format_Header) {
        printf("File is not an executable");
        return false;
    }

    header := cast(*Executable_Format_Header) file.data;
    if header.magic != 0xfeefeef00f00 {
        printf("File is not an executable");
        return false;
    }

    table_size := header.elf_offset - size_of(Executable_Format_Header);

    type_table: [] *Type_Info;
    type_table.count = header.input_parameter_count;
    type_table.data = xx 0xc_0000;

    memcpy(type_table.data, file.data + header.type_table_offset, table_size);

    if parameters.count < type_table.count {
        printf("There are not enough parameters provided for the program! Wanted %, got %.\n", type_table.count, parameters.count);
        return false;
    }

    if parameters.count > type_table.count {
        printf("There are too many parameters provided for the program! Wanted %, got %.\n", type_table.count, parameters.count);
        return false;
    }

    map_memory(0x1000, virtual_address = PROGRAM_PARAMETER_BASE_ADDRESS);
    defer unmap_memory(0x1000, PROGRAM_PARAMETER_BASE_ADDRESS);

    cursor: int;
    for type_table {
        if parameters[it_index].type.type != it.type {
            printf("Parameter % is of the wrong type!\nWanted %, got %.\n", it_index + 1, it.type, parameters[it_index].type.type);
            return false;
        }

        address := PROGRAM_PARAMETER_BASE_ADDRESS + cursor;
        memcpy(xx address, parameters[it_index].value_pointer, it.runtime_size);
        cursor += it.runtime_size;
    }

    elf_base := file.data + header.elf_offset;
    elf := cast(*Elf64_Ehdr) elf_base;
    using Page_Flags;

    for 0..elf.e_phnum - 1 {
        base := elf_base + elf.e_phoff;
        base += it       * elf.e_phentsize;
        header := cast(*Elf64_Phdr) base;

        if header.p_type != PT_LOAD  continue;

        flags := USER_SUPERVISOR | PRESENT | READ_WRITE;
        map_memory(xx header.p_memsz, header.p_vaddr, flags = flags);
        target := cast(*u8) header.p_vaddr;

        for 0..header.p_filesz-1 {
            target[it] = elf_base[header.p_offset + it];
        }

        for header.p_filesz..header.p_memsz-1 {
            target[it] = 0;
        }
    }

    tls := map_memory(0x4000);
    #asm FSGSBASE {
        wrfsbase tls;
    }

    entry_point := << cast(*() #no_context) *elf.e_entry;
    entry_point();

    unmap_memory(0x4000, xx tls);

    for 0..elf.e_phnum - 1 {
        base := elf_base  + elf.e_phoff;
        base += it        * elf.e_phentsize;
        header := cast(*Elf64_Phdr) base;

        if header.p_type != PT_LOAD  continue;
        unmap_memory(xx header.p_memsz, header.p_vaddr);
    }

    return true;
}

Syscall_Numbers :: enum {
    NONE             :: 0x00;
    MAP_MEMORY       :: 0x01;
    UNMAP_MEMORY     :: 0x02;
    WRITE_STRING     :: 0x03;
    READ_FILE        :: 0x04;
    WRITE_FILE       :: 0x05;
    CREATE_FILE      :: 0x06;
    STAT_FILE        :: 0x07;
    GET_MESSAGE      :: 0x08;
    CREATE_WINDOW    :: 0x09;
    CLOSE_WINDOW     :: 0x0a;
    REPAINT          :: 0x0b;
    GET_THEME        :: 0x0c;
    SET_THEME        :: 0x0d;
    INPUT            :: 0x0e;
    OUTPUT           :: 0x0f;
    READ_STRING      :: 0x10;
    LIST_DIRECTORY   :: 0x11;
    GET_TIME         :: 0x12;
}

#program_export
syscall_interrupt :: (data: *Interrupt_Data) #c_call {
    using Syscall_Numbers;
    syscall_context: Context;
    syscall_context.allocator.proc = allocate_memory;
    syscall_context.logger = log;
    syscall_context.assertion_failed = assertion_failed;

    push_context syscall_context {
        old := global_kernel_context;
        global_kernel_context = *context;
        defer global_kernel_context = old;

        if data.rax == xx WRITE_STRING {
            text: string;
            text.data = xx data.rbx;
            text.count = xx data.rcx;
            print(text);
//          paint_screen();
        }

        else if data.rax == xx READ_STRING {
            #asm { sti; }

            prompt: string;
            prompt.data = xx data.rbx;
            prompt.count = xx  data.rcx;

            clear_text_viewer(*shell.command_text);
            write_to_text_viewer(*shell.command_text, Basic.tprint("% > ", prompt));
            update_syntax_highlighting();

            while true {
                #asm { hlt; }
                handle_keyboard_events();

                result := shell_handle_keypress(true);
                if result != "" {
                    result.data += prompt.count + 1;
                    result.count -= prompt.count + 1;

                    data.rbx = xx result.data;
                    data.rcx = xx result.count;
                    break;
                }

                time := cmos_get_calendar_time();
                if xx (time.second % 2) == shell.command_text.point {
                    shell.command_text.point = !shell.command_text.point;
                    shell.command_text.draw.dirty = true;
                    paint_screen();
                }
            }
            #asm { cli; }
        }

        else if data.rax == xx OUTPUT {
            #import "Deep_Copy";

            allocator_data: struct {
                space: *void;
                watermark: int;
            }

            allocator_data.space = map_memory(0x10_000);
            context.allocator.proc = (mode: Allocator_Mode, size: s64, old_size: s64, old_buffer: *void, user_data: *void) -> *void {
                if mode != .ALLOCATE return null;

                data := cast(*type_of(allocator_data)) user_data;

                result := data.space + data.watermark;
                data.watermark += size;
                if data.watermark % 8 {
                    data.watermark += 8 - (data.watermark % 8);
                }

                assert(data.watermark < Shell.PIPE_SIZE);
                return result;
            };

            context.allocator.data = *allocator_data;
            ti := cast(*Type_Info) data.rcx;

            if ti.type == .ARRAY {
                shell.output_pipe.value.value_pointer = Deep_Copy(cast(*void) data.rbx, cast(*Type_Info) data.rcx);
                shell.output_pipe.value.type = Deep_Copy(cast(*void) data.rcx, type_info(Type_Info_Array));
            } else if ti.type == .STRUCT {
                shell.output_pipe.value.value_pointer = Deep_Copy(cast(*void) data.rbx, cast(*Type_Info) data.rcx);
                shell.output_pipe.value.type = Deep_Copy(cast(*void) data.rcx, type_info(Type_Info_Struct));
            } else if ti.type == .STRING {
                shell.output_pipe.value.value_pointer = Deep_Copy(cast(*void) data.rbx, cast(*Type_Info) data.rcx);
                shell.output_pipe.value.type = Deep_Copy(cast(*void) data.rcx, type_info(Type_Info_String));
            }
            context.allocator.proc = allocate_memory;
        }

        else if data.rax == xx INPUT {
            target := cast(*Any) data.rbx;
            << target = shell.input_pipe.value;
            shell.input_pipe.value = null;
        }

        else if data.rax == xx MAP_MEMORY {
            buffer := map_memory(xx data.rcx);
            << cast(**void) data.rbx = buffer;
        }

        else if data.rax == xx UNMAP_MEMORY {
            unmap_memory(xx data.rbx, xx data.rcx);
        }

        else if data.rax == xx GET_MESSAGE {
            result := cast(*Message) data.rbx;
            result.kind = .NONE;

            scan_code := read_key_buffer(*input_key_buffer);

            if scan_code != .NONE {
                result.kind = .KEYBOARD;
                result.keyboard_scan_code = xx scan_code;
                return;
            }

            mouse_event := read_event_buffer(*mouse.buffer);
            if mouse_event != .NONE {
                result.kind = .MOUSE;
                result.mouse_event = mouse_event;
            }
        }

        else if data.rax == xx CREATE_WINDOW {
            width := cast(int) data.rbx;
            height := cast(int) data.rcx;
            target := cast(**u32) data.rdx;

            paint_screen();
            shadow: *Solid_Color = map_memory(size_of(Solid_Color));
            blit: *Blitter = map_memory(size_of(Blitter));

            << shadow = .{};
            << blit = .{};

            add_screen_draw_list_entry(shadow, 0, 0, "window shadow");
            add_screen_draw_list_entry(blit, 0, 0, "window");

            blit.source_surface = create_surface(width, height);

            blit.draw.x = graphics.screen.width / 2 - width / 2;
            blit.draw.y = graphics.screen.height / 2 - height / 2;
            blit.draw.width = width;
            blit.draw.height = height;

            shadow.color.as_u32 = 0x181818;
            shadow.draw.target_rect = blit.draw.target_rect;
            shadow.draw.width += 4;
            shadow.draw.height += 4;

            << target = blit.source_surface.buffer;
        }

        else if data.rax == xx REPAINT {
            entry := graphics.draw_list;
            while entry {
                if entry.type == .BLITTER {
                    entry.dirty = true;
                    entry.prev.dirty = true;
                }
                entry = entry.next;
            }
            paint_screen();
        }

        else if data.rax == xx READ_FILE {
            name: string;
            name.data = xx data.rbx;
            name.count = xx data.rcx;

            file := read_file(name);
            target := cast(*[] u8) data.rdx;
            << target = file;
        }

        else if data.rax == xx WRITE_FILE {
            name:      string = << cast(*string) data.rbx;
            file_data: [] u8  = << cast(*[] u8)  data.rcx;
            write_file(name, file_data);
        }

        else if data.rax == xx CREATE_FILE {
            name: string = << cast(*string) data.rbx;
            create_file(name);
        }

        else if data.rax == xx LIST_DIRECTORY {
            name: string = << cast(*string) data.rbx;
            result := list_directory(name);
            data.rbx = xx result.data;
            data.rcx = xx result.count;
        }

        else if data.rax == xx GET_THEME {
            << cast(*Theme) data.rbx = theme;
        }

        else if data.rax == xx SET_THEME {
            old_theme := theme;
            theme = << cast(*Theme) data.rbx;
            shell.background.color = theme.background;
            shell.background.draw.dirty = true;

            for attr: 0..shell.text.attr_count - 1 {
                old_color := shell.text.attr_buffer[attr].color.as_u32;
                for old_theme.as_array {
                    if it.as_u32 == old_color {
                        shell.text.attr_buffer[attr].color.as_u32 = theme.as_array[it_index].as_u32;
                    }
                }
            }
            shell.text.draw.dirty = true;
        }

        else if data.rax == xx CLOSE_WINDOW {
            entry := graphics.draw_list;
            while entry {
                if entry.type == .BLITTER {
                    blit := cast(*Blitter) entry;
                    if blit.source_surface.buffer == xx data.rbx {
                        if entry.prev entry.prev.prev.next = entry.next;
                        if entry.next entry.next.prev = entry.prev.prev;

                        destroy_surface(*blit.source_surface);
                        unmap_memory(size_of(Blitter), xx entry);
                        unmap_memory(size_of(Solid_Color), xx entry.prev);
                        shell.background.draw.dirty = true;
                        shell.text.draw.dirty = true;
                        shell.command_text.draw.dirty = true;
                        return;
                    }
                }
                entry = entry.next;
            }
        }

        else if data.rax == xx GET_TIME {
            << cast(*Basic.Apollo_Time) data.rbx = get_system_time();
        }

        else assert(false);
    }
}

Message :: struct {
    kind: Message_Kind;
    using data: union {
        keyboard_scan_code: u16;
        mouse_event: Mouse_Event;
    };
}

Message_Kind :: enum {
    NONE;
    EXIT;
    KEYBOARD;
    MOUSE;
}

dont :: () #expand {
    #asm {
        cli;
        hlt;
    }
}
