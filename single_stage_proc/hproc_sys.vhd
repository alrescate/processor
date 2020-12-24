-- hproc_sys.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hproc;
use hproc.hproc_pkg.all;

entity hproc_sys is
    generic ( G_SIM : integer := 0;
              G_CODE_MIF_FILE: string := "";
              G_DATA_MIF_FILE: string := "";
              G_LOG_DEPTH_DATA : integer := 16;
              G_LOG_DEPTH_CODE : integer := 16);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        
        sys_overtake : in std_logic;
        
        sys_data_addr : in std_logic_vector(15 downto 0);

        sys_data_write_ena : in std_logic;
        sys_data_write_data : in std_logic_vector(15 downto 0);

        sys_data_read_ena : in std_logic;
        sys_data_read_data : out std_logic_vector(15 downto 0);

        
        sys_code_addr : in std_logic_vector(15 downto 0);

        sys_code_write_ena : in std_logic;
        sys_code_write_data : in std_logic_vector(15 downto 0);
        
        sys_code_read_ena : in std_logic;
        sys_code_read_data : out std_logic_vector(15 downto 0);
        
		io_sck : out std_logic;
        io_dc : out std_logic;
        io_mosi : out std_logic;
        io_cs1_n : out std_logic;
        io_cs2_n : out std_logic;
        io_cs3_n : out std_logic;
		  
		io_miso : in std_logic;
		debug_data_addr : out std_logic_vector(15 downto 0)
    );
    
end entity;
    
architecture rtl of hproc_sys is 

signal data_addr : std_logic_vector(15 downto 0);

signal data_write_ena : std_logic;
signal conditioned_data_write_ena : std_logic; 
signal controller_write_ena : std_logic;
signal data_write_data : std_logic_vector(15 downto 0);

signal data_read_ena : std_logic;
signal conditioned_data_read_ena : std_logic;
signal conditioned_data_read_ena_z : std_logic;
signal controller_read_ena : std_logic;
signal controller_read_ena_z : std_logic;
signal controller_dout : std_logic_vector(15 downto 0);
signal data_read_data : std_logic_vector(15 downto 0);
signal ram_read_data : std_logic_vector(15 downto 0);

signal code_addr : std_logic_vector(15 downto 0);

signal code_read_ena : std_logic;
signal code_read_data : std_logic_vector(15 downto 0);

signal reset_n : std_logic;

begin

reset_n <= NOT sclr;

u_proc : entity hproc.processor
    generic map ( G_SIM => G_SIM)
    port map (
        aclr => aclr,
        sclr => sclr,
        clk => clk,
        
        data_addr => data_addr, 

        data_write_ena => data_write_ena,
        data_write_data => data_write_data,

        data_read_ena => data_read_ena,
        data_read_data => data_read_data,
        
        code_addr => code_addr,

        code_read_ena => code_read_ena,
        code_read_data => code_read_data
        
    );
    
u_code_mem : entity hproc.memory
    generic map ( G_SIM => G_SIM,
                  G_MIF_FILE => G_CODE_MIF_FILE,
                  G_LOG_DEPTH => G_LOG_DEPTH_CODE)
    port map (
        clk => clk,
        
        addr => code_addr(G_LOG_DEPTH_CODE - 1 DOWNTO 0),
        
        write_ena => '0',
        write_data => x"0000",
        
        read_ena => code_read_ena,
        read_data => code_read_data,
        
        sys_addr => sys_code_addr(G_LOG_DEPTH_CODE - 1 DOWNTO 0),
        sys_write_ena => sys_code_write_ena,
        sys_write_data => sys_code_write_data,
        
        sys_read_ena => sys_code_read_ena,
        sys_read_data => sys_code_read_data,
        
        sys_overtake => sys_overtake
    );
    
    conditioned_data_write_ena <= data_write_ena when data_addr(15 DOWNTO 13) = "111" else '0';
    conditioned_data_read_ena <= data_read_ena when data_addr(15 DOWNTO 13) = "111" else '0';
    
    controller_write_ena <= data_write_ena when data_addr(15 DOWNTO 13) = "000" else '0';
    controller_read_ena <= data_read_ena when data_addr(15 DOWNTO 13) = "000" else '0';
    
u_data_mem : entity hproc.memory
    generic map ( G_SIM => G_SIM,
                  G_MIF_FILE => G_DATA_MIF_FILE,
                  G_LOG_DEPTH => G_LOG_DEPTH_DATA)
    port map (
        clk => clk,
        
        addr => data_addr(G_LOG_DEPTH_DATA - 1 DOWNTO 0),
        
        write_ena => conditioned_data_write_ena,
        write_data => data_write_data,
        
        read_ena => conditioned_data_read_ena,
        read_data => ram_read_data,
        
        sys_addr => sys_data_addr(G_LOG_DEPTH_DATA - 1 DOWNTO 0),
        sys_write_ena => sys_data_write_ena,
        sys_write_data => sys_data_write_data,
        
        sys_read_ena => sys_data_read_ena,
        sys_read_data => sys_data_read_data,
        
        sys_overtake => sys_overtake
    );
    
--out_reg : process(clk)
--begin
    --if RISING_EDGE(clk) then
        --if pio_out_write_ena = '1' then
            --pio_out <= data_write_data;
        --end if;
    --end if;
--end process;
--
p_delay : process(clk)
begin
    if RISING_EDGE(clk) then
        conditioned_data_read_ena_z <= conditioned_data_read_ena;
        controller_read_ena_z <= controller_read_ena;
    end if;
end process;

data_read_data <= ram_read_data when conditioned_data_read_ena_z = '1' else 
                  controller_dout when controller_read_ena_z = '1'     else
                  (OTHERS => '0');

u_controller: entity work.io_controller
  generic map ( g_slow_time => 25, -- G_SLOW_DIVISOR
                g_fast_time => 3 ) -- G_FAST_DIVISOR
  port map (
    clk           => clk,
    sclr_n        => reset_n,
    a0            => data_addr(0),
    
    -- din   => data_write_data,
    -- wr    => controller_write_ena,
    -- rd    => controller_read_ena,
    -- dout  => controller_dout,     
    -- sck   => io_sck,
    -- dc    => io_dc,
    -- mosi  => io_mosi,
    -- cs1_n => io_cs1_n,
    -- cs2_n => io_cs2_n,
    -- cs3_n => io_cs3_n,
    -- miso  => io_miso,
    -- gpin  => (OTHERS => '0'));
    
    data_in       => data_write_data,
    write_ena     => controller_write_ena,
    read_ena      => controller_read_ena,
    data_out      => controller_dout,     
    spi_sck       => io_sck,
    spi_dc        => io_dc,
    spi_mosi      => io_mosi,
    spi_cs1n      => io_cs1_n,
    spi_cs2n      => io_cs2_n,
    spi_cs3n      => io_cs3_n,
    spi_miso      => io_miso );

    
    debug_data_addr <= data_addr; -- map addr to a port so signaltap can trigger on it
    
    
end rtl;
