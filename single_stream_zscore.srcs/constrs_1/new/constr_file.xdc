## This file is a general .xdc for the Nexys A7
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
set_property PACKAGE_PIN E3 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name clk -period 10.00 -waveform {0 5} [get_ports clk]


## Switches

set_property PACKAGE_PIN J15 [get_ports {sw[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property PACKAGE_PIN L16 [get_ports {sw[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property PACKAGE_PIN M13 [get_ports {sw[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property PACKAGE_PIN R15 [get_ports {sw[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property PACKAGE_PIN R17 [get_ports {sw[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property PACKAGE_PIN T18 [get_ports {sw[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property PACKAGE_PIN U18 [get_ports {sw[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property PACKAGE_PIN R13 [get_ports {sw[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property PACKAGE_PIN T8 [get_ports {sw[8]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[8]}]
set_property PACKAGE_PIN U8 [get_ports {sw[9]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[9]}]
set_property PACKAGE_PIN R16 [get_ports {sw[10]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[10]}]
set_property PACKAGE_PIN T13 [get_ports {sw[11]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[11]}]
set_property PACKAGE_PIN H6 [get_ports {sw[12]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[12]}]
set_property PACKAGE_PIN U12 [get_ports {sw[13]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[13]}]
set_property PACKAGE_PIN U11 [get_ports {sw[14]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[14]}]
set_property PACKAGE_PIN V10 [get_ports {sw[15]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {sw[15]}]


## LEDs

set_property PACKAGE_PIN H17 [get_ports {led[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN K15 [get_ports {led[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN J13 [get_ports {led[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property PACKAGE_PIN N14 [get_ports {led[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property PACKAGE_PIN R18 [get_ports {led[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property PACKAGE_PIN V17 [get_ports {led[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property PACKAGE_PIN U17 [get_ports {led[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property PACKAGE_PIN U16 [get_ports {led[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property PACKAGE_PIN V16 [get_ports {led[8]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[8]}]
set_property PACKAGE_PIN T15 [get_ports {led[9]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[9]}]
set_property PACKAGE_PIN U14 [get_ports {led[10]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[10]}]
set_property PACKAGE_PIN T16 [get_ports {led[11]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[11]}]
set_property PACKAGE_PIN V15 [get_ports {led[12]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[12]}]
set_property PACKAGE_PIN V14 [get_ports {led[13]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[13]}]
set_property PACKAGE_PIN V12 [get_ports {led[14]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[14]}]
set_property PACKAGE_PIN V11 [get_ports {led[15]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {led[15]}]


## 7 segment display

set_property PACKAGE_PIN T10 [get_ports {cat[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cat[0]}]
set_property PACKAGE_PIN R10 [get_ports {cat[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cat[1]}]
set_property PACKAGE_PIN K16 [get_ports {cat[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cat[2]}]
set_property PACKAGE_PIN K13 [get_ports {cat[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cat[3]}]
set_property PACKAGE_PIN P15 [get_ports {cat[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cat[4]}]
set_property PACKAGE_PIN T11 [get_ports {cat[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cat[5]}]
set_property PACKAGE_PIN L18 [get_ports {cat[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {cat[6]}]


set_property PACKAGE_PIN J17 [get_ports {an[0]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]
set_property PACKAGE_PIN J18 [get_ports {an[1]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]
set_property PACKAGE_PIN T9 [get_ports {an[2]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]
set_property PACKAGE_PIN J14 [get_ports {an[3]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]
set_property PACKAGE_PIN P14 [get_ports {an[4]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[4]}]
set_property PACKAGE_PIN T14 [get_ports {an[5]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[5]}]
set_property PACKAGE_PIN K2 [get_ports {an[6]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[6]}]
set_property PACKAGE_PIN U13 [get_ports {an[7]}]					
	set_property IOSTANDARD LVCMOS33 [get_ports {an[7]}]

## Buttons

set_property PACKAGE_PIN N17 [get_ports {btn[0]}]						
	set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]
	set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets btn_IBUF[0]]
set_property PACKAGE_PIN M18 [get_ports {btn[1]}]						
	set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
	set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets btn_IBUF[1]]
set_property PACKAGE_PIN P17 [get_ports {btn[2]}]						
	set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
set_property PACKAGE_PIN M17 [get_ports btn[3]]						
	set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]
set_property PACKAGE_PIN P18 [get_ports {btn[4]}]						
	set_property IOSTANDARD LVCMOS33 [get_ports {btn[4]}]

## UART

## Pin D3 for UART CTS
set_property PACKAGE_PIN D3 [get_ports {uart_cts}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_cts}]

## Pin E5 for UART RTS
set_property PACKAGE_PIN E5 [get_ports {uart_rts}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rts}]

## Pin D4 for UART RXD (FPGA output, UART input)
set_property PACKAGE_PIN D4 [get_ports {uart_rxd_out}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rxd_out}]

## Pin C4 for UART TXD (FPGA input, UART output)
set_property PACKAGE_PIN C4 [get_ports {uart_txd_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_txd_in}]

