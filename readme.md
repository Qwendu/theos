
#### Current Jai version: 0.1.076




### Build

VirtualBox or physical hardware is recommended over QEMU for performance reasons.
You have to compile on linux. I usually compile in WSL and then run it on windows.
- Compile, build userspace, and create a bootable disk image: `jai-linux first.jai`  
- Create a VirtualBox VM that has all the correct settings: `jai first.jai - setup_vm`
- Run the created VirtualBox VM: `jai first.jai - run_vm`

(Use jai-linux for the last two if you're actually on linux rather than in WSL + Windows)

The `filesystem/` directory will be the root of the filesystem on the disk image. You can add files there if you want to access them from within the operating system. You can then use `jai-linux first.jai - no_kernel` to add them to the disk image without recompiling everything.

If you have questions or comments please message me on discord: dlandahl#8582

## Git Submodules

To get all the git submodules:
```
git submodule init
git submodule update --recursive
```

### Screenshot
![](screenshot.png)
