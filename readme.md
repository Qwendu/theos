
#### Current Jai version: 0.1.044

## Features
- Structured shell that can manipulate typed data
- Custom executable format that supports typechecked and autocompleteable command line parameters
- Custom filesystem with apollo-time timestamps
- Cooperative multitasking (will do preemptive multitasking in the future)
- Runs on real hardware

## Compile and run

You have to compile on linux. I usually compile in WSL and then run it on windows. It's easy to do this with the below commands

#### VirtualBox or physical hardware is recommended over QEMU for performance reasons

Compile, build userspace, and create a floppy image for QEMU: `jai-linux first.jai - user`  
Compile, build userspace, and create a VDI for virtualbox: `jai-linux first.jai - vdi user`  
To run in QEMU: `qemu-system-x86_64.exe formosa.img -cpu qemu64,+popcnt,+bmi1,+fsgsbase`

To create a VBox VM that has all the correct settings: `jai-linux first.jai - setup_vm`
To run the created VBox VM: `jai-linux first.jai - vbox`

If the VM, emulator, or physical hardware that you are using reports that "No appropriate VESA mode was found", you can go into config.jai and try different resolution values. This requires that you recompile. 1024x768 is a good bet

## Screenshot
![](screenshot.png)
