library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity mean is
generic ( SAMPLE_SIZE_INT : integer := 64;
SAMPLE_SIZE_HEX: STD_LOGIC_VECTOR(31 downto 0) := x"42800000");
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;

x_tvalid: in STD_LOGIC;
x_tready: out STD_LOGIC;
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);

mean_tvalid: out STD_LOGIC;
mean_tready: in STD_LOGIC;
mean_tdata: out STD_LOGIC_VECTOR(31 downto 0);
init_complete: out STD_LOGIC);
end entity;

architecture mean_arh of mean is

component sum_buffering is
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

signal sum_tvalid: STD_LOGIC := '0';
signal sum_tready: STD_LOGIC;
signal sum_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal div_ready_b: STD_LOGIC;

begin

sum_buffering_inst : sum_buffering
generic map ( SAMPLE_SIZE => SAMPLE_SIZE_INT)
port map ( aclk => aclk,
aresetn => aresetn,

x_tvalid => x_tvalid,
x_tready => x_tready,
x_tdata => x_tdata,

sum_tvalid => sum_tvalid,
sum_tready => sum_tready,
sum_tdata => sum_tdata,
init_complete => init_complete);

div_inst : fp_div
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => sum_tvalid,
s_axis_a_tdata => sum_tdata,
s_axis_a_tready => sum_tready,
            
s_axis_b_tvalid => '1',
s_axis_b_tdata => SAMPLE_SIZE_HEX,
s_axis_b_tready => div_ready_b,
            
m_axis_result_tvalid => mean_tvalid,
m_axis_result_tdata => mean_tdata,
m_axis_result_tready => mean_tready);

end architecture;
