
#### Current Jai version: 0.1.044

### Build

VirtualBox or physical hardware is recommended over QEMU for performance reasons.
You have to compile on linux. I usually compile in WSL and then run it on windows.
- Compile, build userspace, and create a floppy image for QEMU: `jai-linux first.jai - user`  
- Run in QEMU: `qemu-system-x86_64.exe disk_images/formosa.img -cpu qemu64,+popcnt,+bmi1,+fsgsbase`
- Compile, build userspace, and create a VDI for virtualbox: `jai-linux first.jai - vdi user`  
- Create a VirtualBox VM that has all the correct settings: `jai-linux first.jai - setup_vm`
- Run the created VirtualBox VM: `jai-linux first.jai - run_vm`

The `filesystem/` directory will be the root of the filesystem on the disk image. You can add files there if you want to access them from within the operating system. You can then use `jai-linux first.jai - no_kernel` to add them to the disk image without recompiling everything. You can also append `vdi` to this to have the new filesystem available in VirtualBox.
### Screenshot
![](screenshot.png)
