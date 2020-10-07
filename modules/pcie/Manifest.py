modules = { "local" : [
  "pcie"
  ]}
files = [ ];

# Be sure 'target' is defined.
try:
        target
except NameError:
        target = ""

# Target specific modules.
if target == "xilinx":
  if (syn_device[0:6].upper()=="XC7Z03" or# Family 7 (ZYNQ Z030,Z035 Z045)
      syn_device[0:7].upper()=="XC7Z045"):
    files.extend(["xilinx/processing_system_pcie.bd" ]);
