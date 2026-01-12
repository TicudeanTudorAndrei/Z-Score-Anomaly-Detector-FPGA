library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity std_dev is
generic ( SAMPLE_SIZE_INT : integer := 64;
SAMPLE_SIZE_HEX: STD_LOGIC_VECTOR(31 downto 0) := x"42800000");
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;
        
x_tvalid: in STD_LOGIC;
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);
x_tready: out STD_LOGIC;
        
mean_tvalid: in STD_LOGIC;
mean_tdata: in STD_LOGIC_VECTOR(31 downto 0);
mean_tready: out STD_LOGIC;
  
std_dev_tvalid: out STD_LOGIC;
std_dev_tdata: out STD_LOGIC_VECTOR(31 downto 0);
std_dev_tready: in STD_LOGIC;

x_minus_mean_tvalid: out STD_LOGIC;
x_minus_mean_tdata: out STD_LOGIC_VECTOR(31 downto 0);
x_minus_mean_tready: in STD_LOGIC;

mean_init_comp: in STD_LOGIC;
init_complete: out STD_LOGIC);
end entity;

architecture std_dev_arh of std_dev is

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

component fp_div is
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;

s_axis_a_tvalid: in STD_LOGIC;
s_axis_a_tready: out STD_LOGIC;
s_axis_a_tdata: in STD_LOGIC_VECTOR(31 downto 0);

s_axis_b_tvalid: in STD_LOGIC;
s_axis_b_tready: out STD_LOGIC;
s_axis_b_tdata: in STD_LOGIC_VECTOR(31 downto 0);

m_axis_result_tvalid: out STD_LOGIC;
m_axis_result_tready: in STD_LOGIC;
m_axis_result_tdata: out STD_LOGIC_VECTOR(31 downto 0));
end component;

component fp_sqrt is
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;

s_axis_a_tvalid: in STD_LOGIC;
s_axis_a_tready: out STD_LOGIC;
s_axis_a_tdata: in STD_LOGIC_VECTOR(31 downto 0);

m_axis_result_tvalid: out STD_LOGIC;
m_axis_result_tready: in STD_LOGIC;
m_axis_result_tdata: out STD_LOGIC_VECTOR(31 downto 0));
end component;

signal sqrddev_tvalid: STD_LOGIC := '0';
signal sqrddev_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal div_a_tready: STD_LOGIC := '0';
signal div_b_tready: STD_LOGIC := '0';

signal div_m_tvalid: STD_LOGIC := '0';
signal div_m_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal sqrt_a_tready: STD_LOGIC := '0';

begin

sqrd_dev_inst: sqrd_dev
generic map ( SAMPLE_SIZE => SAMPLE_SIZE_INT)
port map ( aclk => aclk,
aresetn => aresetn,
        
x_tvalid => x_tvalid,
x_tdata => x_tdata,
x_tready => x_tready,
        
mean_tvalid => mean_tvalid,
mean_tdata => mean_tdata,
mean_tready => mean_tready,
        
sqrd_dev_tvalid => sqrddev_tvalid,
sqrd_dev_tdata => sqrddev_tdata,
sqrd_dev_tready => div_a_tready,

x_minus_mean_tvalid => x_minus_mean_tvalid,
x_minus_mean_tdata => x_minus_mean_tdata,
x_minus_mean_tready => x_minus_mean_tready,

mean_init_comp => mean_init_comp,
init_complete => init_complete);

div_inst: fp_div
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => sqrddev_tvalid,
s_axis_a_tready => div_a_tready,
s_axis_a_tdata => sqrddev_tdata,

s_axis_b_tvalid => '1',
s_axis_b_tready => div_b_tready,
s_axis_b_tdata => SAMPLE_SIZE_HEX,

m_axis_result_tvalid => div_m_tvalid,
m_axis_result_tready => sqrt_a_tready,
m_axis_result_tdata => div_m_tdata);

sqrt_inst: fp_sqrt
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => div_m_tvalid,
s_axis_a_tready => sqrt_a_tready,
s_axis_a_tdata => div_m_tdata,

m_axis_result_tvalid => std_dev_tvalid,
m_axis_result_tready => std_dev_tready,
m_axis_result_tdata => std_dev_tdata);

end architecture;
