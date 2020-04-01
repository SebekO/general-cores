library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone_pkg.all;
use work.axi4_pkg.all;

entity xwb_axi4lite_bridge is
  port (
    clk_sys_i    : in std_logic;
    rst_n_i      : in std_logic;
    axi4_slave_i : in  t_axi4_lite_slave_in_32;
    axi4_slave_o : out t_axi4_lite_slave_out_32;
    wb_master_o  : buffer t_wishbone_master_out;
    wb_master_i  : in  t_wishbone_master_in
  );
end entity xwb_axi4lite_bridge;

architecture rtl of xwb_axi4lite_bridge is
  type state_type is (IDLE, SR_SEND_ADDR, SR_GET_DATA, SR_SEND_DATA, SW_GET_DATA, SW_GET_ADDR, SW_SEND, SW_RESP);
  signal prs, nxt : state_type;
  begin 

  --state register for the Moore state machine, also has a timeout counter. 
state_register : process(clk_sys_i,rst_n_i) is  
  variable count : unsigned(10 downto 0);
begin
  if rst_n_i = '0' then
    prs <= IDLE; 
    count := (others => '0');
  elsif rising_edge(clk_sys_i) then
    if prs /= IDLE then
      count := count + 1;
    else 
      count := (others => '0');
    end if;
    if count > 100 then   
      prs <= IDLE;
    else
      prs <= nxt;
    end if;
  end if;
end process state_register;    

--next state decoder for the Moore state machine.
next_state_decoder : process(prs, wb_master_i, axi4_slave_i) is
begin
  case prs is
  when IDLE =>
    if axi4_slave_i.awvalid = '1' and axi4_slave_i.wvalid = '1'then
      nxt <= SW_SEND;
    elsif axi4_slave_i.awvalid = '0' and axi4_slave_i.wvalid = '1' then
      nxt <= SW_GET_ADDR;
    elsif axi4_slave_i.awvalid = '1' and axi4_slave_i.wvalid = '0' then
      nxt <= SW_GET_DATA;
    elsif axi4_slave_i.arvalid = '1' then
      nxt <= SR_SEND_ADDR;
    else  
      nxt <= IDLE;
    end if;
  when SW_GET_ADDR =>
    if axi4_slave_i.awvalid = '1' then
      nxt <= SW_SEND; 
    else
      nxt <= SW_GET_ADDR;
    end if;
  when SW_GET_DATA => 
    if axi4_slave_i.wvalid = '1' then
      nxt <= SW_SEND; 
    else
      nxt <= SW_GET_DATA;
    end if;
  when SW_SEND => 
    if wb_master_i.ack = '1' or wb_master_i.stall = '0' then
      nxt <= SW_RESP; 
    else
      nxt <= SW_SEND;
    end if;
  when SR_SEND_ADDR =>
    if wb_master_i.stall = '0' then
      if wb_master_i.ack = '1' then
        nxt <= SR_SEND_DATA;
      else
        nxt <= SR_GET_DATA;
      end if;
    else 
      nxt <= SR_SEND_ADDR;
    end if;
  when SR_GET_DATA => 
    if wb_master_i.ack = '1' then
      nxt <= SR_SEND_DATA;
    else 
      nxt <= SR_GET_DATA;
    end if;
  when SR_SEND_DATA =>
    if axi4_slave_i.rready = '1' then
      nxt <= IDLE;
    else
      nxt <= SR_SEND_DATA;
    end if;
  when SW_RESP => 
    if axi4_slave_i.bready = '1' then
      nxt <= IDLE;
    else
      nxt <= SW_RESP;
    end if;
  end case;
end process next_state_decoder; 

--manages the Wishbone addres signal, sources it from the axi-read or write channel depending on the command. 
addr_register : process(clk_sys_i, rst_n_i) is 
begin
  if rst_n_i = '0' then
    wb_master_o.adr <= (others => '0');
  elsif rising_edge(clk_sys_i) then
    if axi4_slave_i.awvalid = '1' then
      wb_master_o.adr <= axi4_slave_i.awaddr;
    elsif prs = SW_RESP then
      wb_master_o.adr <= (others => '0');
    elsif axi4_slave_i.arvalid = '1' then
      wb_master_o.adr <= axi4_slave_i.araddr;
    elsif prs = SR_SEND_DATA then
      wb_master_o.adr <= (others => '0');
    end if;
  end if;
end process addr_register;

--manages the two data registers, one for reading (and byte-validation) the other for writing.
data_register : process(clk_sys_i, rst_n_i) is 
begin
  if rst_n_i = '0' then
    wb_master_o.dat <= (others => '0');
    wb_master_o.sel <= (others => '0');
    axi4_slave_o.rdata <= (others => '0');
  elsif rising_edge(clk_sys_i) then
    if axi4_slave_i.wvalid = '1' then
      wb_master_o.dat <= axi4_slave_i.wdata;
      wb_master_o.sel <= axi4_slave_i.wstrb;
    elsif prs = SW_RESP then
      wb_master_o.dat <= (others => '0');
      wb_master_o.sel <= (others => '0');
    end if;
    if (prs = SR_GET_DATA or prs = SR_SEND_ADDR) and wb_master_i.ack = '1' then
      axi4_slave_o.rdata <= wb_master_i.dat;
      wb_master_o.sel <= (others => '1');
    elsif prs = IDLE then
      axi4_slave_o.rdata <= (others => '0');
    end if;
  end if;
end process data_register;

--roughly convers wishbone error messages to axi-error mesages. 
error_register : process(clk_sys_i, rst_n_i) is 
begin
  if rst_n_i = '0' then
    axi4_slave_o.bresp <= "10";
    axi4_slave_o.rresp <= "10";
  elsif rising_edge(clk_sys_i) then
    if prs = SW_SEND and wb_master_i.ack = '1' then
      axi4_slave_o.bresp <= wb_master_i.err & '0';
      axi4_slave_o.rresp <= "00";
    elsif prs = SW_SEND and wb_master_i.ack = '1' then
      axi4_slave_o.bresp <= "00";
      axi4_slave_o.rresp <= wb_master_i.err & '0';
    elsif prs = IDLE then
      axi4_slave_o.bresp <= "00";
      axi4_slave_o.rresp <= "00";
    end if; 
  end if;
end process error_register;

--AXI READ RELATED SIGNALS
axi4_slave_o.arready  <= '1'    when rst_n_i = '1' and prs = IDLE else '0'; 
axi4_slave_o.rvalid   <= '1'    when prs = SR_SEND_DATA else '0';
axi4_slave_o.rlast    <= '1'    when prs = SR_SEND_DATA else '0';
--AXI WRITE RELATED SIGNALS
axi4_slave_o.awready <= '1' when rst_n_i = '1' and (prs = IDLE or prs = SW_GET_ADDR) else '0';
axi4_slave_o.wready <= '1'  when rst_n_i = '1' and (prs = IDLE or prs = SW_GET_DATA) else '0';
axi4_slave_o.bvalid <= '1'  when prs = SW_RESP else '0';
--WISHBONE RELATED SIGNALS
wb_master_o.we  <= '1'    when prs = SW_SEND else '0';
wb_master_o.cyc <= '1'    when prs = SR_SEND_ADDR or prs = SR_GET_DATA or prs = SW_SEND else '0';
wb_master_o.stb <= '1'    when prs = SR_SEND_ADDR or prs = SW_SEND else '0';

end architecture rtl;