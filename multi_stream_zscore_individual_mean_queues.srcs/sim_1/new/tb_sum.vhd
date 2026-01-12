library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

entity tb_sum is
end entity;

architecture tb_sum_arch of tb_sum is

component sum
generic ( SAMPLE_SIZE : integer := 64);
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;

x_tvalid: in STD_LOGIC;
x_tready: out STD_LOGIC;
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);

sum_tvalid: out STD_LOGIC;
sum_tready: in STD_LOGIC;
sum_tdata: out STD_LOGIC_VECTOR(31 downto 0);
init_complete: out STD_LOGIC);
end component;

signal aclk: STD_LOGIC := '0';
signal aresetn: STD_LOGIC := '0';

signal x_tvalid: STD_LOGIC := '0';
signal x_tready: STD_LOGIC;
signal x_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal sum_tvalid: STD_LOGIC;
signal sum_tready: STD_LOGIC := '0';
signal sum_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal init_complete: STD_LOGIC;

constant clk_period : time := 10 ns;
constant total : integer := 100;

begin

sum_component: sum
generic map ( SAMPLE_SIZE => 64)
port map ( aclk => aclk,
aresetn => aresetn,

x_tvalid => x_tvalid,
x_tready => x_tready,
x_tdata => x_tdata,

sum_tvalid => sum_tvalid,
sum_tready => sum_tready,
sum_tdata => sum_tdata,
init_complete => init_complete);

sum_tready <= '1';

clk_process : process
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

    for i in 0 to total - 1 loop
        wait until rising_edge(aclk) and x_tready = '1';
        
        x_tdata <= x"40000000"; -- 2.0
        x_tvalid <= '1';
        
        wait for clk_period;
        wait until rising_edge(aclk);

        x_tvalid <= '0';
    end loop;

wait;
end process;

end architecture;
