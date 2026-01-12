library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity fp_div_buffering is
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
end entity;

architecture fp_div_buffering_arch of fp_div_buffering is

component fifo32x16_buffering is
port ( s_axis_aresetn: in STD_LOGIC;
s_axis_aclk: in STD_LOGIC;

s_axis_tvalid: in STD_LOGIC;
s_axis_tready: out STD_LOGIC;
s_axis_tdata: in STD_LOGIC_VECTOR(31 downto 0);

m_axis_tvalid: out STD_LOGIC;
m_axis_tready: in STD_LOGIC;
m_axis_tdata: out STD_LOGIC_VECTOR(31 downto 0));
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

signal fifo1_m_tvalid: STD_LOGIC := '0';
signal fifo1_m_tready: STD_LOGIC := '0';
signal fifo1_m_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal fifo2_m_tvalid: STD_LOGIC := '0';
signal fifo2_m_tready: STD_LOGIC := '0';
signal fifo2_m_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

begin

div_inst: fp_div
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => fifo1_m_tvalid,
s_axis_a_tready => fifo1_m_tready,
s_axis_a_tdata => fifo1_m_tdata,

s_axis_b_tvalid => fifo2_m_tvalid,
s_axis_b_tready => fifo2_m_tready,
s_axis_b_tdata => fifo2_m_tdata,

m_axis_result_tvalid => m_axis_result_tvalid,
m_axis_result_tready => m_axis_result_tready,
m_axis_result_tdata => m_axis_result_tdata);

fifo_inst_1: fifo32x16_buffering
port map ( s_axis_aresetn => aresetn,
s_axis_aclk => aclk,

s_axis_tvalid => s_axis_a_tvalid,
s_axis_tready => s_axis_a_tready,
s_axis_tdata => s_axis_a_tdata,
            
m_axis_tvalid => fifo1_m_tvalid,
m_axis_tready => fifo1_m_tready,
m_axis_tdata => fifo1_m_tdata);

fifo_inst_2: fifo32x16_buffering
port map ( s_axis_aresetn => aresetn,
s_axis_aclk => aclk,

s_axis_tvalid => s_axis_b_tvalid,
s_axis_tready => s_axis_b_tready,
s_axis_tdata => s_axis_b_tdata,
            
m_axis_tvalid => fifo2_m_tvalid,
m_axis_tready => fifo2_m_tready,
m_axis_tdata => fifo2_m_tdata);

end architecture;
