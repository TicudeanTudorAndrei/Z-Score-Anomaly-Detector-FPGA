library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity sum is
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

architecture sum_arch of sum is

component fifo32xN_sample is
port ( s_axis_aresetn: in STD_LOGIC;
s_axis_aclk: in STD_LOGIC;

s_axis_tvalid: in STD_LOGIC;
s_axis_tready: out STD_LOGIC;
s_axis_tdata: in STD_LOGIC_VECTOR(31 downto 0);

m_axis_tvalid: out STD_LOGIC;
m_axis_tready: in STD_LOGIC;
m_axis_tdata: out STD_LOGIC_VECTOR(31 downto 0));
end component;

component fp_acc is
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;

s_axis_a_tvalid: in STD_LOGIC;
s_axis_a_tready: out STD_LOGIC;
s_axis_a_tdata: in STD_LOGIC_VECTOR(31 downto 0);
s_axis_a_tlast: in STD_LOGIC;

s_axis_operation_tvalid: in STD_LOGIC;
s_axis_operation_tready: out STD_LOGIC;
s_axis_operation_tdata: in STD_LOGIC_VECTOR(7 downto 0);

m_axis_result_tvalid: out STD_LOGIC;
m_axis_result_tready: in STD_LOGIC;
m_axis_result_tdata: out STD_LOGIC_VECTOR(31 downto 0);
m_axis_result_tlast: out STD_LOGIC);
end component;

signal fifo_s_tvalid: STD_LOGIC;
signal fifo_s_tready: STD_LOGIC;
signal fifo_s_tdata: STD_LOGIC_VECTOR(31 downto 0);

signal fifo_m_tvalid: STD_LOGIC;
signal fifo_m_tready: STD_LOGIC;
signal fifo_m_tdata: STD_LOGIC_VECTOR(31 downto 0);

signal acc_s_tvalid: STD_LOGIC;
signal acc_s_tready: STD_LOGIC;
signal acc_s_tdata: STD_LOGIC_VECTOR(31 downto 0);
signal acc_s_tlast: STD_LOGIC := '0';

signal acc_s_op_tready: STD_LOGIC;
signal acc_s_op_tvalid: STD_LOGIC;
signal acc_s_op_tdata: STD_LOGIC_VECTOR(7 downto 0);

signal acc_m_tvalid: STD_LOGIC;
signal acc_m_tready: STD_LOGIC;
signal acc_m_tdata: STD_LOGIC_VECTOR(31 downto 0);
signal acc_m_tlast: STD_LOGIC;
signal first_subtraction_done : STD_LOGIC := '0';

signal sum_tvalid_up: STD_LOGIC := '0';
signal sum_tvalid_fn: STD_LOGIC := '0';
signal acc_m_tvalid_control: STD_LOGIC := '0';
signal count_tvalid: integer range 0 to 1 := 0;

signal and_sum_x_tready: STD_LOGIC;
signal and_x_tvalid: STD_LOGIC;

signal add_or_sub: STD_LOGIC := '0';

signal fifo_m_tready_pulse: STD_LOGIC := '0';
signal acc_a_and_op_tvalid_pulse: STD_LOGIC := '0';
signal acc_m_result_tready_pulse: STD_LOGIC := '0';
signal pulse_done: STD_LOGIC := '0';
signal full_sample: STD_LOGIC := '0';

signal mux_acc_m_result_tready: STD_LOGIC := '0';
signal mux_acc_m_result_tvalid: STD_LOGIC := '0';

signal count: integer range 0 to SAMPLE_SIZE := 0;
signal acc_free_mux: STD_LOGIC := '1';
signal acc_free_init: STD_LOGIC := '1';
signal acc_free_running: STD_LOGIC := '1';

begin

process(aclk)
begin
    if rising_edge(aclk) then
        if aresetn = '0' then
            count <= 0;
            add_or_sub <= '0';
            full_sample <= '0';
            acc_free_init <= '1';
            acc_free_running <= '1';
        else
            if x_tvalid = '1' and count < SAMPLE_SIZE - 1 and full_sample = '0' then -- if not yet finished initialization, count number and keep adding
                count <= count + 1;
                add_or_sub <= '0';
                acc_free_init <= '0'; -- acc is now busy
            elsif acc_m_tvalid = '1' and count <= SAMPLE_SIZE - 1 and acc_free_init = '0' then -- when a number is added in initialization phase, permit a new one to enter
                acc_free_init <= '1'; -- acc is now free
            elsif x_tvalid = '1' and count = SAMPLE_SIZE - 1 and full_sample = '0' then -- when last number in initialization state is finally processed
                full_sample <= '1'; -- assert full_sample
                acc_free_running <= '0'; -- acc is now busy
                add_or_sub <= '1';  -- start subtraction (go to 1)
            elsif x_tvalid = '1' and count = SAMPLE_SIZE - 1 and full_sample = '1' and acc_free_running = '1' then -- wehn a new number arrives (post initialization process)
                acc_free_running <= '0'; -- acc is now busy
                add_or_sub <= '1';  -- start subtraction (go to 1)
            elsif acc_m_tvalid = '1' and count = SAMPLE_SIZE - 1 and acc_free_running = '0' then -- when a number is added in normal phase, permit a new one to enter
                acc_free_running <= '1'; -- acc is now free
            end if;
        end if;
        
        if add_or_sub = '1' and acc_m_tvalid = '1' then -- (return here after finishing process down below) in subtract mode, a result of subtraction will be produced
            acc_m_result_tready_pulse <= '1'; -- make sure that the accumulator can output it
        elsif add_or_sub = '1' and acc_m_tvalid = '0' and acc_m_result_tready_pulse = '1' then -- after result is produced and pulse for accumulator result and go back to addition mode
            acc_m_result_tready_pulse <= '0';
            add_or_sub <= '0';
        end if;
    end if;
end process;

process(aclk)
begin
    if rising_edge(aclk) then
        if aresetn = '0' then
            fifo_m_tready_pulse <= '0';
            acc_a_and_op_tvalid_pulse <= '0';
            pulse_done <= '0';
        else
            if add_or_sub = '1' and pulse_done = '0' then -- (1 is here) subtraction started,
                fifo_m_tready_pulse <= '1'; -- send pulse to fifo to POP number
                acc_a_and_op_tvalid_pulse <= '1'; -- send pulse to accumulator to accept the POPPED number
                pulse_done <= '1'; -- signal to end pulse next clock (go to 2)
            elsif add_or_sub = '1' and pulse_done = '1' then -- (2 is here) still in subtraction mode, but end of pulse was signaled 
                fifo_m_tready_pulse <= '0'; -- deactivate pulse for fifo
                acc_a_and_op_tvalid_pulse <= '0'; -- deactivate pulse for accumulator
            elsif add_or_sub = '0' then -- when not in subtraction mode (like a constant reset for subtraction related signals)
                pulse_done <= '0';
                fifo_m_tready_pulse <= '0';
                acc_a_and_op_tvalid_pulse <= '0';
            end if;
        end if;
    end if;
end process;

process(aclk)
begin
    if rising_edge(aclk) then
        if sum_tvalid_up = '1' and count_tvalid = 0 and acc_m_tvalid_control <= '0' then
            count_tvalid <= count_tvalid + 1;
            acc_m_tvalid_control <= '1';
        elsif sum_tvalid_up = '1' and count_tvalid = 1 and acc_m_tvalid_control <= '1' then
            count_tvalid <= 0;
            acc_m_tvalid_control <= '0';
            first_subtraction_done <= '1';
        end if;
    end if;
end process;

acc_s_tlast <= '0';

-- ACC_FREE MUX
with full_sample select
acc_free_mux <= acc_free_init when '0',
                acc_free_running when others;

-- AND-GATE x_tready
and_sum_x_tready <= acc_s_tready and acc_s_op_tready and fifo_s_tready and acc_free_mux;
-- AND-GATE x_tvalid
and_x_tvalid <= acc_a_and_op_tvalid_pulse and fifo_m_tvalid;
-- MUX x_tready
with add_or_sub select
x_tready <= and_sum_x_tready when '0',
            '0' when others; 

-- MUX sum_tvalid_1
with full_sample select
mux_acc_m_result_tvalid <= '0' when '0',
                           acc_m_tvalid when others;
-- MUX sum_tvalid_2
with add_or_sub select
sum_tvalid_up <= '0' when '0',
                 mux_acc_m_result_tvalid when others;

with acc_m_tvalid_control select
sum_tvalid_fn <= sum_tvalid_up when '0',
                 '0' when others;

with first_subtraction_done select
sum_tvalid <= '0' when '0',
              sum_tvalid_fn when others;

sum_tdata <= acc_m_tdata;

fifo_m_tready <= fifo_m_tready_pulse;

fifo_s_tdata <= x_tdata;

-- MUX fifo_s_axis_tvalid
with add_or_sub select
fifo_s_tvalid <= x_tvalid when '0',
                 '0' when others;

-- MUX acc_s_axis_a_tvalid
with add_or_sub select
acc_s_tvalid <= x_tvalid when '0',
                and_x_tvalid when others;
-- MUX acc_s_axis_operation_tvalid
with add_or_sub select
acc_s_op_tvalid <= x_tvalid when '0',
                   and_x_tvalid when others;
-- MUX acc_s_axis_operation_tdata
with add_or_sub select
acc_s_op_tdata <= "00000000" when '0',
                  "00000001" when others;           
-- MUX acc_s_axis_a_tdata
with add_or_sub select
acc_s_tdata <= x_tdata when '0',
               fifo_m_tdata when others;                  

-- MUX acc_m_tready_1
with full_sample select
mux_acc_m_result_tready <= '1' when '0',
                           sum_tready when others;
-- MUX acc_m_tready_2
with add_or_sub select
acc_m_tready <= mux_acc_m_result_tready when '0',
                acc_m_result_tready_pulse when others;   

init_complete <= full_sample;

fifo_inst: fifo32xN_sample
port map ( s_axis_aresetn => aresetn,
s_axis_aclk => aclk,

s_axis_tvalid => fifo_s_tvalid,
s_axis_tready => fifo_s_tready,
s_axis_tdata => fifo_s_tdata,
            
m_axis_tvalid => fifo_m_tvalid,
m_axis_tready => fifo_m_tready,
m_axis_tdata => fifo_m_tdata);

acc_inst: fp_acc
port map ( aclk => aclk,
aresetn => aresetn,
            
s_axis_a_tvalid => acc_s_tvalid,
s_axis_a_tready => acc_s_tready,
s_axis_a_tdata => acc_s_tdata,            
s_axis_a_tlast => acc_s_tlast,

s_axis_operation_tvalid => acc_s_op_tvalid,
s_axis_operation_tready => acc_s_op_tready,    
s_axis_operation_tdata => acc_s_op_tdata,

m_axis_result_tvalid => acc_m_tvalid,
m_axis_result_tready => acc_m_tready,
m_axis_result_tdata => acc_m_tdata,
m_axis_result_tlast => acc_m_tlast);
 

end architecture;