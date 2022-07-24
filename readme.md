
### Features
 - Play against a strong chess AI, written in Jai by DanielTan (thanks for letting me use it)
 - Custom file system which uses Apollo Time for created/modified time stamps
 - Custom executable format that supports typechecked parameters for programs using Jai type reflection (Type_Info)
 - Structured shell, programs communicate using typed / structured data, also using Type_Info

### Get it running

If the VM, emulator, or physical hardware that you are using reports that "No appropriate VESA mode was found", you can go into config.jai and try different resolution values. This requires that you recompile. 1024x768 is a good bet, but a lot of modern hardware should support stuff like 1920x1080. The DEPTH value should stay the same (32), because the renderer doesn't currently support output formats other than 0x00rrggbb.

By default, the build program outputs a raw floppy bootable disk image. To run on VirtualBox, you can get the metaprogram to output a virtual hard disk. You just need to append "-- vdi" to the build command (for example: `jai-linux first.jai -import_dir modules -- vdi`). After doing this, you can remove the old (stale) VDI and insert the new one by running with the "-- vbox" flag. This assumes that there's a virtual machine called "theos" visible to VirtualBox, that has a PIIX4 controller on it. These two commands are separate because you might want to compile in WSL but have your VM on Windows.

Qemu might be easier to get started with than VirtualBox. I use the Qemu command "qemu-system-x86_64.exe theos -cpu qemu64,+popcnt,+bmi1,+fsgsbase". The extra flags are required to run the chess game.

#### Current Jai version: 0.1.032

![](screenshot.png)
