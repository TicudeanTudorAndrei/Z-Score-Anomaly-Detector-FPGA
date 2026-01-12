library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity zscore is
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
end entity;

architecture zscore_arh of zscore is

component mean is
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
end component;

component std_dev is
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
end component;

component fp_div_buffering is
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

signal broadcaster_tdata: STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
signal broadcaster_tvalid: STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
signal broadcaster_tready: STD_LOGIC_VECTOR(1 downto 0) := (others => '0');

component fp_broadcaster is
port ( aclk: in std_logic;
aresetn: in std_logic;
s_axis_tvalid: in std_logic;
s_axis_tready: out std_logic;
s_axis_tdata: in std_logic_vector(31 downto 0);
m_axis_tvalid: out std_logic_vector(1 downto 0);
m_axis_tready: in std_logic_vector(1 downto 0);
m_axis_tdata: out std_logic_vector(63 downto 0));
end component;

signal mean_x_tready: STD_LOGIC := '0';
signal mean_m_tready: STD_LOGIC := '0';
signal std_dev_x_tready: STD_LOGIC := '0';
signal std_dev_m_tvalid: STD_LOGIC := '0';
signal std_dev_m_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal and_x_tready: STD_LOGIC := '0';

signal div_a_tready: STD_LOGIC := '0';
signal div_b_tready: STD_LOGIC := '0';

signal mean_m_tvalid: STD_LOGIC := '0';
signal mean_m_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal mean_m_init_complete: STD_LOGIC := '0';
signal std_dev_m_init_complete: STD_LOGIC := '0';

signal x_minus_mean_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal x_minus_mean_tvalid: STD_LOGIC := '0';

begin

fp_broadcast_inst: fp_broadcaster
port map ( aclk => aclk,
aresetn => aresetn,
s_axis_tvalid => x_tvalid,
s_axis_tready => x_tready,
s_axis_tdata => x_tdata,
m_axis_tvalid => broadcaster_tvalid,
m_axis_tready => broadcaster_tready,
m_axis_tdata => broadcaster_tdata);

init_complete <= std_dev_m_init_complete;

mean_inst: mean
generic map ( SAMPLE_SIZE_INT => SAMPLE_SIZE_INT,
SAMPLE_SIZE_HEX => SAMPLE_SIZE_HEX)
port map ( aclk => aclk,
aresetn => aresetn,

x_tvalid => broadcaster_tvalid(0),
x_tready => broadcaster_tready(0),
x_tdata => broadcaster_tdata(63 downto 32),

mean_tvalid => mean_m_tvalid,
mean_tready => mean_m_tready,
mean_tdata => mean_m_tdata,
init_complete => mean_m_init_complete);

std_dev_inst: std_dev
generic map ( SAMPLE_SIZE_INT => SAMPLE_SIZE_INT,
SAMPLE_SIZE_HEX => SAMPLE_SIZE_HEX)
port map ( aclk => aclk,
aresetn => aresetn,
        
x_tvalid => broadcaster_tvalid(1),
x_tdata => broadcaster_tdata(31 downto 0),
x_tready => broadcaster_tready(1),
        
mean_tvalid => mean_m_tvalid,
mean_tdata => mean_m_tdata,
mean_tready => mean_m_tready,
        
std_dev_tvalid => std_dev_m_tvalid,
std_dev_tdata => std_dev_m_tdata,
std_dev_tready => div_b_tready,

x_minus_mean_tvalid => x_minus_mean_tvalid,
x_minus_mean_tdata => x_minus_mean_tdata,
x_minus_mean_tready => div_a_tready,

mean_init_comp => mean_m_init_complete,
init_complete => std_dev_m_init_complete);

div_inst: fp_div_buffering
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => x_minus_mean_tvalid,
s_axis_a_tready => div_a_tready,
s_axis_a_tdata => x_minus_mean_tdata,

s_axis_b_tvalid => std_dev_m_tvalid,
s_axis_b_tready => div_b_tready,
s_axis_b_tdata => std_dev_m_tdata,

m_axis_result_tvalid => zscore_tvalid,
m_axis_result_tready => zscore_tready,
m_axis_result_tdata => zscore_tdata);

end architecture;