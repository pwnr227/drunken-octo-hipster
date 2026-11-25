# HX5 Schematic (rev A)

This is the schematic written out in text, one sheet per section, ready for capture in KiCad. Reference
designators match [../bom/HX5-BOM.csv](../bom/HX5-BOM.csv). Net names are in `CAPS`. Every channel `n`
runs from 0 to 4.

Global nets: `VIN_RAW` (after the connector), `VIN` (after reverse-polarity protection), `+12V`, `+5V`,
`+3V3`, `+3V3A` (filtered analog), `GND` (one ground plane; see the layout notes for the star point between
power ground and analog ground).

---

## Sheet 1: Power input and protection

| Ref | Part | Connections |
|---|---|---|
| J1 | XT90PW-M | `+` → `VIN_RAW`, `−` → `GND` |
| Q1, Q2 | BSC016N06NS (60 V, 1.6 mΩ), in parallel | S → `VIN_RAW`, D → `VIN`, G → `RP_GATE` (the body diode conducts from input to output) |
| U1 | LM74700-Q1 ideal-diode controller | ANODE → `VIN_RAW`, CATHODE → `VIN`, GATE → `RP_GATE`, VCAP → C7 (100 nF to ANODE), EN → `VIN_RAW` via R1 (100 kΩ), GND → `GND` |
| D1 | SMDJ33A, 33 V unidirectional TVS (3 kW) | `VIN` → `GND` (on the protected side, so a reversed input cannot forward-bias it) |
| C1, C2 | 330 µF 50 V low-ESR electrolytic | `VIN` → `GND` |
| C3–C6 | 4.7 µF 50 V X7R 1210 | `VIN` → `GND`, placed at the heater FET bank |
| F6 | 2 A 1206 fast fuse | `VIN` → `VIN_LOGIC` (feeds both bucks, so the logic rails are protected separately) |
| D2 | Green LED + R2 10 kΩ 0805 | `VIN` → `GND` (VIN present) |

## Sheet 2: Logic power

**U2: 12 V buck, LMR33630ADDA (400 kHz, 3 A)**

| Pin | Net / part |
|---|---|
| VIN | `VIN_LOGIC`, with C10 10 µF 50 V 1210 + C11 100 nF 50 V right at the pin |
| EN | `VIN_LOGIC` (always on) |
| CBOOT–SW | C12 100 nF |
| SW | L1 15 µH (≥3 A sat, e.g. Würth 74439346150) → `+12V` |
| FB | R10 100 kΩ (to `+12V`) / R11 9.09 kΩ (to GND) → 12.0 V |
| VCC | C13 1 µF |
| PG | NC |
| Output | C14, C15 22 µF 25 V 1210 X7R |

**U3: 5 V buck, LMR33620ADDA (400 kHz, 2 A)**

Same layout as U2: C20/C21 input, C22 CBOOT, L2 10 µH, R12 100 kΩ / R13 24.9 kΩ → 5.02 V, C23 VCC,
C24–C26 22 µF 16 V output → `+5V`.

**U4: 3.3 V LDO, AP2112K-3.3 (600 mA)**

`+5V` → VIN and EN; VOUT → `+3V3`. C30 1 µF in, C31 1 µF + C32 10 µF out.

| Ref | Part | Connections |
|---|---|---|
| D3 | BZT52C3V6 zener | `+3V3` → `GND`. It absorbs back-feed current if a thermistor wire shorts to VIN with the PT1000 jumper fitted |
| FB1 | Ferrite bead, 600 Ω @ 100 MHz, 0603 | `+3V3` → `+3V3A` |
| C33, C34 | 1 µF + 100 nF | `+3V3A` → `GND` (at VDDA) |
| D4 | SS14 Schottky | `VBUS_SW` → `+5V` |
| JP1 | 2-pin jumper "USB PWR" | `VBUS` ↔ `VBUS_SW`. Fit it only for bench flashing without 24 V. Leave it **open** in the machine |
| D5 | Blue LED + R3 2.2 kΩ | `+3V3` → `GND` (3V3 power LED) |

## Sheet 3: MCU

**U5: STM32G0B1CBT6 (LQFP-48)**

| Pin | Net | Notes |
|---|---|---|
| PA0 | `TH0_ADC` | ADC_IN0 |
| PA1 | `TH1_ADC` | ADC_IN1 |
| PA2 | `TH2_ADC` | ADC_IN2 |
| PA3 | `TH3_ADC` | ADC_IN3 |
| PA4 | `TH4_ADC` | ADC_IN4 |
| PA5 | `BOARD_NTC` | ADC_IN5, on-board NTC near the FET bank |
| PA6 | `VIN_SENSE` | ADC_IN6, VIN divided by 11 |
| PA7 | `FAN1` | TIM3_CH2 / TIM14_CH1 (hardware PWM capable) |
| PA9 | `AUX1` | to J7 |
| PA10 | `AUX2` | to J7 |
| PA11 | `USB_DM` | |
| PA12 | `USB_DP` | |
| PA13 | `SWDIO` | to J6 |
| PA14-BOOT0 | `SWCLK` | to J6. R20 10 kΩ pull-down; SW2 (BOOT) to `+3V3` |
| PA15 | `STATUS_LED` | R21 1 kΩ → D6 (green) → GND |
| PB0 | `CAN_RX` | FDCAN1_RX, Klipper option "CAN bus (on PB0/PB1)" |
| PB1 | `CAN_TX` | FDCAN1_TX |
| PB2 | `IL_SENSE` | interlock state (high = closed/OK) |
| PB9 | `FAN0` | TIM17_CH1 |
| PB10 | `HE0` | heater 0 drive |
| PB11 | `HE1` | heater 1 drive |
| PB12 | `HE2` | heater 2 drive |
| PB13 | `HE3` | heater 3 drive |
| PB14 | `HE4` | heater 4 drive |
| PF0-OSC_IN / PF1-OSC_OUT | Y1 | 8 MHz crystal (ABM8-8.000MHZ-B2-T, CL = 8 pF) with C40/C41 12 pF |
| NRST | `NRST` | C42 100 nF to GND, SW1 (RESET) to GND, to J6 |
| VDD/VDDIO | `+3V3` | C43 4.7 µF + C44 100 nF |
| VDDA/VREF+ | `+3V3A` | C33/C34 (Sheet 2) |
| VSS | `GND` | |

Unused pins (PA8, PB3–PB8, PB15, PC6, PC13–15, PD0–PD3) stay unconnected. PA8, PB15, PB4, PB6 and PD0/PD2 are
**kept off all functional nets on purpose**. They carry the G0B1 UCPD dead-battery pull-downs or alternate
functions, which could otherwise load a heater or thermistor pin at reset.

**USB (J2, USB-C 16-pin receptacle)**

| Pin | Connection |
|---|---|
| VBUS | `VBUS` (→ JP1 only; it does not power the board by default) |
| CC1, CC2 | R22, R23 5.1 kΩ each to GND (UFP / sink) |
| D+ (A6/B6) | `USB_DP` via U6 USBLC6-2SC6 |
| D− (A7/B7) | `USB_DM` via U6 |
| GND, shell | `GND`. Shell to GND through R24 1 MΩ ‖ C45 4.7 nF |

The STM32G0 USB has an internal 1.5 kΩ D+ pull-up, so no external resistor is needed.

**SWD header J6 (1×5, 2.54 mm):** 1 `+3V3`, 2 `SWDIO`, 3 `SWCLK`, 4 `NRST`, 5 `GND`.
**AUX header J7 (1×4):** 1 `+3V3`, 2 `AUX1`, 3 `AUX2`, 4 `GND`.

## Sheet 4: CAN bus

| Ref | Part | Connections |
|---|---|---|
| U7 | TJA1051T/3 (SO-8) | 1 TXD ← `CAN_TX`; 2 GND; 3 VCC ← `+5V` (C50 100 nF); 4 RXD → `CAN_RX`; 5 VIO ← `+3V3` (C51 100 nF); 6 CANL → `CANL`; 7 CANH → `CANH`; 8 S → GND (normal mode) |
| D7 | PESD2CAN (SOT-23) | `CANH`, `CANL` → GND |
| R30 + JP2 | 120 Ω 0805, in series with a 2-pin jumper "CAN TERM" | `CANH` ↔ `CANL`. Fit the jumper only if HX5 is the last node on the bus |
| J3, J4 | JST-XH 3-pin, wired in parallel | 1 `CANH`, 2 `CANL`, 3 `GND` (daisy-chain in/out) |

The CAN connectors carry **no power**. HX5 always takes its power from J1.

## Sheet 5: Thermistor inputs (×5, n = 0..4)

```
 +3V3A ──┬── R4n  4.7 kΩ 0.1 % 25 ppm ──┬──────────────┐
         │                              │              │
         └── R5n 1.27 kΩ 0.1 % ── JP_n ─┤   THn_EXT    R6n 10 kΩ
              (PT1000 select)           │              │
                         J2n pin 1 ─────┘              ├──── THn_ADC ──► MCU PA[n]
                         J2n pin 2 ── GND              │
                                                C6n 100 nF C0G/X7R ── GND
                                                D6n BAT54S: THn_ADC clamped to +3V3A / GND
```

| Ref (n = 0..4) | Part |
|---|---|
| J20–J24 | JST-XH 2-pin, B2B-XH-A |
| R40–R44 | 4.7 kΩ 0.1 % 0805 (Klipper `pullup_resistor: 4700`) |
| R50–R54 | 1.27 kΩ 0.1 % 2010 thin film (0.4 W, sized for the VIN-short fault). In parallel with 4.7 kΩ this gives 999.8 Ω (`pullup_resistor: 1000`) |
| JP10–JP14 | 2-pin jumper "PT1000". Open for NTC (default), fitted for PT1000 |
| R60–R64 | 10 kΩ 1 % 0603, series fault protection and RC filter |
| C60–C64 | 100 nF 0603, filter cap at the MCU pin |
| D60–D64 | BAT54S, clamp to `+3V3A` / GND |

**On-board NTC:** RT1 NCP18WF104F03RC (100 kΩ, B = 4250), placed in the middle of the MOSFET bank.
R7 4.7 kΩ 0.1 % from `+3V3A` to `BOARD_NTC`, RT1 from `BOARD_NTC` to GND, C9 100 nF.

**VIN sense:** R8 100 kΩ 1 % from `VIN` to `VIN_SENSE`, R9 10 kΩ 1 % to GND, C8 100 nF. The ratio is 11:1, so 36 V reads 3.27 V.

## Sheet 6: Heater outputs (×5, n = 0..4)

**Gate drivers (UCC27524ADR, dual 5 A low-side, SOIC-8):**

| Driver | INA | INB | OUTA | OUTB |
|---|---|---|---|---|
| U10 | `HE0` | `HE1` | `G0` | `G1` |
| U11 | `HE2` | `HE3` | `G2` | `G3` |
| U12 | `HE4` | GND (unused) | `G4` | NC |

Every driver has VDD ← `+12V` (1 µF + 100 nF at the pin), GND ← `GND` (power ground, near the FET sources),
and **ENA, ENB ← `HTR_EN`**. Decoupling: C70–C72 1 µF + C73–C75 100 nF.

Per channel, n = 0..4:

| Ref | Part | Connections |
|---|---|---|
| R70–R74 | 100 Ω 0603 | MCU `HEn` → driver input (series, slows edges and limits ringing) |
| R80–R84 | 100 kΩ 0603 | driver input → GND (the output stays off while the MCU is in reset or unflashed) |
| R90–R94 | 4.7 Ω 0603 | driver `Gn` → FET gate |
| R100–R104 | 10 kΩ 0603 | FET gate → source |
| Q10–Q14 | BSC028N06LS3 G (60 V, 2.8 mΩ, SuperSO8) | S → `GND` (power), D → `HEn_SW`, G → via R9n (R90–R94) |
| F1–F5 | 10 A ATM mini-blade fuse in a Keystone 3568 PCB holder | `VIN` → `HEn_PWR` |
| D10–D14 | B560C (60 V 5 A Schottky, SMC) | cathode `HEn_PWR`, anode `HEn_SW` (clamps wiring inductance) |
| D15–D19 | Red LED 0805 + R110–R114 10 kΩ 0805 | `HEn_PWR` → `HEn_SW` (lights while the heater is on) |
| J10–J14 | Phoenix MSTBA 2,5/2-G-5,08 | pin 1 `HEn_PWR` (+), pin 2 `HEn_SW` (−) |

**Heater interlock:**

| Ref | Part | Connections |
|---|---|---|
| J5 | JST-XH 2-pin, shipped with a jumper shunt | pin 1 → R120 1 kΩ → `+5V`; pin 2 → `HTR_EN` |
| R121 | 10 kΩ | `HTR_EN` → GND. **An open loop forces all drivers off.** |
| R122 / R123 | 12 kΩ / 22 kΩ divider | `HTR_EN` → `IL_SENSE` (PB2) → GND. A closed loop reads about 2.9 V |

When the loop is closed, `HTR_EN` sits at about 4.4 V, which is above the UCC27524 enable threshold. Put any
normally-closed contact in the loop (a chamber-door switch, a bimetal thermal cutoff, an E-stop auxiliary
contact). If it opens, all heater FETs turn off in hardware within microseconds, whatever Klipper is doing,
and Klipper also sees the change on PB2.

## Sheet 7: Fans

| Ref | Part | Connections |
|---|---|---|
| JP3 | 3-pin jumper "FAN V" | center `FAN_V`; position 1-2 = `+12V`, position 2-3 = `VIN` |
| Q20, Q21 | AO3400A (30 V, 5.7 A) | G ← `FAN0`/`FAN1` via 100 Ω (R130/R131) with 100 kΩ pull-down (R132/R133); S → GND; D → `FANn_SW` |
| D20, D21 | SS14 | cathode `FAN_V`, anode `FANn_SW` |
| J30, J31 | JST-XH 2-pin | pin 1 `FAN_V`, pin 2 `FANn_SW` |

The fans share a 1 A budget when they run from `+12V`, limited by the U2 buck.
