# HX5 PCB Layout Guidelines (rev A)

## Stack-up (4 layers, 1.6 mm)

| Layer | Copper | Use |
|---|---|---|
| L1 Top | 2 oz | Components, heater channel pours, VIN bus pour |
| L2 | 1 oz | **Solid GND plane**, unbroken under the MCU, ADC and CAN areas |
| L3 | 1 oz | VIN plane under the power section; +12 V / +5V / +3V3 islands under the logic section |
| L4 Bottom | 2 oz | Mirror pours for heater channels and GND return, plus a few signal traces |

Board size 120 × 80 mm, 4 × M3 holes 4 mm in from each corner. Make the hole pads GND-isolated (NPTH or a
non-plated ring) so the chassis does not become a ground return path.

## Floor plan

```
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ [J1 XT90]  Q1 Q2 U1  D1  C1 C2          F1   F2   F3   F4   F5            │
 │  power in  ideal diode  bulk caps    ───── 10 A fuse row ─────           │
 │                                        Q10  Q11  Q12  Q13  Q14  (RT1 in   │
 │  F6  U2 (12V)  U3 (5V)  U4 (3V3)       D10..D14 flyback   middle)         │
 │                                        [J10][J11][J12][J13][J14] heaters  │
 │ ───────────────── power / logic split (GND only joins at star) ───────── │
 │ U10 U11 U12 gate drivers (next to FETs, short gate loops)                 │
 │ [J2 USB-C] U6     U5 STM32G0B1   Y1     J5 interlock   J6 SWD  J7 AUX     │
 │ [J3][J4] CAN U7   JP2 term      SW1 SW2   [J20..J24] thermistors  [J30][J31]│
 └──────────────────────────────────────────────────────────────────────────┘
```

* All high-current parts (XT90, ideal diode, fuses, FETs, heater terminals) go along **one long edge**. Logic and
  low-level connectors go along the opposite edge, so heater wiring never runs over the thermistor and CAN
  connectors.
* Put the heater terminals on the board edge, with the FET for each channel directly behind its terminal and the
  fuse directly behind the FET. Each channel loop (VIN → fuse → terminal+ → heater → terminal− → FET → GND) should
  cover the smallest possible area.

## High-current rules

1. **Heater channels:** pours of at least 5 mm on both L1 and L4, joined by at least 8 × 0.4 mm vias at each pad
   (fuse holder, terminal, FET drain).
2. **VIN bus:** at least 18 mm wide on L1, plus the full L3 plane beneath it, joined to L1 with a via field of at
   least 30 vias at the XT90, the ideal-diode FETs and the fuse row.
3. **Power GND return:** the FET source pads go to L1/L4 pours and to the L2 plane through at least 9 vias per FET.
   The return goes straight back to the XT90 `−` pin.
4. **FET cooling:** put at least 6 cm² of copper under each heater FET drain, and at least 10 cm² under each
   ideal-diode FET, on L1 and L4 with thermal vias at a 1.0 mm pitch.
5. Keep XT90 and terminal pads at least 2 mm from any other net. All VIN–GND clearances on the outer layers are at
   least 0.5 mm.

## Gate drive

* Place each UCC27524 within 15 mm of the FETs it drives. Route gate and return as a pair and keep the loop small.
* Put Rg (4.7 Ω) and the 10 kΩ gate-source resistor right at the FET.
* Put the driver VDD decoupling (1 µF + 100 nF) right at the VDD/GND pins, with GND going straight to power ground.

## Analog and mixed signal

* **Ground strategy:** keep the L2 GND plane solid. Route all heater return current on L1/L4 power pours straight
  to J1, and do **not** route it through the logic area. The logic ground meets power ground at a single star
  point next to J1 (a net-tie in KiCad), so heater current cannot flow under the ADC.
* Put the thermistor RC parts (10 k, 100 nF, BAT54S) within 5 mm of the MCU ADC pins. Put the 4.7 k pull-ups near
  the connectors. Route TH traces over solid GND, away from SW nodes and gate traces.
* Feed VDDA through FB1, with the 1 µF + 100 nF capacitors at the pin.
* Place RT1 (board NTC) in the middle of the FET row, on a thermal island tied to a FET source pour, so it
  reads FET temperature.

## Switching regulators

* Follow the LMR336x0 datasheet layout: input cap → VIN/PGND pins in the tightest possible loop, a small SW
  node, and the FB divider kept away from the inductor.
* Keep at least 10 mm between the bucks and the thermistor traces and the crystal.

## USB / CAN

* USB D+/D−: a 90 Ω differential pair, as short as possible, with U6 (ESD) right at J2.
* CANH/CANL: route as a pair. Put D7 (ESD) at J3/J4 and the transceiver within 20 mm of the connectors.
* Put the crystal Y1 within 5 mm of PF0/PF1, inside a GND guard ring, with no traces underneath it on L1.

## Silkscreen and assembly

* Label every heater terminal with `HEn +/−` and "10 A MAX", every thermistor connector `THn`, and every PT1000
  jumper.
* Print a warning near J1: `24 V DC ONLY — 30 A MAX — 12 AWG`.
* Mark the polarity of the interlock connector and print "LOOP MUST BE CLOSED TO HEAT".
* Add test points: VIN, +12V, +5V, +3V3, +3V3A, GND, HTR_EN, CANH, CANL.

## Fab notes

* 4-layer, FR4 TG170 or better (the board may sit in a heated chamber), 1.6 mm, 2 oz outer / 1 oz inner.
* ENIG finish. Use a solder-mask defined pad for the QFN-style SuperSO8 FETs.
* Do the electrical checks before installing the fuses: hi-pot is not required, but check for VIN-to-GND shorts
  first.
