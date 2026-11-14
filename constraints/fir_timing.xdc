# Timing constraints for fir_top
# Target: 100 MHz (10 ns period). Tighten the period later to find Fmax.

create_clock -period 10.000 -name clk [get_ports clk]
