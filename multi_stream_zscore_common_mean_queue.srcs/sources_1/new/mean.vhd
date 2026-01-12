library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

entity mean is
generic ( NUM_STREAMS: integer := 2; 
SAMPLE_SIZE_INT: integer := 64;
SAMPLE_SIZE_HEX: STD_LOGIC_VECTOR(31 downto 0) := x"42800000");
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;

x_tvalid: in STD_LOGIC;
x_tready: out STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0);
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);
x_id: in STD_LOGIC_VECTOR(15 downto 0);

mean_tvalid: out STD_LOGIC;
mean_tready: in STD_LOGIC;
mean_tdata: out STD_LOGIC_VECTOR(31 downto 0);
mean_id: out STD_LOGIC_VECTOR(15 downto 0);
init_complete: out STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0));
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

type streamtype is array (0 to NUM_STREAMS-1) of STD_LOGIC_VECTOR(31 downto 0);

signal x_tdata_streams: streamtype := (others => (others => '0'));
signal x_tvalid_streams: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');
signal x_tready_streams: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');

signal init_complete_streams: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');
signal mean_tvalid_signal: STD_LOGIC := '0';
signal mean_id_signal: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

signal sum_tvalid_streams: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');
signal sum_tdata_streams: streamtype := (others => (others => '0'));
signal sum_tready_streams: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');

signal div_sum_tvalid: STD_LOGIC := '0';
signal div_sum_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal div_ready_a: STD_LOGIC := '0';
signal div_ready_b: STD_LOGIC := '0';
signal div_ready_a_pulse_done: STD_LOGIC := '0';

signal fifo_m_tvalid: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');
signal fifo_m_tready: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');
signal fifo_m_tdata: streamtype := (others => (others => '0'));

signal fifo_select : integer range 0 to NUM_STREAMS-1 := 0;
signal id_select : integer range 0 to NUM_STREAMS-1 := 0;
signal fifo_ready_pulse : std_logic_vector(NUM_STREAMS-1 downto 0) := (others => '0');

signal mean_tvalid_signal_reg : std_logic := '0';

begin

x_tready <= x_tready_streams;
init_complete <= init_complete_streams;
mean_tvalid <= mean_tvalid_signal;

mean_id <= mean_id_signal;

-- take inputs
process(aclk)
begin
if rising_edge(aclk) then
    x_tvalid_streams <= (others => '0');
    x_tvalid_streams(conv_integer(x_id)) <= x_tvalid;
    
    x_tdata_streams <= (others => (others => '0'));
    x_tdata_streams(conv_integer(x_id)) <= x_tdata;
end if;
end process;

-- round robin div
process(aclk)
begin
    if rising_edge(aclk) then
        if aresetn = '0' then
            fifo_select <= 0;
            fifo_ready_pulse <= (others => '0');
        else
            if fifo_m_tvalid(fifo_select) = '1' and div_ready_a = '1' then
                fifo_ready_pulse <= (others => '0');
                fifo_ready_pulse(fifo_select) <= '1';
                
                if fifo_select = NUM_STREAMS - 1 then
                    fifo_select <= 0;
                else
                    fifo_select <= fifo_select + 1;
                end if;
            else
                fifo_ready_pulse <= (others => '0');
            end if;
        end if;
    end if;
end process;

-- send id with result
process(aclk)
begin
    if rising_edge(aclk) then
        if (mean_tvalid_signal = '1' and mean_tvalid_signal_reg = '0') or (mean_tvalid_signal = '1' and mean_tvalid_signal_reg = '1') then           
                if id_select = NUM_STREAMS-1 then
                    id_select <= 0;
                else
                    id_select <= id_select + 1;
                end if;    
        end if;

        mean_tvalid_signal_reg <= mean_tvalid_signal;
    end if;
end process;

mean_id_signal <= std_logic_vector(to_unsigned(id_select, 16));

fifo_m_tready <= fifo_ready_pulse;

div_sum_tvalid <= fifo_m_tvalid(fifo_select);
div_sum_tdata  <= fifo_m_tdata(fifo_select);

sum_buffering_instances: for i in 0 to NUM_STREAMS-1
generate sum_buffering_inst_i: sum_buffering
         generic map ( SAMPLE_SIZE => SAMPLE_SIZE_INT)
         port map ( aclk => aclk,
         aresetn => aresetn,

         x_tvalid => x_tvalid_streams(i),
         x_tready => x_tready_streams(i),
         x_tdata => x_tdata_streams(i),

         sum_tvalid => sum_tvalid_streams(i),
         sum_tready => sum_tready_streams(i),
         sum_tdata => sum_tdata_streams(i),
         init_complete => init_complete_streams(i));
end generate;

fifo_instances: for i in 0 to NUM_STREAMS-1
generate fifo_inst_i: fifo32x16_buffering
    port map ( s_axis_aresetn => aresetn,
    s_axis_aclk => aclk,

    s_axis_tvalid => sum_tvalid_streams(i),
    s_axis_tready => sum_tready_streams(i),
    s_axis_tdata => sum_tdata_streams(i),
            
    m_axis_tvalid => fifo_m_tvalid(i),
    m_axis_tready => fifo_m_tready(i),
    m_axis_tdata => fifo_m_tdata(i));
end generate;

div_inst : fp_div
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => div_sum_tvalid,
s_axis_a_tdata => div_sum_tdata,
s_axis_a_tready => div_ready_a,
            
s_axis_b_tvalid => '1',
s_axis_b_tdata => SAMPLE_SIZE_HEX,
s_axis_b_tready => div_ready_b,
            
m_axis_result_tvalid => mean_tvalid_signal,
m_axis_result_tdata => mean_tdata,
m_axis_result_tready => mean_tready);

end architecture;
