-- io_revision.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity io_controller is 
    generic ( g_slow_time : integer := 30;
              g_fast_time : integer := 10);
    port (
        clk : in std_logic;
        sclr_n : in std_logic;
        a0 : in std_logic;
        data_in : in std_logic_vector(15 downto 0);
        write_ena : in std_logic;
        read_ena : in std_logic;
        data_out : out std_logic_vector(15 downto 0); -- this is exclusively for the busy but we need 16 bits so that the code can use skpl 
        
        spi_cs1n : out std_logic;
        spi_cs2n : out std_logic;
        spi_cs3n : out std_logic;
        spi_dc : out std_logic;
        spi_mosi : out std_logic;
        spi_sck : out std_logic;
        spi_miso : in std_logic -- a port exists but won't be used 
    );
end io_controller;

architecture rtl of io_controller is

type clock_phase is (NO_BYTE, SERIAL_CLK_LOW, SERIAL_CLK_HIGH, MOSI_UPDATE);
signal phase : clock_phase;
signal busy_c : integer range 0 to g_slow_time;
signal busy_v : std_logic;
signal busy_suppress : std_logic;
signal out_cs1 : std_logic;
signal out_cs2 : std_logic;
signal out_cs3 : std_logic;
signal out_dc : std_logic;
signal out_mosi : std_logic;
signal out_sck : std_logic;
signal remember_slow : std_logic;
signal shift_reg : std_logic_vector(7 downto 0);
signal shift_count : std_logic_vector(3 downto 0);

begin

p_io : process(clk)
begin
    if rising_edge(clk) then
        if sclr_n = '0' then
            out_sck <= '0';
            out_dc <= '0';
            out_mosi <= '0';
            out_cs1 <= '0';
            out_cs2 <= '0';
            out_cs3 <= '0';
            busy_c <= 0;
            busy_v <= '0';
            busy_suppress <= '0';
            phase <= NO_BYTE;
        else
            if busy_v = '1' then -- if we are busy, do the busy timer - don't do anything else.
                if busy_c /= 0 then
                    busy_c <= busy_c - 1;
                else
                    busy_v <= '0';
                end if;
            else
                case phase is
                    when NO_BYTE =>
                        if write_ena = '1' then
                            if a0 = '0' then -- in even address mode, we have individual bit fields
                                out_cs1 <= (out_cs1 or data_in(11)) and not data_in(3); -- note that the clears have precedence over the sets
                                out_cs2 <= (out_cs2 or data_in(12)) and not data_in(4);
                                out_cs3 <= (out_cs3 or data_in(13)) and not data_in(5);
                                out_dc <= (out_dc or data_in(10)) and not data_in(2);
                                out_mosi <= (out_mosi or data_in(9)) and not data_in(1);
                                out_sck <= (out_sck or data_in(8)) and not data_in(0);
                                if data_in(15) = '0' then
                                    busy_c <= g_fast_time;
                                elsif data_in(15) = '1' then
                                    busy_c <= g_slow_time;
                                end if;
                                busy_v <= '1';
                            elsif a0 = '1' then -- set the flags for byte serialization
                                remember_slow <= data_in(15);
                                shift_reg <= data_in(7 downto 0);
                                shift_count <= "1000";
                                phase <= MOSI_UPDATE;
                                busy_suppress <= '1';
                            end if;
                        end if;
                    when MOSI_UPDATE =>
                        if remember_slow = '1' then -- set up the timer - this is done in every phase
                            busy_c <= g_slow_time;
                        else
                            busy_c <= g_fast_time;
                        end if;
                        busy_v <= '1';
                        out_mosi <= shift_reg(7);
                        phase <= SERIAL_CLK_HIGH;
                    when SERIAL_CLK_HIGH =>
                        if remember_slow = '1' then -- set up the timer - this is done in every phase
                            busy_c <= g_slow_time;
                        else
                            busy_c <= g_fast_time;
                        end if;
                        busy_v <= '1';
                        out_sck <= '1';
                        phase <= SERIAL_CLK_LOW;
                    when SERIAL_CLK_LOW =>
                        if remember_slow = '1' then -- set up the timer - this is done in every phase
                            busy_c <= g_slow_time;
                        else
                            busy_c <= g_fast_time;
                        end if;
                        busy_v <= '1';
                        out_sck <= '0';
                        shift_reg <= shift_reg(6 downto 0) & '0';
                        shift_count <= std_logic_vector(unsigned(shift_count)-1);
                        if to_integer(unsigned(shift_count)) = 1 then
                            phase <= NO_BYTE;     -- if this was our last bit then leave this phase 
                                                  -- note that we're still going to wait for busy
                            busy_suppress <= '0'; -- stop suppressing busy to the outside world
                        else
                            phase <= MOSI_UPDATE; -- if we haven't hit the end, still wait for busy, but go back to mosi
                        end if;
                    when OTHERS =>
                        phase <= NO_BYTE;
                end case;
            end if;
        end if;
    end if;
end process;

spi_cs1n <= not out_cs1;
spi_cs2n <= not out_cs2;
spi_cs3n <= not out_cs3;
spi_dc   <= out_dc;
spi_mosi <= out_mosi;
spi_sck  <= out_sck;

data_out <= (busy_v or busy_suppress) & "00000000000000" & spi_miso;

end rtl;