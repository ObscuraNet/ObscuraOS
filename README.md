# ObscuraOS
An operating system for motion detection cameras build using Raspberry Pi CM4, and Raspberry Pi Camera modules.
Build system is buildroot, with a custom overlay to provide fail-safe firmware updates using 2 seperate boot/root partitions.
Not intended to store footage locally, but send the footage to a remote server for storage.

---

## System Information
- Static IP Address on end0 192.168.1.19
- DHCP on end0
- Set up for Raspberry Pi Camera V3 Currently (Working on Any FIrst Party Camera)

---

## Building ObscuraOS


### Setup Build System

```
git clone --recurse-submodules https://github.com/ObscuraNet/ObscuraOS.git
cd ObscuraOS
./setupBuildEnv.sh
```

### Building The Base Buildroot System

Due to the long build times of buildroot, I tend to do that first independant of the build system.

```

# Current Directory = ~/ObscuraOS/

#Since buildroot takes so long to build, we only want to rebuild from scratch if we are removing packages
#We moderate this by adding 'major.minor.patch' empty file in the output directory

touch output/0.0.1
cd buildroot


#The buildroot config sets the operating system, including any software we want installed in our OS
cp ../config/BUILDROOT.cfg .config


#The linux config sets how we want the kernel to be compiled
cp ../config/linux.config .


#The genimage config sets how we want the SD card image that buildroot ouputs.
#We only use this to set the size of the boot directory, having python on board means that we need
# A larger boot filesystem than buildroot includes by default
cp ../config/pi_stock_genimage.cfg.in  /board/raspberrypi/genimage.cfg.in


#We are using a specific version of the linux kernel(6.1.93), so this. (Plus Other Packages)
. utils/add-custom-hashes


# Build From Scratch
make clean all

```

### Building Our Custom Image

Once we have a buildroot system, the rest is relatively simple.
- If you don't want to rebuild buildroot from scratch, make sure you have a file x.y.z in output/ that matches the values in [/obscBuild.sh]
- Run `./obscBuild.sh`

The script will request sudo permissions at times, to copy folders.
Your output/ will contain a folder with a base install image and update package.
