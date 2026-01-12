library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity tb_zscore_1s is
end entity;

architecture tb_zscore_1s_arh of tb_zscore_1s is

component zscore is
generic ( NUM_STREAMS: integer := 2;
SAMPLE_SIZE_INT : integer := 64;
SAMPLE_SIZE_HEX: STD_LOGIC_VECTOR(31 downto 0) := x"42800000");
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;
        
x_tvalid: in STD_LOGIC;
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);
x_tready: out STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0);
x_id: in STD_LOGIC_VECTOR(15 downto 0); 
        
zscore_tvalid: out STD_LOGIC;
zscore_tdata: out STD_LOGIC_VECTOR(31 downto 0);
zscore_tready: in STD_LOGIC;
zscore_id: out STD_LOGIC_VECTOR(15 downto 0); 

init_complete: out STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0));
end component;

signal aclk: STD_LOGIC := '0';
signal aresetn: STD_LOGIC := '0';

signal x_tvalid: STD_LOGIC := '0';
signal x_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal x_tready: STD_LOGIC_VECTOR(0 downto 0) := (others => '0');
signal x_id: STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
    
signal zscore_tvalid: STD_LOGIC;
signal zscore_tdata: STD_LOGIC_VECTOR(31 downto 0);
signal zscore_tready: STD_LOGIC := '0';
signal zscore_id: STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 

signal init_complete: STD_LOGIC_VECTOR(0 downto 0);

constant clk_period : time := 10 ns;

begin

zscore_tready <= '1';

zscore_component: zscore
generic map ( NUM_STREAMS => 1,
SAMPLE_SIZE_INT => 64,
SAMPLE_SIZE_HEX => x"42800000")
port map ( aclk => aclk,
aresetn => aresetn,
            
x_tvalid => x_tvalid,
x_tdata => x_tdata,
x_tready => x_tready,
x_id => x_id,    
            
zscore_tvalid => zscore_tvalid,
zscore_tdata => zscore_tdata,
zscore_tready => zscore_tready,
zscore_id => zscore_id,

init_complete => init_complete);

clk_process: process
begin
    aclk <= '0';
    wait for clk_period / 2;
    aclk <= '1';
    wait for clk_period / 2;
end process;

test_process : process
begin

aresetn <= '0';
wait for clk_period * 2;
aresetn <= '1';
wait for clk_period * 2;

for i in 1 to 20 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3fc00000"; -- 1.5
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 21 to 40 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3fa66666"; -- 1.3
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 41 to 60 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3fd9999a"; -- 1.7
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 61 to 64 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3f8ccccd"; -- 1.1
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 65 to 74 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3f800000"; -- 1.0
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 75 to 84 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3f99999a"; -- 1.2
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 85 to 94 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3fb33333"; -- 1.4
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 95 to 104 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3fa66666"; -- 1.3
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 105 to 114 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3fcccccd"; -- 1.6
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 115 to 124 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3fe66666"; -- 1.8
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 125 to 128 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3f8ccccd"; -- 1.1
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;

for i in 129 to 133 loop
    wait until rising_edge(aclk) and x_tready(0) = '1';
    x_tdata <= x"3fc00000"; -- 1.5
    x_tvalid <= '1';
    x_id <= x"0000";
end loop;


wait until rising_edge(aclk);
x_tvalid <= '0';
wait;

end process;

end architecture;