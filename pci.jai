
PCI_MAX_BUSES        :: 256;
PCI_MAX_DEVICES      :: 32;
PCI_NUM_FUNCTIONS    :: 8;
PCI_VENDOR_NO_DEVICE :: 0xffff;
PCI_HEADER_TYPE_MULTIFUNCTION_BIT :: 0x80;

Pci_Class_Code :: enum u8 {
    UNCLASSIFIED             :: 0x0;
    MASS_STORAGE             :: 0x1;
    NETWORK                  :: 0x2;
    DISPLAY_DEVICE           :: 0x3;
    MULTIMEDIA               :: 0x4;
    MEMORY_CONTROLLER        :: 0x5;
    BRIDGE                   :: 0x6;
    COMMUNICATION            :: 0x7;
    SYSTEM_PERIPHERAL        :: 0x8;
    INPUT_DEVICE             :: 0x9;
    DOCKING_STATION          :: 0xa;
    PROCESSOR                :: 0xb;
    SERIAL_BUS               :: 0xc;
    WIRELESS_CONTROLLER      :: 0xd;
}

Pci_Status :: enum_flags u16 {
    INTERRUPT_STATUS         :: 1 << 3;
    CAPABILITIES_LIST        :: 1 << 4;
    _66_MHZ_CAPABLE          :: 1 << 5;
    FAST_BACK_TO_BACK        :: 1 << 7;
    MASTER_DATA_PARITY_ERROR :: 1 << 8;
    DEVSEL_TIMING_A          :: 1 << 9;
    DEVSEL_TIMING_B          :: 1 << 10;
    SIGNALLED_TARGET_ABORT   :: 1 << 11;
    RECEIVED_TARGET_ABORT    :: 1 << 12;
    RECEIVED_MASTER_ABORT    :: 1 << 13;
    SIGNALLED_SYSTEM_ERROR   :: 1 << 14;
    DETECTED_PARITY_ERROR    :: 1 << 15;
}

Pci_Command :: enum_flags u16 {
    IO_SPACE                    :: 1 << 0;
    MEMORY_SPACE                :: 1 << 1;
    BUS_MASTER                  :: 1 << 2;
    SPECIAL_CYCLES              :: 1 << 3;
    MEMORY_WRITE_AND_INVALIDATE :: 1 << 4;
    VGA_PALETTE_SNOOP           :: 1 << 5;
    PARITY_ERROR_RESPONSE       :: 1 << 6;
    S_ERR_ENABLE                :: 1 << 8;
    FAST_BACK_TO_BACK_ENABLE    :: 1 << 9;
    INTERRUPT_DISABLE           :: 1 << 10;
}

Pci_Port :: enum {
    CONFIG_ADDRESS :: 0xcf8;
    CONFIG_DATA    :: 0xcfc;
}

Pci_Header :: struct {
    vendor_id:       u16;
    device_id:       u16;
    status:          Pci_Status;
    command:         Pci_Command;
    revision_id:     u8;
    prog_if:         u8;
    subclass:        u8;
    class_code:      Pci_Class_Code;
    cache_line_size: u8;
    latency_timer:   u8;
    header_type:     u8;
    bist:            u8;
}

pci_device_info: [PCI_MAX_BUSES * PCI_MAX_DEVICES] Pci_Device_Info;
pci_device_count: int;
pci_devices_scanned: bool;

Pci_Device_Info :: struct {
    bus: u32;
    index: u32;
    function: u32;
    header: Pci_Header;
}

pci_scan_all_devices :: () {
    if pci_devices_scanned return;
    host_controller := pci_read_header(0, 0, 0);

    if host_controller.header_type & PCI_HEADER_TYPE_MULTIFUNCTION_BIT {
        for bus: 0..PCI_NUM_FUNCTIONS - 1 {
            scan_bus(cast(u32) bus);
        }
    } else {
        scan_bus(0);
    }
    pci_devices_scanned = true;
}

scan_bus :: (bus: u32) {
    for device: 0..PCI_MAX_DEVICES-1 {
        header := pci_read_header(xx bus, xx device, 0);
        if header.vendor_id == PCI_VENDOR_NO_DEVICE continue;

        AddDevice(0);

        if header.header_type & PCI_HEADER_TYPE_MULTIFUNCTION_BIT {
            for function: 1..PCI_NUM_FUNCTIONS - 1 {
                header := pci_read_header(xx bus, xx device, xx function);
                if header.vendor_id == PCI_VENDOR_NO_DEVICE continue;

                AddDevice(function);

                if header.class_code == .BRIDGE && header.subclass == 4 {
                    bridge_info := pci_device_info[pci_device_count - 1];
                    register := pci_read_config_register(bridge_info, 0x6);
                    secondary_bus_number := (register >> 8) & 0xff;
                    scan_bus(secondary_bus_number);
                }
            }
        }
    }

    AddDevice :: (function: int) #expand {
        info: Pci_Device_Info = ---;
        info.bus       = xx `bus;
        info.index     = xx `device;
        info.function  = xx function;
        info.header    = `header; // `

        pci_device_info[pci_device_count] = info;
        pci_device_count += 1;
    }
}

pci_read_header :: (bus: u32, device: u32, function: u32) -> Pci_Header {
    pci_address: u32;
    pci_address |= function << 8;
    pci_address |= device   << 11;
    pci_address |= bus      << 16;
    pci_address |= 1        << 31;

    using Pci_Port;
    header: Pci_Header = ---;

    for 0..size_of(Pci_Header) / 4 - 1 {
        offset := cast(u32) it * 4;

        out(xx CONFIG_ADDRESS, pci_address | offset);
        register_value := in(xx CONFIG_DATA);

        << (cast(*u32) *header + it) = register_value;
    }
    return header;
}

pci_read_config_register :: (info: Pci_Device_Info, reg_index: u32) -> u32 {
    pci_address: u32;
    pci_address |= info.function << 8;
    pci_address |= info.index    << 11;
    pci_address |= info.bus      << 16;
    pci_address |= 1             << 31;

    using Pci_Port;
    offset := reg_index * 4;

    out(xx CONFIG_ADDRESS, pci_address | offset);
    return in(xx CONFIG_DATA);
}

pci_write_config_register :: (info: Pci_Device_Info, reg_index: u32, value: u32) {
    pci_address: u32;
    pci_address |= info.function << 8;
    pci_address |= info.index    << 11;
    pci_address |= info.bus      << 16;
    pci_address |= 1             << 31;

    using Pci_Port;
    offset := reg_index * 4;

    out(xx CONFIG_ADDRESS, pci_address | offset);
    out(xx CONFIG_DATA, value);
}

pci_get_base_address :: (info: Pci_Device_Info, bar: u32) -> base: u64, limit: u32, io_space: bool {
    assert(info.header.header_type != 0x2);

    bar0 := pci_read_config_register(info, bar + 0x4);

    io_space := cast(bool) (bar0 & 0b001);
    _64bit := !io_space && (bar0 & 0b100);

    mask: u64;
    if io_space mask = 0xfffffffc;
    else        mask = 0xfffffff0;

    base: u64 = bar0 & mask;
    if _64bit {
        bar1 := pci_read_config_register(info, bar + 0x5);
        base |= bar1 << 32;
    }

    pci_write_config_register(info, bar + 0x4, 0xffffffff);
    limit := pci_read_config_register(info, bar + 0x4);

    pci_write_config_register(info, bar + 0x4, bar0);

    limit = cast(u32) ~(limit & mask) + 1;
    return base, limit, io_space;
}

pci_print_device_list :: () {
    ti := type_info(Pci_Class_Code);

    Pci :: struct {
        Class: Pci_Class_Code;
        Subclass: string;
        Address: struct { bus, device, function: int; };
    }

    list: [..] Pci;

    context.print_style.default_format_struct.short_form_separator_between_fields = ":";
    context.print_style.default_format_struct.begin_string = "";
    context.print_style.default_format_struct.end_string = "";

    for 0..pci_device_count - 1 {
        device_info := pci_device_info[it];
        new := Basic.array_add(*list);
        new.Class = device_info.header.class_code;

        if new.Class < 0x10 {
            class := PCI_SUBCLASSES[new.Class];
            subclass := device_info.header.subclass;
            if subclass == 0x80 new.Subclass = "Other";
            else if class.count > subclass {
                new.Subclass = class[subclass];
            }
        }
        new.Address.bus = device_info.bus;
        new.Address.device = device_info.index;
        new.Address.function = device_info.function;
    }

    shell.input_pipe.value = cast([] Pci) list;
    print_pipe();
}



Mass_Storage_Device :: struct {
    controller_type: enum {
        INVALID :: 0x0;
        IDE     :: 0x1;
        AHCI    :: 0x2;
        NVME    :: 0x3;
    }

    supports_busmastering: bool;
    bus_master_base: u16;

    sector_size :: 512;
    sector_count: int;

    union {
        #as ide: Ide;
        #as ahci: Ahci;
    }

    Ide :: struct {
        device: Ide_Device_Type;
        io_base: u16;
        control_base: u16;
        model_string: [40] u8;
    }

    Ahci :: struct {
        command_list: *Ahci_Command_Table;
        received_fis: *Ahci_Received_Fis;
    }
}

disks: [] Mass_Storage_Device;

read_mass_storage :: (dev: *Mass_Storage_Device, buffer: *void, bytes: int, disk_address: int) {
    assert(dev.controller_type == .IDE);
    assert(dev.supports_busmastering);

    ide_bus_master_transfer(dev, .READ, xx buffer, xx bytes, xx disk_address);
}

write_mass_storage :: (dev: *Mass_Storage_Device, buffer: *void, bytes: int, disk_address: int) {
    assert(dev.controller_type == .IDE);
    assert(dev.supports_busmastering);

    ide_bus_master_transfer(dev, .WRITE, xx buffer, xx bytes, xx disk_address);
}



PCI_SUBCLASS_IDE  :: 0x1;
PCI_SUBCLASS_ATA  :: 0x5;
PCI_SUBCLASS_SATA :: 0x6;

identification_space: [128] u32;

discover_mass_storage_devices :: () {
    discovered: [..] Mass_Storage_Device;
    defer disks = discovered;

    for device: 0..pci_device_count - 1 {
        info := pci_device_info[device];
        if info.header.class_code != .MASS_STORAGE continue;

        // Subclass 0x1 (IDE) might be compatible with subclass 0x5 (ATA), but I am not sure
        if info.header.subclass == PCI_SUBCLASS_IDE {
            init_ide_controller(info, *discovered);
        }

        if info.header.subclass == PCI_SUBCLASS_SATA {
            init_ahci_controller(info, *discovered);
        }
    }
    // pic_enable_irq(.PRIMARY_ATA);
}

init_ide_controller :: (info: Pci_Device_Info, drives: *[..] Mass_Storage_Device) {
    prog_if := info.header.prog_if;

    // Detect bus mastering (DMA)
    bus_master_support := prog_if & 0x80 > 0;
    bus_master_base: u16;

    if bus_master_support {
        // Enable bus mastering
        command_status := pci_read_config_register(info, 0x1);
        pci_write_config_register(info, 0x1, command_status | xx Pci_Command.BUS_MASTER);

        base, limit, io_space := pci_get_base_address(info, bar = 4);

        assert(io_space);
        assert(limit == 16);

        bus_master_base = xx base;
    }

    // Scan the four drive slots of a standard IDE controller
    for channel: 0..1 {
        for device_type: Ide_Device_Type.[.MASTER, .SLAVE] {

            new: Mass_Storage_Device.Ide;

            if prog_if & (0x1 + 0x3 * channel) {
                base, limit, io_space := pci_get_base_address(info, bar = cast(u32) channel * 2);
                assert(io_space, "We don't support IDE controllers with memory mapped IO");
                new.io_base = xx base;

                base, limit, io_space = pci_get_base_address(info, bar = cast(u32) channel * 2 + 1);
                new.control_base = xx base;
            } else {
                new.io_base = 0x1f0 - 0x80 * cast(u16) channel;
                new.control_base = 0x3f6 - 0x80 * cast(u16) channel;
            }

            ide_write(*new, .DRIVE_SELECT, xx device_type);
            sleep(1);

            // IDENTIFY, to determine if the drive exists
            ide_write(*new, .COMMAND, Ide_Command.IDENTIFY);
            sleep(1);

            status := cast(Ide_Status) ide_read(*new, .STATUS);
            if status == .NONE continue; // A clear status register indicates there is no device here

            start := get_system_time();
            while true {
                if status & .ERROR continue device_type; // Not ATA, may be ATAPI, but we don't support it yet

                if !(status & .BUSY) && (status & .TRANSFER_REQUESTED) {
                    // Ready to transfer identification space in response to IDENTIFY
                    break;
                }

                elapsed := Basic.operator-(get_system_time(), start);
                assert(Basic.to_milliseconds(elapsed) < 1000, "ATA 'identify' timeout");

                status = xx ide_read(*new, .STATUS);
            }

            id := identification_space;
            for 0..id.count - 1 {
                id[it] = in(new.io_base + xx Ide_Register.DATA, u32);
            }

            // ATA strings flip each pair of bytes
            str := cast(*u8) id.data + 54;
            for 0..new.model_string.count / 2 - 1 {
                new.model_string[it * 2] = str[it * 2 + 1];
                new.model_string[it * 2 + 1] = str[it * 2];
            }

            msd := Basic.array_add(drives);
            msd.controller_type = .IDE;
            msd.ide = new;

            msd.sector_count = cast(int) id.data[30];
            assert(msd.sector_count > 0);

            msd.bus_master_base = bus_master_base + cast(u16) channel * 8;
            msd.supports_busmastering = bus_master_support;
        }
    }
}

Physical_Region_Descriptor :: struct {
    base: u32;
    byte_count: u16;
    end_of_table: enum u16 {
        NO  :: 0;
        YES :: 1 << 15;
    };
}

#assert(size_of(Physical_Region_Descriptor) == 8);

Ide_Transfer_Direction :: enum {
    READ;
    WRITE;
}

ide_bus_master_transfer :: (dev: *Mass_Storage_Device, direction: Ide_Transfer_Direction, memory_address: *void, number_of_bytes: u64, disk_address: u64, call_site := #caller_location) {
    assert(cast(u64) memory_address % 0x200 == 0);

    assert(dev.controller_type == .IDE);
    assert(dev.supports_busmastering);

    target, present := get_physical_address(memory_address);
    assert(present);
    sector_count : u64 = (number_of_bytes + 0x1ff) / 0x200;
    lba          : u64 = (disk_address    + 0x1ff) / 0x200;

    first_sector_count := (0x10_000 - target % 0x10_000) / 0x200;
    if first_sector_count > sector_count first_sector_count = sector_count;
    sector_count -= first_sector_count;

    ide_bus_master_transfer_sectors(dev, direction, target, cast(u32) lba, xx first_sector_count);
    lba += first_sector_count;
    target += first_sector_count * 0x200;

    while sector_count > 128 {
        ide_bus_master_transfer_sectors(dev, direction, target, cast(u32) lba, 128);
        target += 0x10_000;
        lba += 128;
        sector_count -= 128;
    }

    ide_bus_master_transfer_sectors(dev, direction, target, xx lba, xx sector_count);
}

ide_bus_master_transfer_sectors :: (dev: *Mass_Storage_Device, direction: Ide_Transfer_Direction, physical: u64, sector_lba: u32, sector_count: int) {
    using Ide_Register;
    using Pci_Bus_Master_Port;
    if !sector_count return;

    table: Physical_Region_Descriptor #align 8;
    table.base = cast(u32) physical;
    table.byte_count = 512 * cast(u16) sector_count;
    table.end_of_table = .YES;

    table_phys, present := get_physical_address(*table);
    assert(present);
    out(dev.bus_master_base + xx PRIMARY_PRD, cast(u32) table_phys);

    out(dev.bus_master_base + xx PRIMARY_COMMAND, cast(u8) 0);

    direction_bit := cast(u8) ifx direction == .READ then 0x8 else 0;
    out(dev.bus_master_base + xx PRIMARY_COMMAND, direction_bit);

    status := port_read(dev.bus_master_base + xx PRIMARY_STATUS);
    out(dev.bus_master_base + xx PRIMARY_STATUS, /* cast(u8) (status & ~(0x4 | 0x2)) */ cast(u8) 6);

    ide_write(dev, DRIVE_SELECT, (cast(u8) sector_lba >> 24) | 0xe0);

    ide_write(dev, DEVICE_CONTROL, 0x00);
    ide_write(dev, FEATURE, 0x00);
    ide_write(dev, SECTOR_COUNT, cast(u8) sector_count);

    ide_write(dev, LBA_LOW,  cast(u8) (sector_lba));
    ide_write(dev, LBA_MID,  cast(u8) (sector_lba >> 8));
    ide_write(dev, LBA_HIGH, cast(u8) (sector_lba >> 16));

    if direction == .READ {
        ide_write(dev, COMMAND, Ide_Command.READ_DMA);
    } else if direction == .WRITE {
        ide_write(dev, COMMAND, Ide_Command.WRITE_DMA);
    } else assert(false);

    start := get_system_time();
    while true {
        status := cast(Ide_Status) ide_read(dev, .STATUS);

        if status & .ERROR assert(false);

        if !(status & .BUSY) && (status & .TRANSFER_REQUESTED) {
            break;
        }

        elapsed := Basic.operator-(get_system_time(), start);
        assert(Basic.to_milliseconds(elapsed) < 1000, "ATA DMA read timeout");
    }

    out(dev.bus_master_base + xx PRIMARY_COMMAND, direction_bit | 0x1);

    start = get_system_time();
    while true {
        status := port_read(dev.bus_master_base + xx PRIMARY_STATUS);
        active    := (status & 1 > 0);
        interrupt := (status & 4 > 0);

        if (!active && interrupt) {
            port_write(dev.bus_master_base + xx PRIMARY_COMMAND, 0);
            break;
        }

        elapsed := Basic.operator-(get_system_time(), start);
        assert(Basic.to_milliseconds(elapsed) < 1000, "ATA DMA read timeout");
    }
}

#program_export
ata_interrupt :: () #c_call {
    pic_end_of_interrupt(.PRIMARY_ATA);
}

Pci_Bus_Master_Port :: enum {
    PRIMARY_COMMAND :: 0x0;
    PRIMARY_STATUS :: 0x2;
    PRIMARY_PRD :: 0x4;

    SECONDARY_COMMAND :: 0x8;
    SECONDARY_STATUS :: 0xa;
    SECONDARY_PRD :: 0xc;
}

Ide_Status :: enum_flags u8 {
    NONE                :: 0x0;
    ERROR               :: 0x1;
    INDEX               :: 0x2;
    CORRECTED_DATA      :: 0x4;
    TRANSFER_REQUESTED  :: 0x8;
    SEEK_COMPLETE       :: 0x10;
    DEVICE_FAULT        :: 0x20;
    READY               :: 0x40;
    BUSY                :: 0x80;
}

Ide_Error :: enum_flags {
    NONE                   :: 0x0;
    ADDRESS_MARK_NOT_FOUND :: 0x1;
    TRACK_ZERO_NOT_FOUND   :: 0x2;
    ABORTED                :: 0x4;
    MEDIA_CHANGE_REQUEST   :: 0x8;
    ID_NOT_FOUND           :: 0x10;
    MEDIA_CHANGED          :: 0x20;
    DATA_ERROR             :: 0x40;
    BAD_BLOCK              :: 0x80;
}

Ide_Register :: enum u16 {
    DATA          :: 0x0;
    FEATURE       :: 0x1;
    SECTOR_COUNT  :: 0x2;
    LBA_LOW       :: 0x3;
    LBA_MID       :: 0x4;
    LBA_HIGH      :: 0x5;
    DRIVE_SELECT  :: 0x6;
    COMMAND       :: 0x7;

    ERROR  :: 0x1;
    STATUS :: 0x7;

    DEVICE_CONTROL :: 0x0; // Offset from control base
}

Ide_Command :: enum u8 {
    READ_PIO  :: 0x20;
    READ_DMA  :: 0xc8;
    WRITE_PIO :: 0x30;
    WRITE_DMA :: 0xca;
    IDENTIFY  :: 0xec;
}

Ide_Device_Type :: enum {
    MASTER :: 0xa0;
    SLAVE :: 0xb0;
};

ide_write :: (dev: *Mass_Storage_Device.Ide, reg: Ide_Register, value: $T) {
    base := dev.io_base;
    if reg == .DEVICE_CONTROL base = dev.control_base;
    port_write(base + cast(u16) reg, value);
}

ide_read :: (dev: *Mass_Storage_Device.Ide, reg: Ide_Register) -> u8 {
    base := dev.io_base;
    return port_read(base + cast(u16) reg);
}    



/*
ata_await_transfer_request :: () {
    using Ide_Status;
    ata_wait();

    while true {
        status := cast(Ide_Status) port_read(ide.primary.io_base + xx Ide_Register.IN_STATUS);

        trq := status & TRANSFER_REQUESTED;
        bsy := status & BUSY;

        if trq && !bsy {
            break;
        }
    }
}

ata_get_error :: () -> Ide_Error {
    return xx port_read(ide.primary.io_base + xx Ide_Register.IN_ERROR);
}

ata_pio_start :: (start_sector: u32, sector_count: u8) {
    using Ide_Register;

    port_write(ide.primary.io_base + xx DRIVE_SELECT, cast(u8) (start_sector >> 24) | 0xe0);
    port_write(ide.primary.io_base + xx FEATURE, 0x00);
    port_write(ide.primary.io_base + xx SECTOR_COUNT, sector_count);

    port_write(ide.primary.io_base + xx LBA_LOW,  cast(u8) (start_sector));
    port_write(ide.primary.io_base + xx LBA_MID,  cast(u8) (start_sector >> 8));
    port_write(ide.primary.io_base + xx LBA_HIGH, cast(u8) (start_sector >> 16));
}

ata_pio_read :: (buffer: *u16, start_sector: u32, sector_count: u8) -> Ide_Error {
    using Ide_Register;
    ata_wait();

    ata_pio_start(start_sector, sector_count);
    port_write(ide.primary.io_base + xx COMMAND, Ide_Command.READ_PIO);
    ata_wait();

    count := ifx sector_count == 0 then 256 else sector_count;
    for sector: 0..count - 1 {
        print("R");
        ata_await_transfer_request();

        for 0..0x100 - 1 {
            buffer[it + 0x100 * sector] = in(ide.primary.io_base + xx DATA, u16);
        }
        ata_wait();
    }
    ata_wait();
    return ata_get_error();
}

ata_read :: (buffer: *u8, start_address: int, size_bytes: int) {
    sector_count := (size_bytes    + 0x1ff) / 0x200;
    start_lba    := (start_address + 0x1ff) / 0x200;

    num_reads_required := sector_count / 256;
    num_sectors_left   := sector_count % 256;

    for 0..num_reads_required-1 {
        lba_offset := 0x100 * it;
        ata_pio_read(xx (buffer + 0x200 * lba_offset), cast(u32) (start_lba + lba_offset), 0);
    }

    lba := 0x100 * num_reads_required;
    ata_pio_read(xx (buffer + 0x200 * lba), cast(u32) (start_lba + lba), xx num_sectors_left);
}

ata_pio_write :: (buffer: *u16, start_sector: u32, sector_count: u8) -> Ide_Error {
    using Ide_Register;

    ata_wait();
    ata_pio_start(start_sector, sector_count);
    port_write(ide.primary.io_base + xx COMMAND, Ide_Command.WRITE_PIO);

    ata_wait();
    count := ifx sector_count == 0 then 256 else sector_count;
    for sector: 0..count - 1 {
        ata_await_transfer_request();

        for 0..0x100 - 1 {
            out(ide.primary.io_base + xx DATA, buffer[it + 0x100 * sector]);
        }
        ata_wait();
    }
    ata_wait();
    return ata_get_error();
}
*/



SSTS_DET_ESTABLISHED :: 0x3;
SSTS_IPM_ACTIVE :: 0x1;

init_ahci_controller :: (info: Pci_Device_Info, drives: *[..] Mass_Storage_Device) {
    context.print_style.default_format_struct.use_newlines_if_long_form = true;

    // command_status := pci_read_config_register(info, 0x1);
    // command_status |= xx (Pci_Command.BUS_MASTER | .MEMORY_SPACE);
    // command_status &= xx ~.INTERRUPT_DISABLE;
    // pci_write_config_register(info, 0x1, xx command_status);

    // BARs 1 to 4 are used for IDE compatibility, 5 is the AHCI base address
    base, limit, io_space := pci_get_base_address(info, bar = 5);
    assert(base != 0);
    assert(!io_space);

    using Page_Flags;
    uncacheable_flags := READ_WRITE | PRESENT | CACHE_DISABLE;
    m := map_memory(limit + 0x1000, physical_address = base, flags = uncacheable_flags);
    offset_in_page := base % 0x1000;
    ahci: *Ahci_Memory_Region = xx (m + offset_in_page);

    cap := ahci.host_capabilities;

    ahci_only := cap & .SUPPORTS_AHCI_ONLY > 0;
    if !ahci_only {
        ahci.global_host_control |= 0x1;
    }

    num_ports := cast(int) (cap & 0b11111) + 1;
    command_slot_count := cast(int) ((cap >> 8) & 0b11111) + 1; // Can't bit shift by an enum value

    assert(cap & ._64BIT_ADDRESSING > 0, "AHCI controller without 64bit addressing not supported");

    for 0..num_ports - 1 {
        assert(ahci.ports_implemented & (1 << it) > 0, "Implemented AHCI ports are not contiguous");
        port := *ahci.ports[it];

        assert(port.command_status & .SPIN_UP > 0, "AHCI port not spun up");

        // Don't know what to do in case of staggered spin up
        // if ahci.host_capabilities & .STAGGERED_SPIN_UP > 0 {
        // }

        detection := port.sata_status & 0xf;
        power_mgmt := (port.sata_status >> 8) & 0xf;
        if detection != SSTS_DET_ESTABLISHED continue;
        assert(power_mgmt == SSTS_IPM_ACTIVE);

        assert(port.signature == .ATA, "AHCI: We only handle the \"ATA\" device signature");

        // Allocate received FIS and command list for this port
        dev: Mass_Storage_Device.Ahci;

        list_size := size_of(Ahci_Command_Header) * command_slot_count;
        dev.command_list == map_memory(list_size, flags = uncacheable_flags);
        dev.received_fis == map_memory(size_of(Ahci_Received_Fis), flags = uncacheable_flags);

        port.command_list_base = get_physical_address(dev.command_list);
        port.fis_base = get_physical_address(dev.received_fis);

        table_region: *Ahci_Command_Table = map_memory(size_of(Ahci_Command_Table) * command_slot_count);
        assert(xx table_region % 128 == 0);

        for 0..command_slot_count - 1 {
            header := cast(*Ahci_Command_Header) dev.command_list + it;
            header.command_table_base = xx (table_region + it);
        }

        using Ahci_Port_Command_Status;
        port.command_status |= START | FIS_RECEIVE_ENABLE;

        // Issue IDENTIFY
        fis: Ahci_Command_Fis;
        fis.command = xx Ide_Command.IDENTIFY;
        fis.flags = .IS_COMMAND;

        dev.command_list[0].fis = fis;

        assert(port.command_issue & 0x1 == 0);
        port.command_issue |= 0x1;

        // Read identification space

        msd := Basic.array_add(drives);
        msd.controller_type = .AHCI;
        msd.ahci = dev;
    }
}

Ahci_Command_Fis :: struct {
    fis_type: Fis_Type = .REGISTER_H2D;
    flags: enum u8 { NONE :: 0x0; IS_COMMAND :: 0x80; };
    command: u8;
    features_low: u8;
    lba_low: u8;
    lba_mid: u8;
    lba_high: u8;
    device: u8;
    lba_really_high: u8;
    lba_super_high: u8;
    lba_super_duper_high: u8;
    features_high: u8;
    sector_count_low: u8;
    sector_count_high: u8;
    icc: u8;
    control: u8;
    reserved: u32;
}

Ahci_Command_Header :: struct {
    flags: u16;
    prd_table_length: u16;
    prd_byte_count: u32;
    command_table_base: u64;
    reserved: [4] u32;
}

Ahci_Command_Table :: struct {
    fis: Ahci_Command_Fis;
    reserved_1: [0x40 - size_of(Ahci_Command_Fis)] u8;
    atapi: [0x10] u8;
    reserved_2: [0x30] u8;
}

Fis_Type :: enum u8 {
    INVALID      :: 0x0;
    REGISTER_H2D :: 0x27;
    REGISTER_D2H :: 0x34;
    DMA_ACTIVATE :: 0x39;
    DMA_SETUP    :: 0x41;
    DATA         :: 0x46;
    BIST         :: 0x58;
    PIO_SETUP    :: 0x5f;
    DEV_BITS     :: 0xa1;
}

Ahci_Received_Fis :: struct {
    dma_setup: struct {

        fis: [0x20] u8;
    };

    pio_setup: struct {

        fis: [0x20] u8;
    };

    d2h_register: Ahci_Command_Fis = .{
        fis_type = .REGISTER_D2H,
    };

    device_bits: u64;
    unknown: struct {
        fis: [64] u8;
    };

    reserved: [0x60] u8;
}

Ahci_Signature :: enum u32 {
    ATA   :: 0x0000_0101;
    ATAPI :: 0xeb14_0101;
    SEMB  :: 0xc33c_0101;
    PM    :: 0x9669_0101;
}

Ahci_Memory_Region :: struct {
    host_capabilities:     Ahci_Capabilities;
    global_host_control:   u32;
    interrupt_status:      u32;
    ports_implemented:     u32;
    version:               u32;
    ccc_control:           u32;
    ccc_ports:             u32;
    enclosure_mgmt_loc:    u32;
    enclosure_mgmt_ctl:    u32;
    ext_host_capabilities: u32;
    bios_handoff_ctl_stat: u32;

    reserved: [0xa0 - 0x2c] u8;
    vendor_specific: [0x100 - 0xa0] u8;

    /* #no_abc */ ports: [32] Port;

    Port :: struct {
        command_list_base: u64 #align 4;
        fis_base: u64 #align 4;
        interrupt_status: u32;
        interrupt_enable: u32;
        command_status: Ahci_Port_Command_Status;
        reserved: u32;
        task_file_data: u32;
        signature: Ahci_Signature; /* struct {
            // Why does the spec say the signature has this structure?
            sector_count: u8;
            lba_low: u8;
            lba_mid: u8;
            lba_high: u8;
        }; */

        sata_status: u32;
        sata_control: u32;
        sata_error: u32;
        sata_active: u32;
        command_issue: u32;
        sata_notif: u32;
        fis_based_switching_control: u32;
        device_sleep: u32;

        reserved_2: [0x70 - 0x48] u8;
        vendor_specific: [16] u8;
    }
}

#assert(size_of(Ahci_Command_Header) == 0x20);
#assert(size_of(Ahci_Command_Table) == 0x80);
#assert(size_of(Ahci_Memory_Region.Port) == 0x80);
#assert(size_of(Ahci_Received_Fis) == 0x100);
#assert(Ahci_Port_Command_Status.INTERFACE_COMMUNICATION_CONTROL_BIT3 == 0x8000_0000);

Ahci_Capabilities :: enum_flags u32 {
    PORT_COUNT_BIT0;
    PORT_COUNT_BIT1;
    PORT_COUNT_BIT2;
    PORT_COUNT_BIT3;
    PORT_COUNT_BIT4;
    EXTERNAL_SATA;
    ENCLOSURE_MGMT;
    CCC;
    COMMAND_SLOT_COUNT_BIT0;
    COMMAND_SLOT_COUNT_BIT1;
    COMMAND_SLOT_COUNT_BIT2;
    COMMAND_SLOT_COUNT_BIT3;
    COMMAND_SLOT_COUNT_BIT4;
    PARTIAL_STATE;
    SLUMBER_STATE;
    PIO_MULTIPLE_DRQ;
    FIS_BASED_SWITCHING;
    PORT_MULTIPLIER;
    SUPPORTS_AHCI_ONLY;
    RESERVED;
    INTERFACE_SPEED_BIT0;
    INTERFACE_SPEED_BIT1;
    INTERFACE_SPEED_BIT2;
    INTERFACE_SPEED_BIT3;
    COMMAND_LIST_OVERRIDE;
    ACTIVITY_LED;
    AGGRESSIVE_LINK_POWER_MGMT;
    STAGGERED_SPIN_UP;
    MECHANICAL_PRESENCE_SWITCH;
    S_NOTIFICATION_REGISTER;
    NATIVE_COMMAND_QUEUEUUEUEING;
    _64BIT_ADDRESSING;
}

Ahci_Port_Command_Status :: enum_flags u32 {
    START;
    SPIN_UP;
    POWER_ON;
    COMMAND_LIST_OVERRIDE;
    FIS_RECEIVE_ENABLE;
    RESERVED_BIT0;
    RESERVED_BIT1;
    RESERVED_BIT2;
    CURRENT_COMMAND_SLOT_BIT0;
    CURRENT_COMMAND_SLOT_BIT1;
    CURRENT_COMMAND_SLOT_BIT2;
    CURRENT_COMMAND_SLOT_BIT3;
    CURRENT_COMMAND_SLOT_BIT4;
    MECHANICAL_PRESENCE_SWITCH_STATE;
    FIS_RECEIVE_RUNNING;
    COMMAND_LIST_RUNNING;
    COLD_PRESENCE_STATE;
    PORT_MULTIPLIER_ATTACHED;
    HOT_PLUG_CAPABLE_PORT;
    MECHANICAL_PRESENSE_SWITCH_ATTACHED_TO_PORT;
    COLD_PRESENCE_DETECTION;
    EXTERNAL_SATA_PORT;
    FIS_BASED_SWITCHING_CAPABLE;
    AUTOMATIC_PARTIAL_TO_SLUMBER_TRANSITIONS_ENABLED;
    DEVICE_IS_ATAPI;
    DRIVE_LED_ON_ATAPI_ENABLE;
    AGGRESSIVE_LINK_POWER_MANAGEMENT_ENABLE;
    AGGRESSIVE_SLUMBER_AND_PARTIAL;
    INTERFACE_COMMUNICATION_CONTROL_BIT0;
    INTERFACE_COMMUNICATION_CONTROL_BIT1;
    INTERFACE_COMMUNICATION_CONTROL_BIT2;
    INTERFACE_COMMUNICATION_CONTROL_BIT3;
}



Hda :: struct {
    pci_info: Pci_Device_Info;
    mm: *u8;
    codec_bitmap: u16;
    command_buffer: *u32;
}

hda_read :: (hda: *Hda, reg: Hda_Register, $T: Type = u32) -> T {
    return << cast(*T) (hda.mm + cast(int) reg);
}

hda_write :: (hda: *Hda, reg: Hda_Register, value: $T) {
    << cast(*T) (hda.mm + cast(int) reg) = value;
}

hda_set_bit :: (hda: *Hda, reg: Hda_Register, bit: int) {
    register := cast(*u32) (hda.mm + cast(int) reg);
    << register |= xx (1 << bit);
}

hda_unset_bit :: (hda: *Hda, reg: Hda_Register, bit: int) {
    register := cast(*u32) (hda.mm + cast(int) reg);
    << register &= xx ~(1 << bit);
}

hda_discover :: () -> Pci_Device_Info, bool {
    assert(pci_devices_scanned);

    for 0..pci_device_count-1 {
        info := pci_device_info[it];
        if info.header.class_code == .MULTIMEDIA && info.header.subclass == 0x3 {
            return info, true;
        }
    }

    return .{}, false;
}

Hda_Register :: enum {
    GCTL      :: 0x08;
    WAKEEN    :: 0x0c;
    STATESTS  :: 0x0e;

    CORBLBASE :: 0x40;
    CORBUBASE :: 0x44;
    CORBWP    :: 0x48;
    CORBRP    :: 0x4a;
    CORBCTL   :: 0x4c;
    CORBSIZE  :: 0x4e;

    RIRBLBASE :: 0x50;
    RIRBUBASE :: 0x54;
    RIRBWP    :: 0x58;
    RIRBRP    :: 0x5a;
    RIRBCTL   :: 0x5c;
    RIRBSIZE  :: 0x5e;
}

hda_init :: (pci: Pci_Device_Info) {
    hda: Hda;

    base, limit, io_space := pci_get_base_address(pci, 0);
    assert(!io_space);
    assert(base > 0);
    assert(limit > 0);

    hda.mm = cast(*u8) map_memory(limit, physical_address = base);
    hda.command_buffer = map_memory(0x1000, flags = Page_Flags.PRESENT | .READ_WRITE | .CACHE_DISABLE);

    hda_set_bit(*hda, .GCTL, 1);
    gctl := hda_read(*hda, .GCTL);
    assert(!gctl);

    hda_set_bit(*hda, .GCTL, 0);
    while !gctl {
        gctl = hda_read(*hda, .GCTL);
    }

    // wait(100000);
    hda.codec_bitmap = hda_read(*hda, .STATESTS, u16);
    assert(hda.codec_bitmap > 0, "No codecs enumerated");

    {
        hda_unset_bit(*hda, .CORBCTL, 1);

        corbsize := hda_read(*hda, .CORBSIZE, u8);
        assert(corbsize >> 4 == 0b0100, "Large CORB size not supported");
        hda_set_bit(*hda, .CORBSIZE, 1);

        corb_base := hda.command_buffer;
        hda_write(*hda, .CORBLBASE, cast(u32)            corb_base);
        hda_write(*hda, .CORBUBASE, cast(u32) (cast(u64) corb_base) >> 32);

        hda_set_bit(*hda, .CORBRP, 15);
        hda_write(*hda, .CORBWP, cast(u16) 0);

        hda_set_bit(*hda, .CORBCTL, 1);
    }

    {
        hda_unset_bit(*hda, .RIRBCTL, 1);

        rirbsize := hda_read(*hda, .RIRBSIZE, u8);
        assert(rirbsize >> 4 == 0b0100, "Large RIRB size not supported");
        hda_set_bit(*hda, .RIRBSIZE, 1);

        rirb_base := hda.command_buffer + 256;
        hda_write(*hda, .RIRBLBASE, cast(u32)            rirb_base);
        hda_write(*hda, .RIRBUBASE, cast(u32) (cast(u64) rirb_base) >> 32);

        hda_set_bit(*hda, .RIRBWP, 15);
        hda_set_bit(*hda, .RIRBCTL, 1);
    }
}



PCI_SUBCLASSES :: ([] string).[
    .[
        "Non VGA Compatible Unclassified",
        "VGA Compatible Unclassified"
    ],
    .[
        "SCSI Bus Controller",
        "IDE Controller",
        "Floppy Disk Controller",
        "IPI Bus Controller",
        "RAID Controller",
        "ATA Controller",
        "Serial ATA Controller",
        "Serial Attached SCSI Controller",
        "Non-Volatile Memory Controller",
    ],
    .[
        "Ethernet Controller",
        "Token Ring Controller",
        "FFDI Controller",
        "ATM Controller",
        "ISDN Controller",
        "WorldFip Controller",
        "PICMG 2.14 Multi Computing Controller",
        "Infiniband Controller",
        "Fabric Controller",
    ],
    .[
        "VGA Compatible Controller",
        "XGA Controller",
        "3D Controller",
    ],
    .[
        "Multimedia Video Controller",
        "Multimedia Audio Controller",
        "Computer Telephony Device",
        "Audio Device",
    ],
    .[
        "RAM Controller",
        "Flash Controller",
    ],
    .[
        "Host Bridge",
        "ISA Bridge",
        "EISA Bridge",
        "MCA Bridge",
        "PCI-to-PCI Bridge",
        "PCMCIA Bridge",
        "NuBus Bridge",
        "CardBus Bridge",
        "RACEway Bridge",
        "PCI-to-PCI Bridge (Semi Transparent)",
        "InfiniBand-to-PCI Host Bridge",
    ],
    .[
        "Serial Controller",
        "Parallel Controller",
        "Multiport Serial Controller",
        "Modem",
        "IEEE 488.1/2 (GPIB) Controller",
        "Smart Card Controller",
    ],
    .[
        "Programmable Interrupt Controller",
        "DMA Controller",
        "Timer",
        "RTC Controller",
        "PCI Hot-Plug Controller",
        "SD Host Controller",
        "IOMMU",
    ],
    .[
        "Keyboard Controller",
        "Digitizer Pen",
        "Mouse Controller",
        "Scanner Controller",
        "Gameport Controller",
    ],
    .[
        "Generic",
    ],
    .[
        "386 Processor",
        "486 Processor",
        "Pentium",
        "Pentium Pro",
    ],
    .[
        "FireWire (IEEE 1394) Controller",
        "ACCESS Bus Controller",
        "SSA",
        "USB Controller",
        "Fibre Channel",
        "SMBus Controller",
        "InfiniBand Controller",
        "IPMI Interface",
        "SERCOS Interface (IEC 61491)",
        "CANbus Controller",
    ],
    .[
        "iRDA Compatible Controller",
        "Consumer IR Controller",
        "RF Controller",
        "Bluetooth Controller",
        "Broadband Controller",
        "Ethernet Controller (802.1a)",
        "Ethernet Controller (802.1b)",
    ],
    .[
        "I20",
    ],
    .[
        "Satellite TV Controller",
        "Satellite Audio Controller",
        "Satellite Voice Controller",
        "Satellite Data Controller",
    ],
    .[
        "Network and Computing Encryption/Decryption",
    ],
    .[
        "DPIO Modules",
        "Performance Counters",
    ],            
];
