---
title: "Flash Elite C bootloader on Helix Keyboard"
date: 2021-05-30T00:22:27+01:00
draft: true
---

I've been running a Helix keyboard as my daily driver for the last year and have been loving it so far, unfortunately for the last couple of months I've had a bootloader issue that mean't I could no longer flash the firmware and customise the keymap. A lot of the guidance wasn't super useful on this but I managed to stumble my way into a solution which may help others in the same situation.

For reference I'm using Elite-C v3 on the helix board purchased from mechboards.co.uk around april of 2020

I would get the following error message when trying to run

{{< highlight bash >}}
bash -> qmk flash
...
Bootloader Version: 0x00 (0)
Erasing flash...  Success
Checking memory from 0x0 to 0x6FFF...  Not blank at 0x1.
0%                            100%  Programming 0x5F00 bytes...
[>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>]  Success
0%                            100%  Reading 0x7000 bytes...
[>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>]  Success
Validating...  ERROR
24231 invalid bytes in program region, 4335 outside region.
FAIL
Memory did not validate. Did you erase?
{{</highlight>}}

Most posts in github issues and stack overflow suggested that the bootloader was corrupted and would need to be reflashed, I found this guide https://beta.docs.qmk.fm/using-qmk/guides/keyboard-building/isp_flashing_guide on QMK which was moderately helpful but didn't work for me as I used a arduino UNO as an isp flash tool and this didn't show up in qmk toolbox.

This did help me figure out some keywords I needed though, I also noticed the acronym ICSP was on my helix board with some bare bins for soldering a header to.

![Image of helix keyboard displaying ICSP silkscreen on board](/helix-icsp.jpg)

I found the pinout of the ICSP header using a multimeter and the pinout I found on [Deskthority](https://deskthority.net/wiki/Elite-C#Pinout). The right side of the board had the following ICSP pinout tested using a multimeter.

{{< highlight bash >}}

RIGHT SIDE OF HELIX, WHEN VIEWED FROM THE FRONT

MISO SCLK RESET
VCC MOSI GROUND
{{</highlight>}}

I could then use an ISP [flashing guide](https://schou.dk/linux/arduino/isp/) to find the matching pins on an arduino UNO and burn a new bootloader onto the board.

Something to additionally note is that you may have to change your qmk firmware to use caterina instead of dfu-programmer. In rules.mk

{{< highlight c >}}
#BOOTLOADER = dfu-programmer
BOOTLOADER = caterina
{{</highlight>}}

Then flash your keyboard again using qmk flash and you should be back up and running once again