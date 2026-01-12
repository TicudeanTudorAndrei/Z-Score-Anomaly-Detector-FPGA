library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity sqrd_dev is
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
end entity;

architecture sqrd_dev_arch of sqrd_dev is

component fp_mul is
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

component fp_sub is
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

signal sub_tvalid: STD_LOGIC := '0';
signal sub_tready: STD_LOGIC := '0';
signal sub_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal mul_tvalid: STD_LOGIC := '0';
signal mul_tready: STD_LOGIC := '0';
signal mul_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal mux_a_tvalid: STD_LOGIC := '0';

signal mul_a_tready: STD_LOGIC := '0';
signal mul_b_tready: STD_LOGIC := '0';

signal sum_x_tready: STD_LOGIC := '0';

signal fifo1_m_tvalid: STD_LOGIC := '0';
signal fifo1_m_tready: STD_LOGIC := '0';
signal fifo1_m_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

signal count_sub: integer range 0 to SAMPLE_SIZE := 0;
signal send_x_minus_mean: STD_LOGIC := '0';

signal count_x: integer range 0 to SAMPLE_SIZE := 0;
signal send_x: STD_LOGIC := '0';

begin

mul_tready <= sum_x_tready;

x_minus_mean_tdata <= sub_tdata;

-- MUX x_minus_mean_tvalid
with send_x_minus_mean select
x_minus_mean_tvalid <= '0' when '0',
                        sub_tvalid when others;

-- MUX s_axis_a_tvalid
with send_x select
mux_a_tvalid <= '0' when '0',
                x_tvalid when others;

-- AND sub_tready
sub_tready <= mul_a_tready and mul_b_tready;

process(aclk)
begin
    if rising_edge(aclk) then    
        if aresetn = '0' then
                count_sub <= 0;
                send_x_minus_mean <= '0';
        else
                if sub_tvalid = '1' and count_sub < SAMPLE_SIZE - 1 and send_x_minus_mean = '0' then -- if not yet finished initialization, just count
                    count_sub <= count_sub + 1;
                    send_x_minus_mean <= '0';
                elsif sub_tvalid = '1' and count_sub = SAMPLE_SIZE - 1 and send_x_minus_mean = '0' then -- when last number in initialization state is finally processed
                    send_x_minus_mean <= '1'; -- assert send_x_minus_mean
                end if;
        end if;
    end if;
end process;

process(aclk)
begin
    if rising_edge(aclk) then    
        if aresetn = '0' then
                count_x <= 0;
                send_x <= '0';
        else
                if x_tvalid = '1' and count_x < SAMPLE_SIZE - 1 and send_x = '0' then -- if not yet finished initialization, just count
                    count_x <= count_x + 1;
                    send_x <= '0';
                elsif x_tvalid = '1' and count_x = SAMPLE_SIZE - 1 and send_x = '0' then -- when last number in initialization state is finally processed
                    send_x <= '1'; -- assert send_x
                end if;
        end if;
    end if;
end process;

fifo_inst: fifo32xN_buffering
port map ( s_axis_aresetn => aresetn,
s_axis_aclk => aclk,

s_axis_tvalid => mux_a_tvalid,
s_axis_tready => x_tready,
s_axis_tdata => x_tdata,
            
m_axis_tvalid => fifo1_m_tvalid,
m_axis_tready => fifo1_m_tready,
m_axis_tdata => fifo1_m_tdata);

sub_inst: fp_sub 
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => fifo1_m_tvalid,
s_axis_a_tdata => fifo1_m_tdata,
s_axis_a_tready => fifo1_m_tready,
            
s_axis_b_tvalid => mean_tvalid,
s_axis_b_tdata => mean_tdata,
s_axis_b_tready => mean_tready,

m_axis_result_tvalid => sub_tvalid,
m_axis_result_tdata => sub_tdata,
m_axis_result_tready => sub_tready);

mul_inst: fp_mul
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => sub_tvalid,
s_axis_a_tdata => sub_tdata,
s_axis_a_tready => mul_a_tready,
            
s_axis_b_tvalid => sub_tvalid,
s_axis_b_tdata => sub_tdata,
s_axis_b_tready => mul_b_tready,
            
m_axis_result_tvalid => mul_tvalid,
m_axis_result_tdata => mul_tdata,
m_axis_result_tready => mul_tready);

sum_inst : sum
generic map ( SAMPLE_SIZE => SAMPLE_SIZE)
port map ( aclk => aclk,
aresetn => aresetn,

x_tvalid => mul_tvalid,
x_tready => sum_x_tready,
x_tdata => mul_tdata,

sum_tvalid => sqrd_dev_tvalid,
sum_tready => sqrd_dev_tready,
sum_tdata => sqrd_dev_tdata,
init_complete => init_complete);

end architecture;