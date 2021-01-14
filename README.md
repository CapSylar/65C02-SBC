# 65C02 SBC  with Graphics #

65C02-SBC is as the name suggests a single board computer build with the 65C02 processor, a modified version of the original 6502 used to power many 70's and 80's computers and consoles like the Apple I and Nintendo Entertainement System.

The System consists of the a) the 65C02 along with its peripherals for general IO and Serial and b) a kind of PPU ( pixel processing unit ) that is memory mapped to the CPU. The PPU is implemented on an FPGA using Verilog.

Specifications: 65C02 running at 10Mhz,32KB of EEPROM, 16KB of RAM
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
As we can see the monitor printed what the location `$0000` contained before the write, and after reading from the location again we can confirm that the value `$FF` was indeed written succesfully.

The syntax show below is valid as well:

```
$1000: A1 A2 A3 A4
```
This will write the bytes $A1 $A2 $A3 $A4 into succesive locations starting from $1000.

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

## Hardware

### CPU memory map

| Locations   | Device |
| ----------- | -------- |
| $0000-$3fff      | RAM       |
| $5000-$5003      | ACIA       |
| $6000-$600F      | VIA       |
| $8000-$ffff      | EEPROM   |
|
 

Note that the address decoding has been done to greatly simplify the logic used but it wastes a lot of space, in addition it is discouraged to write outside the indicated locations since the RAM/ACIA/VIA overlap at some intervals.