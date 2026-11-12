# 4-Tap Pipelined Direct Form FIR Filter: Specification

Revision 2. This version matches the RTL in `rtl/` (`fir_top.v`, `fir_d.v`, `fir_controller.v`).

## 1. Overview

A programmable 4-tap Direct Form FIR filter with a fixed 2-cycle latency and an atomic parallel-load coefficient bank. Samples stream through a serial-in, parallel-out (SIPO) history buffer, are multiplied by programmable coefficients, and are summed by a two-layer adder tree across two clock cycles.

| Item | Value |
|------|-------|
| Architecture | Direct Form, 4 taps |
| Pipeline depth | 2 clock cycles |
| Input and coefficient width | 8-bit signed |
| Product width | 16-bit signed |
| Output width | 18-bit signed |
| Clocking | Single clock, rising edge |
| Reset | Synchronous, active high |

Filter equation, where `x[n]` is the current input sample and `h0..h3` are the coefficients:

`y[n] = h0*x[n] + h1*x[n-1] + h2*x[n-2] + h3*x[n-3]`

## 2. Interface

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | in | 1 | Global clock |
| `rst` | in | 1 | Synchronous, active-high reset |
| `xin` | in | 8, signed | Input sample |
| `x_valid` | in | 1 | Input qualifier. Enables the SIPO and product registers |
| `coeff_ld` | in | 1 | Loads all four coefficients on the next clock edge |
| `coeff_in` | in | 32, signed | Packed coefficients: `h0 = [31:24]`, `h1 = [23:16]`, `h2 = [15:8]`, `h3 = [7:0]`. Each byte is signed |
| `yout` | out | 18, signed | Filtered output. Meaningful only while `y_valid` is high |
| `y_valid` | out | 1 | Output qualifier, `x_valid` delayed by exactly 2 cycles |

## 3. Microarchitecture

### 3.1 Registers

| Register | Width | Description |
|----------|-------|-------------|
| `sipo[0..2]` | 8, signed | Sample history: previous, 2 back, 3 back |
| `coeff[0..3]` | 8, signed | Coefficient bank (`h0..h3`) |
| `product[0..3]` | 16, signed | Product registers |
| `yout` | 18, signed | Output register |
| `valid_mid`, `y_valid` | 1 | Two-stage valid pipeline |

### 3.2 Tap mapping

| Tap | Sample | Coefficient |
|-----|--------|-------------|
| 0 | live `xin` | `coeff[0]` (`h0`) |
| 1 | `sipo[0]` | `coeff[1]` (`h1`) |
| 2 | `sipo[1]` | `coeff[2]` (`h2`) |
| 3 | `sipo[2]` | `coeff[3]` (`h3`) |

### 3.3 Modules

| Module | Role |
|--------|------|
| `fir_top` | Connects datapath and controller. `x_valid` drives the datapath's `shift_en` |
| `fir_d` | Datapath: SIPO, coefficient bank, multipliers, product registers, adder tree, output register |
| `fir_controller` | Control: two-stage valid pipeline producing `y_valid` |

## 4. Timing

**Edge 1 (multiply and capture).** When `x_valid = 1`, combinational multipliers form the four products from the live `xin`, the SIPO history, and the coefficient registers. On the rising edge:
- the four products are latched into `product[0..3]`
- the SIPO shifts: `xin` goes into `sipo[0]`, `sipo[0]` into `sipo[1]`, `sipo[1]` into `sipo[2]`
- `x_valid` is captured into `valid_mid`

**Edge 2 (sum and deliver).** A two-layer adder tree sums the four products combinationally, widening to 18 bits. On the next rising edge:
- the sum is latched into `yout`
- `valid_mid` moves into `y_valid`

So an output appears two clock edges after the input edge that produced it, and `y_valid` follows `x_valid` by exactly 2 cycles.

## 5. Stall ("bubble") behavior

When `x_valid = 0`:
- the SIPO and the product registers hold their values
- no new sample enters the history
- samples already in the pipeline still reach the output
- `y_valid` goes low 2 cycles later
- `yout` is recomputed each cycle from the held products and so repeats its last value. It is **not meaningful while `y_valid` is low** and must be ignored by downstream logic and testbenches

## 6. Coefficient loading

- A `coeff_ld` pulse loads all four coefficients in parallel on the next rising edge (atomic: there is never a mix of old and new values).
- Recommended sequence: pulse `coeff_ld = 1` with `x_valid = 0` for one cycle. The next valid sample is then evaluated with all four new coefficients.
- If `coeff_ld` and `x_valid` are both high in the same cycle, that sample's products use the **old** coefficients (the bank updates at the same edge the products are captured). The new coefficients apply from the next valid sample. No output ever mixes old and new coefficients within one sum, because every product of a given sample is computed in a single cycle.
- Samples already past edge 1 are unaffected by a later load.
- If `rst` and `coeff_ld` are both high, reset wins.

## 7. Reset

Synchronous, active high. On a rising clock edge with `rst = 1`:
- the SIPO history, product registers, `yout`, `valid_mid`, and `y_valid` clear to 0
- the coefficient bank clears to 0, so the filter outputs zeros until coefficients are loaded
- any samples in the pipeline are discarded

## 8. Numeric range

Inputs and coefficients range from -128 to 127. The largest product magnitude is (-128) x (-128) = 16384, which fits in 16-bit signed. The largest possible sum is 4 x 16384 = 65536, which fits in 18-bit signed (range -131072 to 131071). Overflow cannot occur.

## 9. Verification plan

A self-checking testbench compares the DUT against an independent reference model. It checks `yout` only on cycles where `y_valid` is high.

| # | Test | Purpose |
|---|------|---------|
| 1 | Unit impulse | Load `h = [16, 48, 48, 16]`, send a single 1 followed by zeros with `x_valid` held high. Expect the coefficients streaming out in order, then zeros |
| 2 | Asymmetric impulse | Repeat with `h = [1, 2, 3, 4]` to catch a reversed tap order that a symmetric profile hides |
| 3 | Bubble | Drop `x_valid` mid-stream. Check that no samples are lost or duplicated and `y_valid` drops 2 cycles later |
| 4 | Reconfiguration | Reload coefficients mid-stream (for example low-pass to high-pass) using the recommended sequence. The first sample after the load uses all new coefficients |
| 5 | Load with valid | Assert `coeff_ld` and `x_valid` together. Check the old-coefficient behavior in section 6 |
| 6 | Extremes | -128 and 127 inputs and coefficients, including (-128) x (-128) on all taps |
| 7 | Reset mid-stream | Assert `rst` during streaming. Check everything clears and `y_valid` is low |
| 8 | Valid latency | An assertion: `y_valid` equals `x_valid` delayed by 2 cycles, on every cycle |
| 9 | Random | Random samples, coefficients, and `x_valid` patterns, with a replayable seed, against the reference model |

## 10. Revision history

| Rev | Change |
|-----|--------|
| 1 | Initial specification |
| 2 | Aligned with the RTL: port names (`xin`, `yout`, `coeff_ld`, packed `coeff_in`); stall behavior (product registers hold); reset clears the coefficients; defined `coeff_ld` with `x_valid` and reset priority; replaced the "3-cycle transient" wording; expanded the verification plan |
