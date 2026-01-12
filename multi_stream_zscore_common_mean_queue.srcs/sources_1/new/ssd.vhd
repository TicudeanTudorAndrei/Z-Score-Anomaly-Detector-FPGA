library IEEE;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity ssd is
port ( digits: in STD_LOGIC_VECTOR (31 downto 0); 
clk: in STD_LOGIC;
an: out STD_LOGIC_VECTOR (7 downto 0);
cat: out STD_LOGIC_VECTOR (6 downto 0));
end entity;

architecture ssd_arh of ssd is

signal cnt: STD_LOGIC_VECTOR(15 downto 0);
signal sel: STD_LOGIC_VECTOR(2 downto 0);
signal mux_cat: STD_LOGIC_VECTOR(3 downto 0);
signal mux_an: STD_LOGIC_VECTOR(7 downto 0);

begin

COUNTER: process(clk)
begin
	if rising_edge(clk) then
	   cnt <= cnt + 1;
	end if;
end process;

sel(2 downto 0) <= cnt(15 downto 13);

MUXCAT: process(sel, digits)
begin
	case sel is		   
		when "000" => mux_cat <= digits(3 downto 0);
		when "001" => mux_cat <= digits(7 downto 4);
		when "010" => mux_cat <= digits(11 downto 8);
		when "011" => mux_cat <= digits(15 downto 12);
		when "100" => mux_cat <= digits(19 downto 16);
		when "101" => mux_cat <= digits(23 downto 20);
		when "110" => mux_cat <= digits(27 downto 24);
		when others => mux_cat <= digits(31 downto 28);
	end case;
end process;

MUXAN: process(sel)
begin
	case sel is
		when "000" => mux_an <= "11111110";
		when "001" => mux_an <= "11111101";
		when "010" => mux_an <= "11111011";
		when "011" => mux_an <= "11110111";
		when "100" => mux_an <= "11101111";
		when "101" => mux_an <= "11011111";
		when "110" => mux_an <= "10111111";
		when others => mux_an <= "01111111";
	end case;
end process;

an <= mux_an;

with mux_cat select
cat <= 	"1111001" when "0001",   --1
	   	"0100100" when "0010",   --2
       	"0110000" when "0011",   --3
       	"0011001" when "0100",   --4
       	"0010010" when "0101",   --5
	   	"0000010" when "0110",   --6
	   	"1111000" when "0111",   --7   
		"0000000" when "1000",   --8
		"0010000" when "1001",   --9
		"0001000" when "1010",   --A
		"0000011" when "1011",   --B 
		"1000110" when "1100",   --C
		"0100001" when "1101",   --D
		"0000110" when "1110",   --E
		"0001110" when "1111",   --F
		"1000000" when others;   --0 

end architecture;