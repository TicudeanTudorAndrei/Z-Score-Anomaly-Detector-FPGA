library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity mpg is
port ( btn: in STD_LOGIC;
clk: in STD_LOGIC;
enable: out STD_LOGIC);
end mpg;

architecture mpg_arh of mpg is

signal counter: STD_LOGIC_VECTOR(15 downto 0) := x"0000";
signal Q1: STD_LOGIC;
signal Q2: STD_LOGIC;
signal Q3: STD_LOGIC;

begin
enable <= Q2 AND (not Q3);

CTR: process (clk) 
begin
    if rising_edge(clk) then
        counter <= counter + 1;
    end if;
end process;

SIG: process (clk)
begin
    if rising_edge(clk) then  
	   if counter(15 downto 0) = x"1111" then 
	       Q1 <= btn;
	   end if; 
    end if;
end process;

CON: process (clk)
begin
    if rising_edge(clk) then  
        Q2 <= Q1;
        Q3 <= Q2;
    end if;
end process;

end mpg_arh;