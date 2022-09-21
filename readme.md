
### Get it running

You have to set USE_SIMD in Basic/Print.jai to false. I do not know why. You can make a copy of Basic in theos/modules so that you don't have to modifiy the module globally.

If the VM, emulator, or physical hardware that you are using reports that "No appropriate VESA mode was found", you can go into config.jai and try different resolution values. This requires that you recompile. 1024x768 is a good bet, but a lot of modern hardware should support stuff like 1920x1080. The DEPTH value should stay the same (32), because the renderer doesn't currently support output formats other than 0x00rrggbb.

By default, the build program outputs a raw floppy bootable disk image. To run on VirtualBox, you can get the metaprogram to output a virtual hard disk. You just need to append "-- vdi" to the build command (for example: `jai-linux first.jai -import_dir modules -- vdi`). After doing this, you can remove the old (stale) VDI and insert the new one by running with the "-- vbox" flag. This assumes that there's a virtual machine called "theos" visible to VirtualBox, that has a PIIX4 controller on it. These two commands are separate because you might want to compile in WSL but have your VM on Windows.

Qemu might be easier to get started with than VirtualBox. I use the Qemu command "qemu-system-x86_64.exe theos -cpu qemu64,+popcnt,+bmi1,+fsgsbase". The extra flags are required to run the chess game.

#### Current Jai version: 0.1.038

## Features
- Structured shell that can manipulate typed data
- Custom executable format that supports typechecked and autocompleteable command line parameters
- Custom filesystem with apollo-time timestamps
- Many apps like chess and text editing

## Compile and run
You have to set USE_SIMD in Basic/Print.jai to false. I do not know why. You can make a copy of Basic in theos/modules so that you don't have to modifiy the module globally.

Compile, build userspace, and create a floppy image for QEMU: `jai-linux first.jai -import_dir modules -- user`  
Compile, build userspace, and create a VDI for virtualbox: `jai-linux first.jai -import_dir modules -- vdi user`  
To run in QEMU: `qemu-system-x86_64.exe theos -cpu qemu64,+popcnt,+bmi1,+fsgsbase`

If the VM, emulator, or physical hardware that you are using reports that "No appropriate VESA mode was found", you can go into config.jai and try different resolution values. This requires that you recompile. 1024x768 is a good bet

If VirtualBox says that the disk is "inaccessible", you can try running `jai-linux first.jai -import_dir modules --vbox` as long as your vm is called "theos" and you're using a PIIX4 controller

## Screenshot
![](screenshot.png)
