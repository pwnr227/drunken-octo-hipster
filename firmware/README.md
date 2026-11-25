# HX5 Firmware: Building and Flashing Klipper

HX5 runs stock Klipper on an STM32G0B1. No board-specific patches are needed. You choose USB or CAN when you
build the firmware. The board has hardware for both, but one firmware image uses only one of them.

## 1. Pick the host link

| Link | When to use it | Wiring |
|---|---|---|
| **USB** | HX5 sits next to the Pi/host | USB-C to the host. Leave JP1 (USB PWR) **open**, because the board takes power from 24 V |
| **CAN** | HX5 is remote (chamber, bed underside) or the host already has a CAN network | J3/J4 to the bus (CANH, CANL, GND). Fit JP2 (120 Ω) only if HX5 is at one end of the bus |

## 2. Optional: install the Katapult bootloader (recommended for CAN)

With Katapult installed, all later updates go over USB or CAN, and you never need the BOOT button again.

```bash
cd ~ && git clone https://github.com/Arksine/katapult && cd katapult
make menuconfig
```

| Option | Value |
|---|---|
| Micro-controller Architecture | STMicroelectronics STM32 |
| Processor model | STM32G0B1 |
| Build Katapult deployment application | Do not build |
| Clock Reference | 8 MHz crystal |
| Communication interface | `USB (on PA11/PA12)` **or** `CAN bus (on PB0/PB1)` |
| Application start offset | 8KiB offset |
| CAN bus speed (CAN only) | 1000000 |
| Support bootloader entry on rapid double click of reset button | ✔ |
| Enable Status LED | ✔, GPIO pin `PA15` |

Flash it over USB DFU. First fit JP1, or power the board from 24 V. Then hold **BOOT**, tap **RESET**, release **BOOT**:

```bash
make
lsusb | grep 0483:df11          # STM32 DFU device should be listed
sudo dfu-util -a 0 -D out/katapult.bin -s 0x08000000:mass-erase:force:leave
```

## 3. Build Klipper

```bash
cd ~/klipper && make menuconfig
```

| Option | Value |
|---|---|
| Enable extra low-level configuration options | ✔ |
| Micro-controller Architecture | STMicroelectronics STM32 |
| Processor model | STM32G0B1 |
| Bootloader offset | `8KiB bootloader` (with Katapult) or `No bootloader` |
| Clock Reference | 8 MHz crystal |
| Communication interface | `USB (on PA11/PA12)` **or** `CAN bus (on PB0/PB1)` |
| CAN bus speed (CAN only) | 1000000 (must match the host `can0` bitrate) |
| GPIO pins to set at micro-controller startup | `!PB10,!PB11,!PB12,!PB13,!PB14` (holds the heaters low from boot; the hardware pull-downs already do this, so it is belt-and-braces) |

```bash
make clean && make
```

## 4. Flash Klipper

**Without Katapult (USB DFU):** enter DFU mode with BOOT + RESET as above, then

```bash
make flash FLASH_DEVICE=0483:df11
```

**With Katapult over USB:**

```bash
python3 ~/katapult/scripts/flashtool.py -d /dev/serial/by-id/usb-katapult_stm32g0b1xx_<id>-if00 -f out/klipper.bin
```

**With Katapult over CAN:**

```bash
python3 ~/katapult/scripts/flashtool.py -i can0 -q                       # find the UUID
python3 ~/katapult/scripts/flashtool.py -i can0 -u <uuid> -f out/klipper.bin
```

## 5. Find the board from the host

```bash
ls /dev/serial/by-id/                                             # USB: usb-Klipper_stm32g0b1xx_<id>-if00
~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0    # CAN: prints canbus_uuid
```

Host `can0` setup, if you don't have it already (`/etc/network/interfaces.d/can0`):

```
allow-hotplug can0
iface can0 can static
    bitrate 1000000
    up ip link set $IFACE txqueuelen 128
```

## 6. Add the config

Copy [hx5.cfg](hx5.cfg) next to `printer.cfg`, set `serial:` or `canbus_uuid:` in it, and add

```ini
[include hx5.cfg]
```

Then PID-tune each zone with its real heater and load attached:

```
PID_CALIBRATE HEATER=hx5_zone0 TARGET=80
SAVE_CONFIG
```

## 7. Bring-up checklist

1. Fuses **out**, 24 V on, and nothing smoking. Measure the test points: +12V, +5V, +3V3 (±3 %).
2. Connect USB/CAN and check that Klipper connects. In Mainsail/Fluidd, `hx5_vin` should read about 24 V and
   `hx5_mcu` should read room temperature.
3. With every thermistor connector open, the zones should read **below** `min_temp`, and Klipper should shut down
   with "ADC out of range". That is expected. Plug a thermistor in and check it reads room temperature.
4. Open the interlock (J5), and Klipper should emergency-stop with "HX5 heater interlock opened". Close it again.
5. Fit one fuse, with a heater attached to that channel. Set a 40 °C target and check that the channel LED lights
   and the temperature rises. Repeat for each channel.
6. Run all five zones at 100 % for 15 minutes and check that `hx5_board` stays below 60 °C.
