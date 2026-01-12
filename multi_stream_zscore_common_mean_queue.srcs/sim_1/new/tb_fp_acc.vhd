library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity tb_fp_acc is
end entity;

architecture tb_fp_acc_arh of tb_fp_acc is

component fp_acc
port ( aclk: in std_logic;
aresetn: in std_logic;

s_axis_a_tvalid: in std_logic;
s_axis_a_tready: out std_logic;
s_axis_a_tdata: in  std_logic_vector(31 downto 0);
s_axis_a_tlast: in  std_logic;

s_axis_operation_tvalid: in  std_logic;
s_axis_operation_tready: out std_logic;
s_axis_operation_tdata: in  std_logic_vector(7 downto 0);

m_axis_result_tvalid: out std_logic;
m_axis_result_tready: in  std_logic;
m_axis_result_tdata: out std_logic_vector(31 downto 0);
m_axis_result_tlast: out std_logic);
end component;

signal aclk: std_logic := '0';
signal aresetn: std_logic := '0';

signal s_axis_a_tvalid: std_logic := '0';
signal s_axis_a_tready: std_logic;
signal s_axis_a_tdata: std_logic_vector(31 downto 0) := (others => '0');
signal s_axis_a_tlast: std_logic := '0';

signal s_axis_operation_tvalid: std_logic := '0';
signal s_axis_operation_tready: std_logic;
signal s_axis_operation_tdata: std_logic_vector(7 downto 0) := (others => '0');

signal m_axis_result_tvalid: std_logic;
signal m_axis_result_tready: std_logic := '0';
signal m_axis_result_tdata: std_logic_vector(31 downto 0);
signal m_axis_result_tlast: std_logic;

constant clk_period : time := 10 ns;

begin

fp_acc_component: fp_acc
port map ( aclk => aclk,
aresetn => aresetn,

s_axis_a_tvalid => s_axis_a_tvalid,
s_axis_a_tready => s_axis_a_tready,
s_axis_a_tdata => s_axis_a_tdata,
s_axis_a_tlast => s_axis_a_tlast,

s_axis_operation_tvalid => s_axis_operation_tvalid,
s_axis_operation_tready => s_axis_operation_tready,
s_axis_operation_tdata => s_axis_operation_tdata,

m_axis_result_tvalid => m_axis_result_tvalid,
m_axis_result_tready => m_axis_result_tready,
m_axis_result_tdata => m_axis_result_tdata,
m_axis_result_tlast => m_axis_result_tlast);

clk_process : process
begin
aclk <= '0';
wait for clk_period/2;
aclk <= '1';
wait for clk_period/2;
end process;

test_process: process
begin
    aresetn <= '0';
    wait for clk_period * 2;
    aresetn <= '1';
    wait for clk_period * 2;
    
    wait until rising_edge(aclk) and s_axis_a_tready = '1' and s_axis_operation_tready = '1';
    
    s_axis_operation_tdata <= x"00"; -- add
    s_axis_a_tdata <= x"41000000"; -- 8.0
    s_axis_a_tlast <= '0';
    -- s_axis_a_tlast <= '1';
    s_axis_a_tvalid <= '1';
    s_axis_operation_tvalid <= '1';
    m_axis_result_tready <= '1';

    wait for clk_period;
    wait until rising_edge(aclk);

    s_axis_a_tvalid <= '0';
    s_axis_operation_tvalid <= '0';
    -- s_axis_a_tlast <= '0';

    wait until rising_edge(aclk) and m_axis_result_tvalid = '1';
    wait until rising_edge(aclk) and m_axis_result_tvalid = '0';
    m_axis_result_tready <= '0';

    wait for clk_period * 4;
    wait until rising_edge(aclk);

    s_axis_operation_tdata <= x"00"; -- add
    s_axis_a_tdata <= x"40000000"; -- 2.0
    s_axis_a_tlast <= '0';
    -- s_axis_a_tlast <= '1';
    s_axis_a_tvalid <= '1';
    s_axis_operation_tvalid <= '1';
    m_axis_result_tready <= '1';

    wait for clk_period;
    wait until rising_edge(aclk);

    s_axis_a_tvalid <= '0';
    s_axis_operation_tvalid <= '0';
    -- s_axis_a_tlast <= '0';

    wait until rising_edge(aclk) and m_axis_result_tvalid = '1';
    wait until rising_edge(aclk) and m_axis_result_tvalid = '0';
    m_axis_result_tready <= '0';

    wait for clk_period * 4;
    wait until rising_edge(aclk);

    s_axis_operation_tdata <= x"01"; -- subtract
    s_axis_a_tdata <= x"41200000"; -- 10.0
    s_axis_a_tlast <= '1';
    -- s_axis_a_tlast <= '0';
    s_axis_a_tvalid <= '1';
    s_axis_operation_tvalid <= '1';
    m_axis_result_tready <= '1';

    wait for clk_period;
    wait until rising_edge(aclk);

    s_axis_a_tvalid <= '0';
    s_axis_operation_tvalid <= '0';
    -- s_axis_a_tlast <= '0';

    wait until rising_edge(aclk) and m_axis_result_tvalid = '1';
    wait until rising_edge(aclk) and m_axis_result_tvalid = '0';
    m_axis_result_tready <= '0';

    wait for clk_period * 4;
    wait until rising_edge(aclk);

    aresetn <= '0';

    wait;
end process;

end architecture;
