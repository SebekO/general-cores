//////////////////////////////////////////////////////////////////////////////
// Title      : util_pkg
// Project    : PS Damper Loops
// Date       : 2023-03-31
//////////////////////////////////////////////////////////////////////////////
// Schematic  : https://edms.cern.ch/ui/file/1390859/2/EDA-02917-V2-0_sch.pdf
//////////////////////////////////////////////////////////////////////////////
// File       : util_pkg.sv
// Author     : Sebastian Owarzany
// Company    : CERN
// Platform   : EDA-02917-V2-0
// Standard   : SystemVerilog IEEE 1800
//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021-2022 CERN. All rights reserved.
//////////////////////////////////////////////////////////////////////////////

`ifndef util_pkg_DONE
  `define util_pkg_DONE
  package util_pkg;

    function integer clogb2;
    input [31:0] value;
    integer 	i;
    begin
      clogb2 = 0;
      for(i = 0; 2**i < value; i = i + 1)
        clogb2 = i + 1;
    end
    endfunction // clogb2
  endpackage // util_pkg

  // Import package in the design
  import util_pkg::*;

`endif // util_pkg_DONE