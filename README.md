# 4-Tap Pipelined Direct Form FIR Filter

A programmable 4-tap Direct Form FIR filter in Verilog, designed with ASIC implementation in mind. It has a fixed 2-cycle latency and an atomic parallel-load coefficient bank.

> **Status: work in progress.** The RTL and specification are written. The testbench and the first simulation runs are still to come. See [Status](#status).

Full details are in the [specification](docs/SPEC.md).

## Features

- Direct Form architecture, 4 taps
- Signed 8-bit input samples and coefficients
- 16-bit products and an 18-bit signed output (overflow is not possible)
- Fixed 2-cycle latency from `x_valid` to `y_valid`
- Stall ("bubble") support: when `x_valid = 0`, the sample history freezes
- All four coefficients load in parallel on a single clock edge
- Synchronous, active-high reset
- Datapath and control are separate modules

## Architecture

Samples enter a serial-in, parallel-out (SIPO) history buffer. Each tap multiplies its sample by its coefficient, and a two-layer adder tree sums the products:

`y[n] = h0*x[n] + h1*x[n-1] + h2*x[n-2] + h3*x[n-3]`

**Pipeline**

- **Edge 1:** the four products are latched, the SIPO shifts, and `x_valid` enters the valid pipeline.
- **Edge 2:** the adder tree output is latched into `yout`, and `y_valid` goes high.

## Modules

| File | Description |
|------|-------------|
| `rtl/fir_top.v` | Top level, connects the datapath and controller |
| `rtl/fir_d.v` | Datapath: SIPO history, coefficient bank, multipliers, product registers, adder tree, output register |
| `rtl/fir_controller.v` | Control: two-stage valid pipeline that produces `y_valid` |

## Interface

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | in | 1 | Clock |
| `rst` | in | 1 | Synchronous, active-high reset |
| `xin` | in | 8 (signed) | Input sample |
| `x_valid` | in | 1 | Input qualifier and shift enable |
| `coeff_ld` | in | 1 | Loads all four coefficients on the next clock edge |
| `coeff_in` | in | 32 (signed) | Packed coefficients: `h0 = [31:24]`, `h1 = [23:16]`, `h2 = [15:8]`, `h3 = [7:0]` |
| `yout` | out | 18 (signed) | Filter output, meaningful only while `y_valid` is high |
| `y_valid` | out | 1 | Output qualifier, `x_valid` delayed by exactly 2 cycles |

## Behavior notes

- **Reset:** synchronous. It clears the history, products, output, valid pipeline, and the coefficient bank, so the filter outputs zeros until coefficients are loaded.
- **Stalls:** when `x_valid = 0`, the SIPO and product registers hold. In-flight samples still reach the output, and `y_valid` drops 2 cycles later.
- **Coefficient updates:** pulse `coeff_ld = 1` with `x_valid = 0` for one cycle, and the next valid sample uses all new coefficients. If `coeff_ld` and `x_valid` are high together, that sample uses the old coefficients.

See the [specification](docs/SPEC.md) for the full timing and behavior rules.

## Verification plan

A self-checking testbench with an independent reference model, covering:

1. Unit impulse and asymmetric-coefficient impulse
2. Backpressure bubbles
3. Runtime coefficient reconfiguration
4. `coeff_ld` together with `x_valid`
5. Extreme values, including -128 x -128 on all taps
6. Reset in the middle of a stream
7. A valid-latency assertion
8. Constrained-random stimulus with a replayable seed

## Status

- [x] Specification
- [x] RTL: datapath, controller, top
- [ ] Hand-traced impulse response table
- [ ] Testbench and reference model
- [ ] Simulation passing
- [ ] Block diagram and timing diagram in `docs/`

## Repository layout

```
fir-filter/
├── README.md
├── docs/    # specification, diagrams, design notes
├── rtl/     # Verilog source
└── tb/      # testbench (in progress)
```

## Possible future work

- Parameterize the number of taps and the data widths
- Synthesize the design and report the critical path
- Compare against a non-pipelined version

## Author

Karthik Naresh Panyam

## License

*To be decided*
