library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity sum_buffering is
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
end entity;

architecture sum_buffering_arch of sum_buffering is

component sum is
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

component fifo32xN_buffering is
port ( s_axis_aresetn: in STD_LOGIC;
s_axis_aclk: in STD_LOGIC;

s_axis_tvalid: in STD_LOGIC;
s_axis_tready: out STD_LOGIC;
s_axis_tdata: in STD_LOGIC_VECTOR(31 downto 0);

m_axis_tvalid: out STD_LOGIC;
m_axis_tready: in STD_LOGIC;
m_axis_tdata: out STD_LOGIC_VECTOR(31 downto 0));
end component;

signal fifo1_m_tvalid: STD_LOGIC := '0';
signal fifo1_m_tready: STD_LOGIC := '0';
signal fifo1_m_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal fifo1_control_m_tvalid: STD_LOGIC := '0';
signal fifo1_control_m_tready: STD_LOGIC := '0';

signal sum_reading: STD_LOGIC := '0';

begin

sum_inst : sum
generic map ( SAMPLE_SIZE => SAMPLE_SIZE)
port map ( aclk => aclk,
aresetn => aresetn,

x_tvalid => fifo1_control_m_tvalid,
x_tready => fifo1_control_m_tready,
x_tdata => fifo1_m_tdata,

sum_tvalid => sum_tvalid,
sum_tready => sum_tready,
sum_tdata => sum_tdata,
init_complete => init_complete);

fifo_buffer_inst: fifo32xN_buffering
port map ( s_axis_aresetn => aresetn,
s_axis_aclk => aclk,

s_axis_tvalid => x_tvalid,
s_axis_tready => x_tready,
s_axis_tdata => x_tdata,
            
m_axis_tvalid => fifo1_m_tvalid,
m_axis_tready => fifo1_m_tready,
m_axis_tdata => fifo1_m_tdata);

-- generate m_tready and m_tvalid signals for one clock cycle so the fifo POPS out a single value to the running_sum component
process(aclk)
begin
    if rising_edge (aclk) then
        if aresetn = '0' then
            fifo1_control_m_tvalid <= '0';
            sum_reading <= '0';
        else           
            sum_reading <= '0';
            if fifo1_control_m_tready = '1' and fifo1_m_tvalid = '1' and sum_reading = '0' then
                fifo1_m_tready <= '1';
                fifo1_control_m_tvalid <= '1';
                sum_reading <= '1';
            elsif fifo1_m_tready = '1' and fifo1_control_m_tvalid = '1' then
                fifo1_m_tready <= '0';    
                fifo1_control_m_tvalid <= '0';
            end if;
        end if;
    end if;
end process;

end architecture;