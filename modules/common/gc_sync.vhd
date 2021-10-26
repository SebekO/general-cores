--------------------------------------------------------------------------------
-- CERN BE-CO-HT
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   gc_sync
--
-- description: Elementary synchronizer chain using two flip-flops.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2014-2020
--------------------------------------------------------------------------------
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License. You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-2.0.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity gc_sync is
  generic(
    -- valid values are "positive" and "negative"
    g_SYNC_EDGE : string := "positive");
  port (
    clk_i     : in  std_logic;
    d_i       : in  std_logic;
    q_o       : out std_logic);
end gc_sync;

-- make Altera Quartus quiet regarding unknown attributes:
-- altera message_off 10335

architecture arch of gc_sync is

  signal sync_0ff, sync_1ff : std_logic := '0';

  attribute async_reg             : string;
  attribute async_reg of sync_0ff : signal is "true";
  attribute async_reg of sync_1ff : signal is "true";

begin

  assert g_SYNC_EDGE = "positive" or g_SYNC_EDGE = "negative" severity failure;

  sync_posedge : if (g_SYNC_EDGE = "positive") generate
    process(clk_i)
    begin
      if rising_edge(clk_i) then
        sync_0ff <= d_i;
        sync_1ff <= sync_0ff;
      end if;
    end process;
  end generate sync_posedge;

  sync_negedge : if(g_SYNC_EDGE = "negative") generate
    process(clk_i)
    begin
      if falling_edge(clk_i) then
        sync_0ff <= d_i;
        sync_1ff <= sync_0ff;
      end if;
    end process;
  end generate sync_negedge;

  q_o <= sync_1ff;

end arch;
