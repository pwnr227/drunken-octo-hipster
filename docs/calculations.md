# HX5 Design Calculations (rev A)

## 1. Heater channel current

| Supply | 120 W heater current | Heater resistance |
|---|---|---|
| 24.0 V | 5.00 A | 4.80 Ω |
| 26.0 V (PSU trimmed high) | 5.42 A (141 W into the same 4.8 Ω element) | 4.80 Ω |
| 12.0 V | 10.0 A | 1.20 Ω |

The design point is **5.42 A per channel** (a 24 V heater on a PSU trimmed to 26 V). The hardware
rating is **10 A per channel**, which gives 85 % margin at 24 V and still allows a 120 W heater at 12 V.

Total at 24 V: 5 × 5.42 A + about 1.5 A logic and fans = **28.6 A worst case**. The input path (XT90 at 40 A, ideal
diode, planes) is rated for **30 A continuous**.

## 2. Heater MOSFET: Infineon BSC028N06LS3 G

* V<sub>DS</sub> = 60 V. The SMDJ33A TVS clamps VIN at no more than 53.3 V, so the FET stays below its V<sub>DS</sub>
  rating even during a surge.
* R<sub>DS(on)</sub> = 2.8 mΩ max at V<sub>GS</sub> = 10 V and 25 °C. Allow ×1.6 at T<sub>j</sub> = 110 °C, which gives **4.5 mΩ**.
* Gate drive is 12 V, so the FET is fully enhanced. This avoids relying on its logic-level rating at 3.3 V.

Conduction loss:

| Current | P = I² · R<sub>DS(on),hot</sub> |
|---|---|
| 5.42 A (24 V design point) | 0.13 W |
| 10 A (channel max) | 0.45 W |

SuperSO8 on about 6 cm² of 2 oz copper gives R<sub>θJA</sub> ≈ 40 K/W. At 10 A that is a rise of about 18 K, so
no heatsink is needed.

Switching loss: Klipper heaters use software PWM with `pwm_cycle_time: 0.100` (10 Hz). The UCC27524 drives the
gate with Rg = 4.7 Ω, so with Q<sub>g</sub> ≈ 40 nC each edge takes well under 100 ns.
P<sub>sw</sub> ≈ ½ · V · I · (t<sub>r</sub>+t<sub>f</sub>) · f = ½ · 26 · 5.4 · 200 ns · 10 Hz ≈ **0.14 µW**. This is negligible.

## 3. Fuses: 10 A ATM mini blade

* The normal channel current of 5.4 A is 54 % of the fuse rating. Blade fuses should run continuously at 75 % or less,
  and less again in hot ambient (about −10 % at 60 °C chamber air). 54 % is well inside both limits.
* Cold resistance is about 7 mΩ, so the fuse dissipates about 0.2 W at 5.4 A.
* The fuse protects the 12 A terminal, the 18 AWG heater wire and the PCB traces against a short. It does **not**
  protect the heater against overtemperature. Use a thermal cutoff for that, as the README explains.
* For PTC ceramic chamber heaters, check the cold inrush current. Most 120 W / 24 V PTC heaters peak at 2–3× their
  running current for under 1 s, and an ATM fuse tolerates that (200 % for > 0.15 s).

## 4. Reverse-polarity ideal diode: 2 × BSC016N06NS + LM74700-Q1

R<sub>DS(on)</sub> = 1.6 mΩ, or about 2.6 mΩ hot. The two FETs are in parallel, so each carries 15 A at 30 A total:

P = 15² × 2.6 mΩ = **0.59 W per FET**. This needs about 10 cm² of 2 oz copper per FET on both outer layers,
stitched with vias. Expect a rise of about 30 K.

A Schottky diode at 30 A would dissipate about 15 W, so the ideal-diode controller is required.

## 5. PCB copper (IPC-2221, outer layer, 2 oz = 70 µm)

I = k · ΔT<sup>0.44</sup> · A<sup>0.725</sup> with k = 0.048 (external), A in mil².

| Path | Current | ΔT | Min cross-section | Min width at 2 oz | **Specified** |
|---|---|---|---|---|---|
| Heater channel (fuse → terminal → FET) | 10 A | 10 K | 390 mil² | 3.5 mm | **≥ 5 mm pour, top + bottom** |
| VIN and GND bus | 30 A | 10 K | 1780 mil² | 16.1 mm | **≥ 18 mm on L1 + full inner plane L3 (VIN) / L2 (GND)** |

## 6. Gate drive and logic budget

| Load | Rail | Current |
|---|---|---|
| 3 × UCC27524 quiescent + gate charge at 10 Hz | +12 V | < 5 mA |
| 2 × fans (when FAN V = 12 V) | +12 V | ≤ 1.0 A |
| TJA1051T/3 (dominant) | +5 V | 70 mA |
| AP2112K → STM32G0B1 + LEDs | +5 V | 60 mA |
| **U2 12 V buck output** | | ≈ 1.0 A of 3 A rating |
| **U3 5 V buck output** | | ≈ 0.15 A of 2 A rating |

LDO dissipation: (5 − 3.3) V × 60 mA = 0.1 W in SOT-23-5, which is fine.

Buck feedback (LMR336x0, V<sub>REF</sub> = 1.0 V):
* 12 V: 1 + 100 k / 9.09 k = **12.00 V**
* 5 V: 1 + 100 k / 24.9 k = **5.02 V**

Buck inductor, 400 kHz, with ripple at 30–40 % of rated current:
* 12 V from 24 V: D = 0.5, L = (24 − 12) · 0.5 / (400 k · 1.0 A) = 15 µH → **15 µH, I<sub>sat</sub> ≥ 4 A**
* 5 V from 24 V: D = 0.21, L = (24 − 5) · 0.21 / (400 k · 0.8 A) = 12 µH → **10 µH, I<sub>sat</sub> ≥ 3 A**

## 7. Thermistor front-end

The divider is R<sub>pull-up</sub> = 4.7 kΩ to 3.3 V (VDDA, which is also the ADC reference, so the result is
ratiometric).

| Sensor | Temperature | R | V<sub>ADC</sub> |
|---|---|---|---|
| NTC 100k B3950 | 25 °C | 100 kΩ | 3.15 V |
| NTC 100k B3950 | 100 °C | 6.97 kΩ | 1.97 V |
| NTC 100k B3950 | 250 °C | 0.34 kΩ | 0.22 V |
| PT1000 (1 kΩ pull-up) | 25 °C | 1097 Ω | 1.73 V |
| PT1000 (1 kΩ pull-up) | 300 °C | 2120 Ω | 2.24 V |

The 10 kΩ series resistor carries no DC current, because the ADC input current is in the nA range, so it adds no
reading error and Klipper's `inline_resistor` stays at 0. The 10 kΩ / 100 nF RC gives τ = 1 ms, or f<sub>c</sub> = 160 Hz.
Klipper samples thermistors every 300 ms and averages 8 readings, so the RC removes PWM and switching noise without
slowing the response.

**Fault case: a thermistor wire shorted to 24 V.**
* The current through the 10 kΩ series resistor into the BAT54S clamp is (24 − 3.6) / 10 k = **2.0 mA**, which is
  within the STM32 injection limit even without the clamp.
* Back-feed through the pull-up: (24 − 3.3) / 4.7 k = 4.4 mA, or 20 mA with the PT1000 jumper fitted. The 3V3 rail
  load is about 40 mA and D3 (3.6 V zener) clamps any excess, so the rail cannot rise.
* Dissipation in the 4.7 kΩ is 91 mW, so it is specified in 0805 (125 mW). In the 1.27 kΩ it is 0.34 W, so the 1.27 kΩ is a **2010 thin-film part (0.4 W)**.

## 8. VIN sense

The divider is 100 k / 10 k (÷11). Full scale 3.3 V corresponds to 36.3 V. The resolution is 12-bit / 11 = 8.9 mV
per count. Klipper's oversampling makes the reading more stable than that resolution suggests.

## 9. Interlock

`HTR_EN` when closed: 5 V × 10 k / (1 k + 10 k ‖ 34 k) = **4.43 V**. The UCC27524 EN V<sub>IH</sub> is 2.1 V max.
`HTR_EN` when open: pulled to 0 V through 10 kΩ, while the driver's internal EN pull-up is about 200 kΩ, so the
result is 0.24 V, below V<sub>IL</sub> (0.8 V min). The drivers are disabled.
`IL_SENSE` = 4.43 × 22 / 34 = 2.87 V, which reads as logic high (V<sub>IH</sub> = 0.7 × 3.3 = 2.31 V).

## 10. Board thermal summary at 5 × 120 W, 24 V

| Source | Total |
|---|---|
| 5 × heater FETs | 0.65 W |
| 5 × fuses | 1.0 W |
| 2 × ideal-diode FETs | 1.2 W |
| 10 × terminal contacts (about 1 mΩ each) | 0.3 W |
| Bucks + LDO | 1.0 W |
| **Total** | **≈ 4.2 W** spread over 96 cm² |

The board runs passively up to 60 °C ambient. If it is mounted inside a heated chamber, connect a fan to J30 and
monitor the on-board NTC; the config shuts down if the board passes 85 °C.
