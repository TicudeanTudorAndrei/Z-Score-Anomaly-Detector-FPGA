library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity top_level_proj is
port ( clk: in STD_LOGIC;
btn: in STD_LOGIC_VECTOR(4 downto 0);
sw: in STD_LOGIC_VECTOR(15 downto 0);       
led: out STD_LOGIC_VECTOR(15 downto 0);       
an: out STD_LOGIC_VECTOR(7 downto 0);        
cat: out STD_LOGIC_VECTOR(6 downto 0);
uart_cts: in STD_LOGIC; -- Clear to Send
uart_rts: out STD_LOGIC; -- Request to Send
uart_rxd_out: out STD_LOGIC; -- Receive Data - FPGA output
uart_txd_in: in STD_LOGIC);  -- Transmit Data - FPGA input
end top_level_proj;

architecture top_level_proj_arh of top_level_proj is

constant SAMPLE_SIZE_INTEGER: integer := 64;                                      -- SELECT SAMPLE SIZE HERE, MAX IS 64
constant SAMPLE_SIZE_HEXADECIMAL: STD_LOGIC_VECTOR(31 downto 0) := x"42800000";   -- WRITE THE IEEE 754 HEXADECIMAL REPRESENTATION: https://www.h-schmidt.net/FloatConverter/IEEE754.html?

component mpg is
port ( btn: in STD_LOGIC;
clk: in STD_LOGIC;
enable: out STD_LOGIC);
end component;

component ssd is
port ( digits: in STD_LOGIC_VECTOR(31 downto 0); 
clk: in STD_LOGIC;
an: out STD_LOGIC_VECTOR(7 downto 0);
cat: out STD_LOGIC_VECTOR(6 downto 0));
end component;

component zscore is
generic ( SAMPLE_SIZE_INT : integer := 64;
SAMPLE_SIZE_HEX: STD_LOGIC_VECTOR(31 downto 0) := x"42800000");
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;
        
x_tvalid: in STD_LOGIC;
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);
x_tready: out STD_LOGIC;
        
zscore_tvalid: out STD_LOGIC;
zscore_tdata: out STD_LOGIC_VECTOR(31 downto 0);
zscore_tready: in STD_LOGIC;
init_complete: out STD_LOGIC);
end component;

component uart_tx is
generic ( g_CLKS_PER_BIT : integer := 869);
port ( i_Clk: in  STD_LOGIC;  
i_TX_DV: in  STD_LOGIC;    
i_TX_Byte: in  STD_LOGIC_VECTOR(7 downto 0);    
o_TX_Active: out STD_LOGIC;    
o_TX_Serial: out STD_LOGIC;    
o_TX_Done: out STD_LOGIC);
end component;

component uart_rx is
generic ( g_CLKS_PER_BIT : integer := 869);
port ( i_Clk: in  STD_LOGIC;
i_RX_Serial: in  STD_LOGIC;   
o_RX_DV: out STD_LOGIC;   
o_RX_Byte: out STD_LOGIC_VECTOR(7 downto 0));
end component;

component fifo32x64 is
port ( s_axis_aresetn: in STD_LOGIC;
s_axis_aclk: in STD_LOGIC;

s_axis_tvalid: in STD_LOGIC;
s_axis_tready: out STD_LOGIC;
s_axis_tdata: in STD_LOGIC_VECTOR(31 downto 0);

m_axis_tvalid: out STD_LOGIC;
m_axis_tready: in STD_LOGIC;
m_axis_tdata: out STD_LOGIC_VECTOR(31 downto 0));
end component;

signal deb_buttons: STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
signal display_data_7seg: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal uart_tx_dv: STD_LOGIC := '0';
signal uart_tx_done: STD_LOGIC := '0';
signal uart_rx_dv: STD_LOGIC := '0';
signal uart_rx_byte: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
signal uart_tx_byte: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

signal received_data_accumulator: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal rcv_packet_count: integer range 0 to 3 := 0;

signal zscore_final: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal full_float_number_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal full_float_number_tvalid: STD_LOGIC := '0';
signal full_float_number_tready: STD_LOGIC := '0';

signal zscore_tvalid: STD_LOGIC := '0';
signal zscore_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal send_valid: STD_LOGIC := '0';
signal send_data: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal send_active: STD_LOGIC := '0';

type uart_state_type is (IDL, SB2, SB3, SB4, SELB);
signal uart_state: uart_state_type := IDL;
signal byte_count: integer range 0 to 3 := 0;

begin

mpg_inst_0: mpg port map( btn => btn(0), clk => clk, enable => deb_buttons(0));
mpg_inst_1: mpg port map(btn => btn(1), clk => clk, enable => deb_buttons(1));
mpg_inst_2: mpg port map(btn => btn(2), clk => clk, enable => deb_buttons(2));
mpg_inst_3: mpg port map(btn => btn(3), clk => clk, enable => deb_buttons(3));
mpg_inst_4: mpg port map(btn => btn(4), clk => clk, enable => deb_buttons(4));
--    1
--  2 0 3 
--    4
display_inst: ssd port map(digits => display_data_7seg, clk => clk, an => an, cat => cat);

uart_trs_inst: uart_tx
generic map ( g_CLKS_PER_BIT => 869)
port map ( i_Clk => clk,      
i_TX_DV => uart_tx_dv,  
i_TX_Byte => uart_tx_byte,     
o_TX_Active => open,  
o_TX_Serial => uart_rxd_out,
o_TX_Done => uart_tx_done);

uart_rcv_inst: uart_rx
generic map ( g_CLKS_PER_BIT => 869)
port map ( i_Clk => clk,  
i_RX_Serial => uart_txd_in,     
o_RX_DV => uart_rx_dv,   
o_RX_Byte => uart_rx_byte);

z_score_inst: zscore
generic map ( SAMPLE_SIZE_INT => SAMPLE_SIZE_INTEGER,
SAMPLE_SIZE_HEX => SAMPLE_SIZE_HEXADECIMAL)
port map ( aclk => clk,
aresetn => sw(0),

x_tvalid => full_float_number_tvalid,
x_tdata => full_float_number_tdata,
x_tready => full_float_number_tready,

zscore_tvalid => zscore_tvalid,
zscore_tdata => zscore_tdata,
zscore_tready => '1'); -- always ready to receive zscore

uart_send_proc: process(clk)
begin
    if rising_edge(clk) then
        case uart_state is
            when IDL =>
                if send_valid = '1' then
                    uart_tx_byte <= send_data(31 downto 24);
                    uart_tx_dv <= '1';
                    send_active <= '1';
                    byte_count <= 0;
                    uart_state <= SELB;
                end if;

            when SELB =>
                if uart_tx_done = '1' then
                    uart_tx_dv <= '0';
                    case byte_count is
                        when 0 =>
                            uart_tx_byte <= send_data(23 downto 16);
                            uart_state <= SB2;
                        when 1 =>
                            uart_tx_byte <= send_data(15 downto 8);
                            uart_state <= SB3;
                        when 2 =>
                            uart_tx_byte <= send_data(7 downto 0);
                            uart_state <= SB4;
                        when others =>
                            send_active <= '0';
                            uart_state <= IDL;
                    end case;
                    byte_count <= byte_count + 1;
                end if;

            when SB2 =>
                uart_tx_dv <= '1';
                uart_state <= SELB;

            when SB3 =>
                uart_tx_dv <= '1';
                uart_state <= SELB;

            when SB4 =>
                uart_tx_dv <= '1';
                uart_state <= SELB;

            when others =>
                uart_state <= IDL;
        end case;
    end if;
end process;


uart_recieve_proc: process(clk)
begin
    if rising_edge(clk) then     
        full_float_number_tvalid <= '0';   
        if uart_rx_dv = '1' then
            received_data_accumulator <= received_data_accumulator(23 downto 0) & uart_rx_byte;
            rcv_packet_count <= rcv_packet_count + 1;
        
            if rcv_packet_count = 3 and full_float_number_tready = '1' then
                full_float_number_tdata <= received_data_accumulator(23 downto 0) & uart_rx_byte;
                full_float_number_tvalid <= '1';
                
                rcv_packet_count <= 0;
            end if;
        end if;
    end if;
end process;

display_result_proc: process(clk)
begin
    if rising_edge(clk) then
        send_valid <= '0';
        if zscore_tvalid = '1' then
            display_data_7seg <= zscore_tdata;
            send_data <= zscore_tdata;
            send_valid <= '1';
        end if;
     end if;
end process;

end architecture;
