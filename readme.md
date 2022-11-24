
#### Current Jai version: 0.1.044

## Features
- Structured shell that can manipulate typed data
- Custom executable format that supports typechecked and autocompleteable command line parameters
- Custom filesystem with apollo-time timestamps
- Cooperative multitasking (will do preemptive multitasking in the future)
- Runs on real hardware

## Compile and run

### VirtualBox or physical hardware is recommended over QEMU for performance reasons

Compile, build userspace, and create a floppy image for QEMU: `jai-linux first.jai -import_dir modules -- user`  
Compile, build userspace, and create a VDI for virtualbox: `jai-linux first.jai -import_dir modules -- vdi user`  
To run in QEMU: `qemu-system-x86_64.exe formosa -cpu qemu64,+popcnt,+bmi1,+fsgsbase`

If the VM, emulator, or physical hardware that you are using reports that "No appropriate VESA mode was found", you can go into config.jai and try different resolution values. This requires that you recompile. 1024x768 is a good bet

If VirtualBox says that the disk is "inaccessible", you can try running `jai-linux first.jai -import_dir modules -- vbox` as long as your vm is called "formosa" and you're using an AHCI controller

## Screenshot
![](screenshot.png)
