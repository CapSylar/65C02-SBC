# 65C02 SBC  with Graphics #

65C02-SBC is as the name suggests a single board computer build with the 65C02 processor, a modified version of the original 6502 used to power many 70's and 80's computers and consoles like the Apple I and Nintendo Entertainement System.

The System consists of the a) the 65C02 along with its peripherals for general IO and Serial and b) a kind of PPU ( pixel processing unit ) that is memory mapped to the CPU. The PPU is implemented on an FPGA using Verilog.

Specifications: 65C02 running at 10Mhz,32KB of EEPROM, 16KB of RAM

<img src="/pictures/shematic.png">

<img src="/pictures/top_view.png">

# Table of Contents
- [65C02 SBC  with Graphics](#65c02-sbc--with-graphics)
- [Table of Contents](#table-of-contents)
- [65C02 SBC](#65c02-sbc)
  - [Software](#software)
    - [Using the Monitor](#using-the-monitor)
    - [Examining locations](#examining-locations)
    - [Writing into memory](#writing-into-memory)
    - [Additional features](#additional-features)
    - [Executing user programs](#executing-user-programs)
    - [Uploading using serial mode](#uploading-using-serial-mode)
  - [Hardware](#hardware)
    - [Components](#components)
    - [CPU memory map](#cpu-memory-map)
- [picoPPU](#picoppu)
  - [Specifications](#specifications)
  - [Memory Mapped registers](#memory-mapped-registers)
    - [PPUCTRL/PPUSTATUS](#ppuctrlppustatus)
    - [PPU_ADDRESS](#ppu_address)
    - [PPU_DATA](#ppu_data)
    - [OAM_ADDRESS](#oam_address)
    - [OAM_DATA](#oam_data)
    
    2. [Hardware/Board](#Hardware)
       1. [Components](#Components)
       2. [CPU memory map](#CPU-memory-map)
2. [Pico PPU](#picoPPU)
   1. [Specifications](#Specifications)
   2. [Memory Mapped registers](#Memory-Mapped-registers)
      1. [PPUCTRL/PPUSTATUS](#PPUCTRL/PPUSTATUS)
      2. [PPU_ADDRESS](#PPU_ADDRESS)  
      3. [PPU_DATA](#PPU_DATA)
      4. [OAM_ADDRESS](#OAM_ADDRESS)  
      5. [OAM_DATA](#OAM_DATA)
# 65C02 SBC
## Software

The SBC runs a heavily modified version of the original Apple I monitor program wr itten by Steve Wozniak. The program can examine memory locations and write to locations by specifying the byte either as hex or by giving the value directly. The latter mode is used to load already assembled programs onto the SBC via serial.

### Using the Monitor

Note that the `$` is equivalent to the linux `$` on the terminal.
### Examining locations

We type F0 for example

```
$F0
00F0: 55
$
```

We can also type several locations as such 
```
$F0 AA BA
00F0: 55
00AA: 55
00BA: 55
$
```

We can also list a memory block using the following syntax:
`START.END`

```
$00.0F
0000: 55 55 55 55 55 55 55 55
0008: 55 55 55 55 55 55 55 55
$
```
The monitor saves the last opened location such that syntax like the following is possible:
```
$00
0000: 55 ; $0000 now saved as last opened location
$.3
0001: 55 55 55 ; equivalent to $0001.$0003
```

### Writing into memory
To write into memory use the syntax `LOCATION:VALUE`
```
$00:FF
0000: 55

$00
0000: FF
$
```
As we can see the monitor prints what the location `$0000` contained before the write. After reading from the location again we can confirm that the value `$FF` was indeed written succesfully.

The syntax show below is valid as well:

```
$1000: A1 A2 A3 A4
```
This will write the bytes $A1 $A2 $A3 $A4 into succesive locations starting from $1000.

Using the fact that the monitor saves the last used location we can also break down long entries in the following way:

```
$1000: A1 A2

1000: 55
$:A3 A4
```
This is equivalent to ```$1000: A1 A2 A3 A4```

### Additional features

Commands such as the following are possible:
```
$1000 00.03 ff
1000: 55
0000: 55 55 55 55
00FF: 55 
```

### Executing user programs

To execute code on the SBC, we must tell the monitor to run code starting from a specific location:

```
$8000 R
```

the command above will make the SBC start executing code from location `$8000`. Note that after such a jump the SBC will be totally controlled by the other program.

### Uploading using serial mode

Finally, to upload new programs unto the SBC without having to write them manually using the STORE mode shown above or without having to re-program the ROM, the serial load block mode was introduced to circumvent this issue, we use the syntax <`START_LOCATION`>S<`NUMBER_BYTES`> to load bytes from serial and deposit them starting from the start location.This mode does not auto jump to the new location in case the user wants to inspect the data or in case he uses this mode to upload things other than programs.

```
$1000S7b
1000: 55
```
As with the other commands, the monitor starts by printing the contents of location `$1000` and then it enters listening mode. The monitor will not return to the normal `$` prompt until `7B` bytes have been sent. Note that the monitor will eco the bytes being sent.

## Hardware

### Components 

TODO: describe components 

### CPU memory map

| Locations   | Device |
| ----------- | -------- |
| $0000-$3fff      | RAM       |
| $4800-$4804 |      picoPPU           |
| $5000-$5003      | ACIA       |
| $6000-$600F      | VIA       |
| $8000-$ffff      | EEPROM   |
 

Note that the address decoding has been done to greatly simplify the logic used but it wastes a lot of space, in addition it is discouraged to write outside the indicated locations since the RAM/ACIA/VIA/picoPPU overlap at some intervals.

# picoPPU 

picoPPU is the pixel processing unit implemented on an FPGA attached to the SBC.

## Specifications 

picoPPU supports up to 64 sprites on the screen at any given time with a limit of 8 sprites per scanline. The design of the unit was heavily inspired by the inner workings of the NES PPU and like the latter, it has both Primary and Secondary OAM ( Object Attribute Memory ) acting as sprite buffers. picoPPU has no background rendering at the moment.

## Memory Mapped registers 

### PPUCTRL/PPUSTATUS
Writing to this port writes the contents to PPUCTRL.
Reading from this port reads the contents to PPUSTATUS.
### PPU_ADDRESS
Writing to this port sets the address at which the next write to PPU_DATA will happen. Internally, this register is 16 bits wide and required two writes to set the address, one write to set the high byte and one for the low byte.
### PPU_DATA 
A write to this register writes the contents to PPU memory at the 16-bit address specified by PPU_ADDRESS.
A read from this register reads the last written byte.
### OAM_ADDRESS
A write to this register sets the address at which the next write to OAM memory will occur.
A read from this register reads the last written byte.
### OAM_DATA 
A write to this register writes the contents to Primary OAM memory at the address specified by the OAM_ADDRESS register.
Internally, this register is 16 bits wide and thus requires two writes, one write to set the high byte and a second one for the low byte. The write is trigger at the second write.

| Register   | Size |
| ----------- | -------- |
| PPUCTRL/PPUCTRL      | 8 bits   |
| PPU_ADDRESS    | 16 bits  | 
| PPU_DATA      | 8 bits   | 
| OAM_ADDRESS      | 8 bits|
| OAM_DATA      | 16 bits |
