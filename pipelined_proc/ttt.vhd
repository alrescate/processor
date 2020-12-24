-- ttt.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;

--/* This is a Verilog template for use with the Max 10 FPGA 10M08 Evaluation Kit.*/
--/* This file shows IO pin names and directions. */
--/* Last edited 03.30.2016 by William Gao*/
--/* The signals below can be found in Altera's "Max 10 FPGA Evaluation Kit" documentation. */
--/* For more details about the kit, including the user manual and schematics, please refer to the document.*/


--`define ENABLE_SWITCH
--`define ENABLE_LED
--`define ENABLE_ARDUINO
--`define ENABLE_DIFFIO

entity ttt is
 generic (
  G_SYS_CODE_MIF_FILE: string := "";
  G_SYS_DATA_MIF_FILE: string := ""
 );
 port ( 
--  // Switch Inputs
  SWITCH1 : in std_logic; -- ,        // Voltage Level 2.5 V 
  SWITCH2 : in std_logic; -- ,        // Voltage Level 2.5 V
  SWITCH3 : in std_logic; --,        // Voltage Level 2.5 V
  SWITCH4 : in std_logic; --,        // Voltage Level 2.5 V
  SWITCH5 : in std_logic; --,        // Voltage Level 2.5 V
--  //LED Outputs
  LED1 : out std_logic; --        // Voltage Level 2.5 V 
  LED2 : out std_logic; --        // Voltage Level 2.5 V
  LED3 : out std_logic; --        // Voltage Level 2.5 V
  LED4 : out std_logic; --        // Voltage Level 2.5 V
  LED5 : out std_logic; --        // Voltage Level 2.5 V
  
  -- //Clock from oscillator, referred to as osc_out in schematic
  CLOCK : in std_logic;

--  //Analog input in Arduino connector
  Arduino_A0 : in std_logic; --       // Voltage Level 2.5 V 
  Arduino_A1 : in std_logic; --       // Voltage Level 2.5 V
  Arduino_A2 : in std_logic; --       // Voltage Level 2.5 V
  Arduino_A3 : in std_logic; --       // Voltage Level 2.5 V
  Arduino_A4 : in std_logic; --       // Voltage Level 2.5 V
  Arduino_A5 : in std_logic; --       // Voltage Level 2.5 V
  Arduino_A6 : in std_logic; --       // Voltage Level 2.5 V
  Arduino_A7 : in std_logic; --       // Voltage Level 2.5 V
  
  -- //Arduino I/Os
  Arduino_IO0  : inout std_logic; --       // Voltage Level 2.5 V 
  Arduino_IO1  : inout std_logic; --      // Voltage Level 2.5 V
  Arduino_IO2  : inout std_logic; --      // Voltage Level 2.5 V
  Arduino_IO3  : inout std_logic; --      // Voltage Level 2.5 V
  Arduino_IO4  : inout std_logic; --      // Voltage Level 2.5 V
  Arduino_IO5  : inout std_logic; --      // Voltage Level 2.5 V
  Arduino_IO6  : inout std_logic; --      // Voltage Level 2.5 V
  Arduino_IO7  : inout std_logic; --      // Voltage Level 2.5 V
  Arduino_IO8  : inout std_logic; --      // Voltage Level 2.5 V
  Arduino_IO9  : inout std_logic; --      // Voltage Level 2.5 V 
  Arduino_IO10 : inout std_logic; --       // Voltage Level 2.5 V
  Arduino_IO11 : inout std_logic; --       // Voltage Level 2.5 V
  Arduino_IO12 : inout std_logic; --       // Voltage Level 2.5 V
  Arduino_IO13 : inout std_logic; --       // Voltage Level 2.5 V
  
--  //Reset Pin
  RESET_N : in std_logic; -- ,        // Voltage Level 2.5 V
  
--  //There are 40 GPIOs. In this example pins are not used as LVDS pins. 
--  //NOTE: Refer README.txt on how to use these GPIOs with LVDS option. 


    DIFFIO_L27N_PLL_CLKOUTN : inout std_logic; -- ,    // Voltage Level 2.5 V 
    DIFFIO_L27P_PLL_CLKOUTP : inout std_logic; -- ,    // Voltage Level 2.5 V
    DIFFIO_L20N_CLK1N : inout std_logic; -- ,     // Voltage Level 2.5 V 
    DIFFIO_L20P_CLK1P : inout std_logic; -- ,     // Voltage Level 2.5 V
    DIFFIO_R14P_CLK2P : inout std_logic; -- ,     // Voltage Level 2.5 V
    DIFFIO_R14N_CLK2N : inout std_logic; -- ,     // Voltage Level 2.5 V
    DIFFIO_R16P_CLK3P : inout std_logic; -- ,     // Voltage Level 2.5 V
    DIFFIO_R16N_CLK3N : inout std_logic; -- ,     // Voltage Level 2.5 V
    DIFFIO_R26N_DPCLK2 : inout std_logic; -- ,    // Voltage Level 2.5 V
    DIFFIO_R26P_DPCLK3 : inout std_logic; -- ,    // Voltage Level 2.5 V
    DIFFIO_B1N : inout std_logic; --      // Voltage Level 2.5 V 
    DIFFIO_B1P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B3N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B3P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B5N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B5P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B7N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B7P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B9N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B9P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_T1P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_T1N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_T4N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_T6P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B12N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B12P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B14N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B14P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B16N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_B16P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_R18P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_R18N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_R27P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_R28P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_R27N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_R28N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_R33P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_R33N : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_T10P : inout std_logic; --      // Voltage Level 2.5 V
    DIFFIO_T10N : inout std_logic  --      // Voltage Level 2.5 V 
);
end entity;

architecture rtl of ttt is

	signal reset : std_logic;
	signal q : std_logic_vector(25 DOWNTO 0);
	
	signal cs1_n, cs2_n, cs3_n : std_logic;
	signal debug_data_addr : std_logic_vector(15 downto 0);

begin

reset <= not reset_n;

--  Arduino_IO0  <= 'Z'; 
--  Arduino_IO1  <= 'Z';
--  Arduino_IO2  <= 'Z';
--  Arduino_IO3  <= 'Z';
--  Arduino_IO4  <= 'Z';
--  Arduino_IO5  <= 'Z';
--  Arduino_IO6  <= 'Z';
--  Arduino_IO7  <= 'Z';
--  Arduino_IO8  <= 'Z';
--  Arduino_IO9  <= 'Z';
--  Arduino_IO10 <= 'Z';
--  Arduino_IO11 <= 'Z';
Arduino_IO12 <= 'Z';
--  Arduino_IO13 <= 'Z';
  
    DIFFIO_L27N_PLL_CLKOUTN <= 'Z';
    DIFFIO_L27P_PLL_CLKOUTP <= 'Z';
    DIFFIO_L20N_CLK1N <= 'Z';
    DIFFIO_L20P_CLK1P <= 'Z';
    DIFFIO_R14P_CLK2P <= 'Z';
    DIFFIO_R14N_CLK2N <= 'Z';
    DIFFIO_R16P_CLK3P <= 'Z';
    DIFFIO_R16N_CLK3N <= 'Z';
    DIFFIO_R26N_DPCLK2 <= 'Z';
    DIFFIO_R26P_DPCLK3 <= 'Z';
    DIFFIO_B1N <= 'Z';
    DIFFIO_B1P <= 'Z';
    DIFFIO_B3N <= 'Z';
    DIFFIO_B3P <= 'Z';
    DIFFIO_B5N <= 'Z';
    DIFFIO_B5P <= 'Z';
    DIFFIO_B7N <= 'Z';
    DIFFIO_B7P <= 'Z';
    DIFFIO_B9N <= 'Z';
    DIFFIO_B9P <= 'Z';
    DIFFIO_T1P <= 'Z';
    DIFFIO_T1N <= 'Z';
    DIFFIO_T4N <= 'Z';
    DIFFIO_T6P <= 'Z';
    DIFFIO_B12N <= debug_data_addr(0);
    DIFFIO_B12P <= debug_data_addr(1);
    DIFFIO_B14N <= debug_data_addr(2);
    DIFFIO_B14P <= debug_data_addr(3);
    DIFFIO_B16N <= debug_data_addr(4);
    DIFFIO_B16P <= debug_data_addr(5);
    DIFFIO_R18P <= debug_data_addr(6);
    DIFFIO_R18N <= debug_data_addr(7);
    DIFFIO_R27P <= debug_data_addr(8);
    DIFFIO_R28P <= debug_data_addr(9);
    DIFFIO_R27N <= debug_data_addr(10);
    DIFFIO_R28N <= debug_data_addr(11);
    DIFFIO_R33P <= debug_data_addr(12);
    DIFFIO_R33N <= debug_data_addr(13);
    DIFFIO_T10P <= debug_data_addr(14);
    DIFFIO_T10N <= debug_data_addr(15);
	 
	 --=================================================================

-- LED5<=q(25);
-- LED4<=q(24);
-- LED3<=q(23);
-- LED2<=q(22);
-- LED1<=q(21);

LED5 <= cs1_n;
LED4 <= cs2_n;
LED3 <= cs3_n;
LED2 <= '0';
LED1 <= '0';

--const uint8_t TFT_DC=9;
--const uint8_t TFT_CS=10;
--const uint8_t TFT_MOSI=11;
--const uint8_t TFT_MISO=12;
--const uint8_t TFT_SCK=13;

p_poohbear : process(CLOCK)
begin
	if RISING_EDGE(CLOCK) then
		q <= std_logic_vector(unsigned(q) + 1);
	end if;
end process;

sys: entity pipe_proc.pipe_proc_sys
    generic map ( G_SIM => 0,
	           G_CODE_MIF_FILE => G_SYS_CODE_MIF_FILE,
              G_DATA_MIF_FILE => G_SYS_DATA_MIF_FILE,
              G_LOG_DEPTH_DATA => 13,
              G_LOG_DEPTH_CODE => 12)
    port map (
        aclr => reset,
        sclr => reset,
        clk => q(0),
        
        sys_overtake => '0',
        
        sys_data_addr => (OTHERS => '0'),

        sys_data_write_ena => '0',
        sys_data_write_data => (OTHERS => '0'),

        sys_data_read_ena => '0',
        sys_data_read_data => OPEN,

        
        sys_code_addr => (OTHERS => '0'),

        sys_code_write_ena => '0',
        sys_code_write_data => (OTHERS => '0'),
        
        sys_code_read_ena => '0',
        sys_code_read_data => OPEN,
		  
		io_sck => ARDUINO_IO13,
        io_dc => ARDUINO_IO9,
        io_mosi => ARDUINO_IO11,
        io_cs1_n => cs1_n,
        io_cs2_n => cs2_n,
        io_cs3_n => cs3_n,
		  
		io_miso => ARDUINO_IO12 -- 
		
		-- debug_data_addr => debug_data_addr
    );

    ARDUINO_IO10 <= cs1_n; -- TFT_CS (LCD Controller)
    ARDUINO_IO8 <= cs2_n;  -- RT_CS (Touch Screen Controller)
    ARDUINO_IO4 <= cs3_n;  -- CARDCS (Flash Card)
	 
end rtl;
