library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity zscore is
generic ( NUM_STREAMS: integer := 2;
SAMPLE_SIZE_INT : integer := 64;
SAMPLE_SIZE_HEX: STD_LOGIC_VECTOR(31 downto 0) := x"42800000");
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;
        
x_tvalid: in STD_LOGIC;
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);
x_tready: out STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0);
x_id: in STD_LOGIC_VECTOR(15 downto 0); 
        
zscore_tvalid: out STD_LOGIC;
zscore_tdata: out STD_LOGIC_VECTOR(31 downto 0);
zscore_tready: in STD_LOGIC;
zscore_id: out STD_LOGIC_VECTOR(15 downto 0); 

init_complete: out STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0));
end entity;

architecture zscore_arh of zscore is

component mean is
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
end component;

component std_dev is
generic ( NUM_STREAMS: integer := 2;
SAMPLE_SIZE_INT : integer := 64;
SAMPLE_SIZE_HEX: STD_LOGIC_VECTOR(31 downto 0) := x"42800000");
port ( aclk: in STD_LOGIC;
aresetn: in STD_LOGIC;
        
x_tvalid: in STD_LOGIC;
x_tdata: in STD_LOGIC_VECTOR(31 downto 0);
x_tready: out STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0);
x_id: in STD_LOGIC_VECTOR(15 downto 0);
        
mean_tvalid: in STD_LOGIC;
mean_tdata: in STD_LOGIC_VECTOR(31 downto 0);
mean_tready: out STD_LOGIC;
mean_id: in STD_LOGIC_VECTOR(15 downto 0);
  
std_dev_tvalid: out STD_LOGIC;
std_dev_tdata: out STD_LOGIC_VECTOR(31 downto 0);
std_dev_tready: in STD_LOGIC;
std_dev_id: out STD_LOGIC_VECTOR(15 downto 0);

x_minus_mean_tvalid: out STD_LOGIC;
x_minus_mean_tdata: out STD_LOGIC_VECTOR(31 downto 0);
x_minus_mean_tready: in STD_LOGIC;
x_minus_mean_id: out STD_LOGIC_VECTOR(15 downto 0);

mean_init_comp: in STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0);
init_complete: out STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0));
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

signal std_dev_tvalid: STD_LOGIC := '0';
signal std_dev_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal std_dev_init_complete: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0);
signal std_dev_id_signal: STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 

signal div_a_tready: STD_LOGIC := '0';
signal div_b_tready: STD_LOGIC := '0';

signal mean_tready: STD_LOGIC := '0';
signal mean_id: STD_LOGIC_VECTOR(15 downto 0); 
signal mean_tvalid_signal: STD_LOGIC := '0';
signal mean_tvalid: STD_LOGIC := '0';
signal mean_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal mean_init_complete: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0);
signal mean_tready_signals: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');

signal x_minus_mean_tdata: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
signal x_minus_mean_tvalid: STD_LOGIC := '0';
signal x_minus_mean_id_signal: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

signal x_tready_mean: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');
signal x_tready_std: STD_LOGIC_VECTOR(NUM_STREAMS-1 downto 0) := (others => '0');

signal ready_mean_select : integer range 0 to NUM_STREAMS-1 := 0;

signal zscore_tvalid_signal: STD_LOGIC := '0';
signal zscore_id_signal: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal zscore_id_select : integer range 0 to NUM_STREAMS-1 := 0;

signal zscore_tvalid_signal_reg : std_logic := '0';

begin

init_complete <= std_dev_init_complete;
zscore_tvalid <= zscore_tvalid_signal;

zscore_id <= zscore_id_signal;

mean_inst: mean
generic map ( NUM_STREAMS => NUM_STREAMS,
SAMPLE_SIZE_INT => SAMPLE_SIZE_INT,
SAMPLE_SIZE_HEX => SAMPLE_SIZE_HEX)
port map ( aclk => aclk,
aresetn => aresetn,

x_tvalid => x_tvalid,
x_tready => x_tready_mean,
x_tdata => x_tdata,
x_id => x_id,

mean_tvalid => mean_tvalid,
mean_tready => '1',
mean_tdata => mean_tdata,
mean_id => mean_id,

init_complete => mean_init_complete);

-- select tready signal for mean
-- process(aclk, mean_tvalid)
-- begin
-- if rising_edge(aclk) or mean_tvalid'event then
    -- if mean_tvalid = '1' then
        --mean_tready <= mean_tready_signals(ready_mean_select); 
        
        -- if ready_mean_select = NUM_STREAMS-1 then
            -- ready_mean_select <= 0;
        -- else
            -- ready_mean_select <= ready_mean_select + 1;
        -- end if;    
    -- end if;
-- end if;    
-- end process;

-- AND x_tready
process(x_tready_mean, x_tready_std)
begin
    for i in 0 to NUM_STREAMS-1 loop
        x_tready(i) <= x_tready_mean(i) and x_tready_std(i);      
    end loop;
end process;

std_dev_inst: std_dev
generic map ( NUM_STREAMS => NUM_STREAMS,
SAMPLE_SIZE_INT => SAMPLE_SIZE_INT,
SAMPLE_SIZE_HEX => SAMPLE_SIZE_HEX)
port map ( aclk => aclk,
aresetn => aresetn,
        
x_tvalid => x_tvalid,
x_tdata => x_tdata,
x_tready => x_tready_std,
x_id => x_id,
        
mean_tvalid => mean_tvalid,
mean_tdata => mean_tdata,
mean_tready => mean_tready,
mean_id => mean_id,
        
std_dev_tvalid => std_dev_tvalid,
std_dev_tdata => std_dev_tdata,
std_dev_tready => div_b_tready,
std_dev_id => std_dev_id_signal,

x_minus_mean_tvalid => x_minus_mean_tvalid,
x_minus_mean_tdata => x_minus_mean_tdata,
x_minus_mean_tready => div_a_tready,
x_minus_mean_id => x_minus_mean_id_signal,

mean_init_comp => mean_init_complete,
init_complete => std_dev_init_complete);

div_inst: fp_div_buffering
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => x_minus_mean_tvalid,
s_axis_a_tready => div_a_tready,
s_axis_a_tdata => x_minus_mean_tdata,

s_axis_b_tvalid => std_dev_tvalid,
s_axis_b_tready => div_b_tready,
s_axis_b_tdata => std_dev_tdata,

m_axis_result_tvalid => zscore_tvalid_signal,
m_axis_result_tready => zscore_tready,
m_axis_result_tdata => zscore_tdata);

-- send id with result
process(aclk)
begin
    if rising_edge(aclk) then
        if (zscore_tvalid_signal = '1' and zscore_tvalid_signal_reg = '0') or (zscore_tvalid_signal = '1' and zscore_tvalid_signal_reg = '1') then
            if zscore_id_select = NUM_STREAMS - 1 then
                zscore_id_select <= 0;
            else
                zscore_id_select <= zscore_id_select + 1;
            end if;
        end if;
        
        zscore_tvalid_signal_reg <= zscore_tvalid_signal;
    end if;
end process;

zscore_id_signal <= std_logic_vector(to_unsigned(zscore_id_select, 16));

end architecture;