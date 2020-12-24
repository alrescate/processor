-- memory.vhd 

--
--LIBRARY ieee;
--USE ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

--ENTITY my_ram IS
 --generic ( mif_file : string := "my_rom.mif" );
 --PORT(
 --clock : IN STD_LOGIC;
 --addr  : IN std_logic_vector(7 downto 0);
 --we    : IN std_logic;
 --d     : IN std_logic_vector(15 downto 0);
 --q     : OUT std_logic_vector(15 downto 0) );
--END my_ram;

--ARCHITECTURE rtl OF my_ram IS
 --TYPE Tmem IS ARRAY(0 to 255) OF std_logic_vector(15 downto 0);
 --signal the_ram : Tmem;
 --attribute ram_init_file : string;
 --attribute ram_init_file of the_ram :  signal is mif_file;

--BEGIN

--p_reg: process(clock)
--begin
--if rising_edge(clock) then
  --q <= the_ram(to_integer(UNSIGNED(addr)));
  ----
  --if we='1' then
    --the_ram(to_integer(UNSIGNED(addr))) <= d;
  --end if;
--end if;
--end process;
 
--END rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;
use pipe_proc.pipe_proc_pkg.all;

entity memory is
    generic ( G_SIM: integer := 0;
              G_MIF_FILE: string := "";
              G_LOG_DEPTH: integer := 16);
    port (
        clk : in std_logic;
        
        addr : in std_logic_vector(G_LOG_DEPTH - 1 downto 0);
        
        write_ena : in std_logic;
        write_data : in data_t;
        
        read_ena : in std_logic;
        read_data : out data_t;
        
        sys_addr : in std_logic_vector(G_LOG_DEPTH - 1 downto 0);
        sys_write_ena : in std_logic;
        sys_write_data : in data_t;
        
        sys_read_ena : in std_logic;
        sys_read_data : out data_t;
        
        sys_overtake : in std_logic
    );
    
end entity;
    
architecture rtl of memory is 

subtype word_t is std_logic_vector(15 downto 0);
type word_array_t is array(0 to 2**G_LOG_DEPTH - 1) of word_t;

signal mem : word_array_t;
attribute ram_init_file : string;
attribute ram_init_file of mem :  signal is G_MIF_FILE;
signal we : std_logic;
signal rd : std_logic;
signal wdata : word_t;
signal mout : word_t;
signal waddr : std_logic_vector(G_LOG_DEPTH - 1 downto 0);
signal raddr : std_logic_vector(G_LOG_DEPTH - 1 downto 0);

begin

waddr <= sys_addr(G_LOG_DEPTH - 1 downto 0) when sys_overtake = '1' else addr;
raddr <= sys_addr(G_LOG_DEPTH - 1 downto 0) when sys_overtake = '1' else addr;

we <= sys_write_ena when sys_overtake = '1' else write_ena;
rd <= sys_read_ena when sys_overtake = '1' else read_ena;

wdata <= sys_write_data when sys_overtake = '1' else write_data;

sys_read_data <= mout;
read_data <= mout;

mem_w : process (clk)
begin     
    if RISING_EDGE(clk) then
        if (we = '1') then
            mem(to_integer(unsigned(waddr))) <= wdata;
        end if;
    end if;
end process;

mem_r : process (clk) 
begin
    if RISING_EDGE(clk) then
        if (rd = '1') then
            mout <= mem(to_integer(unsigned(raddr)));
        end if;
    end if;
end process;

end rtl;
