library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity tb_sqrd_dev is
end entity;

architecture tb_sqrd_dev_arh of tb_sqrd_dev is

component sqrd_dev is
generic ( SAMPLE_SIZE : integer := 64);
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;
        
x_tvalid: in STD_LOGIC;
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);
x_tready: out STD_LOGIC;
        
mean_tvalid: in STD_LOGIC;
mean_tdata: in STD_LOGIC_VECTOR(31 downto 0);
mean_tready: out STD_LOGIC;
        
sqrd_dev_tvalid: out STD_LOGIC;
sqrd_dev_tdata: out STD_LOGIC_VECTOR(31 downto 0);
sqrd_dev_tready: in STD_LOGIC;

x_minus_mean_tvalid: out STD_LOGIC;
x_minus_mean_tdata: out STD_LOGIC_VECTOR(31 downto 0);
x_minus_mean_tready: in STD_LOGIC;

mean_init_comp: in STD_LOGIC;
init_complete: out STD_LOGIC);
end component;

signal aclk: STD_LOGIC := '0';
signal aresetn: STD_LOGIC := '0';
        
signal x_tvalid: STD_LOGIC := '0';
signal x_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal x_tready: STD_LOGIC := '0';
        
signal mean_tvalid: STD_LOGIC := '0';
signal mean_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal mean_tready: STD_LOGIC := '0';
        
signal sqrd_dev_tvalid: STD_LOGIC := '0';
signal sqrd_dev_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal sqrd_dev_tready: STD_LOGIC := '0';

signal x_minus_mean_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal x_minus_mean_tvalid: STD_LOGIC := '0';
signal x_minus_mean_tready: STD_LOGIC := '0';

signal mean_init_comp: STD_LOGIC := '0';
signal init_complete: STD_LOGIC := '0';

constant clk_period : time := 10 ns;

begin

sqrd_dev_component: sqrd_dev
generic map ( SAMPLE_SIZE => 64)
port map ( aclk => aclk,
aresetn => aresetn,
        
x_tvalid => x_tvalid,
x_tdata => x_tdata,
x_tready => x_tready,
        
mean_tvalid => mean_tvalid,
mean_tdata => mean_tdata,
mean_tready => mean_tready,
        
sqrd_dev_tvalid => sqrd_dev_tvalid,
sqrd_dev_tdata => sqrd_dev_tdata,
sqrd_dev_tready => sqrd_dev_tready,

x_minus_mean_tvalid => x_minus_mean_tvalid,
x_minus_mean_tdata => x_minus_mean_tdata,
x_minus_mean_tready => x_minus_mean_tready,

mean_init_comp => mean_init_comp,
init_complete => init_complete);

sqrd_dev_tready <= '1';
x_minus_mean_tready <= '1';
mean_init_comp <= '1';

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
    
    for i in 1 to 64 loop
        wait until rising_edge(aclk) and x_tready = '1';
        x_tdata <= x"42c80000"; --100
        x_tvalid <= '1';
    end loop;
    
    for i in 1 to 69 loop
        wait until rising_edge(aclk) and x_tready = '1';
        case i is
            when 1 to 10 => x_tdata <= x"3f800000"; -- 1.0
            when 11 to 20 => x_tdata <= x"3f99999a"; -- 1.2
            when 21 to 30 => x_tdata <= x"3fb33333"; -- 1.4
            when 31 to 40 => x_tdata <= x"3fa66666"; -- 1.3
            when 41 to 50 => x_tdata <= x"3fcccccd"; -- 1.6
            when 51 to 60 => x_tdata <= x"3fe66666"; -- 1.8
            when 61 to 64 => x_tdata <= x"3f8ccccd"; -- 1.1
            when others => x_tdata <= x"3fc00000"; -- 1.5
        end case;
        x_tvalid <= '1';
    end loop;

    wait until rising_edge(aclk);
    x_tvalid <= '0';

    wait for clk_period * 10;
    
    for i in 1 to 69 loop
        wait until rising_edge(aclk) and mean_tready = '1';
        case i is
            when 1 => mean_tdata <= x"3fbbcccd"; -- 1.467187
            when 2 => mean_tdata <= x"3fbacccd"; -- 1.459375
            when 3 => mean_tdata <= x"3fb9cccd"; -- 1.451562
            when 4 => mean_tdata <= x"3fb8cccd"; -- 1.443750
            when 5 => mean_tdata <= x"3fb7cccd"; -- 1.435937
            when 6 => mean_tdata <= x"3fb6cccd"; -- 1.428125
            when 7 => mean_tdata <= x"3fb5cccd"; -- 1.420312
            when 8 => mean_tdata <= x"3fb4cccd"; -- 1.412500
            when 9 => mean_tdata <= x"3fb3cccd"; -- 1.404687
            when 10 => mean_tdata <= x"3fb2cccd"; -- 1.396875
            when 11 => mean_tdata <= x"3fb23333"; -- 1.392187
            when 12 => mean_tdata <= x"3fb1999a"; -- 1.387500
            when 13 => mean_tdata <= x"3fb10000"; -- 1.382812
            when 14 => mean_tdata <= x"3fb06666"; -- 1.378125
            when 15 => mean_tdata <= x"3fafcccd"; -- 1.373437
            when 16 => mean_tdata <= x"3faf3333"; -- 1.368750
            when 17 => mean_tdata <= x"3fae999a"; -- 1.364062
            when 18 => mean_tdata <= x"3fae0000"; -- 1.359375
            when 19 => mean_tdata <= x"3fad6666"; -- 1.354688
            when 20 => mean_tdata <= x"3faccccd"; -- 1.350000
            when 21 => mean_tdata <= x"3fad0000"; -- 1.351563
            when 22 => mean_tdata <= x"3fad3333"; -- 1.353125
            when 23 => mean_tdata <= x"3fad6666"; -- 1.354688
            when 24 => mean_tdata <= x"3fad999a"; -- 1.356250
            when 25 => mean_tdata <= x"3fadcccd"; -- 1.357813
            when 26 => mean_tdata <= x"3fae0000"; -- 1.359375
            when 27 => mean_tdata <= x"3fae3333"; -- 1.360938
            when 28 => mean_tdata <= x"3fae6666"; -- 1.362500
            when 29 => mean_tdata <= x"3fae999a"; -- 1.364063
            when 30 => mean_tdata <= x"3faecccd"; -- 1.365625
            when 31 to 40 => mean_tdata <= x"3faecccd"; -- 1.365625
            when 41 => mean_tdata <= x"3fae999a"; -- 1.364063
            when 42 => mean_tdata <= x"3fae6666"; -- 1.362500
            when 43 => mean_tdata <= x"3fae3333"; -- 1.360938
            when 44 => mean_tdata <= x"3fae0000"; -- 1.359375
            when 45 => mean_tdata <= x"3fadcccd"; -- 1.357813
            when 46 => mean_tdata <= x"3fad999a"; -- 1.356250
            when 47 => mean_tdata <= x"3fad6666"; -- 1.354688
            when 48 => mean_tdata <= x"3fad3333"; -- 1.353125
            when 49 => mean_tdata <= x"3fad0000"; -- 1.351563
            when 50 => mean_tdata <= x"3faccccd"; -- 1.350000
            when 51 => mean_tdata <= x"3fad0000"; -- 1.351563
            when 52 => mean_tdata <= x"3fad3333"; -- 1.353125
            when 53 => mean_tdata <= x"3fad6666"; -- 1.354687
            when 54 => mean_tdata <= x"3fad999a"; -- 1.356250
            when 55 => mean_tdata <= x"3fadcccd"; -- 1.357812
            when 56 => mean_tdata <= x"3fae0000"; -- 1.359375
            when 57 => mean_tdata <= x"3fae3333"; -- 1.360937
            when 58 => mean_tdata <= x"3fae6666"; -- 1.362500
            when 59 => mean_tdata <= x"3fae999a"; -- 1.364062
            when 60 => mean_tdata <= x"3faecccd"; -- 1.365625
            when 61 to 64 => mean_tdata <= x"3faecccd"; -- 1.365625
            when 65 => mean_tdata <= x"3fafcccd"; -- 1.373437 
            when 66 => mean_tdata <= x"3fb0cccd"; -- 1.381250 
            when 67 => mean_tdata <= x"3fb1cccd"; -- 1.389062 
            when 68 => mean_tdata <= x"3fb2cccd"; -- 1.396875 
            when others => mean_tdata <= x"3fb3cccd"; -- 1.404687
        end case;
        mean_tvalid <= '1';
    end loop;
    
    wait until rising_edge(aclk);
    mean_tvalid <= '0';
    
    wait;
end process;

end architecture;
