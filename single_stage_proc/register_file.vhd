-- register_file.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hproc;
use hproc.hproc_pkg.all;

entity register_file is
    generic ( G_SIM: integer := 0);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        clk_ena : in std_logic;
        write_ena : in std_logic;
        write_addr : in std_logic_vector(3 downto 0);
        writev : in data_t;
        rna : in std_logic_vector(3 downto 0);
        rnb : in std_logic_vector(3 downto 0);
        
        rav_out : out data_t;
        rbv_out : out data_t
    );
    
end entity;
    
architecture rtl of register_file is 

signal rf_reg : data_array_t;
begin

reg_w : process (aclr, clk)
begin     
    if (aclr = '1') then
        rf_reg <= (OTHERS => (OTHERS => '0'));
    elsif RISING_EDGE(clk) then
        if (clk_ena = '1') then
            if (sclr = '1') then
                rf_reg <= (OTHERS => (OTHERS => '0'));
            elsif (write_ena = '1') then
                rf_reg(to_integer(unsigned(write_addr))) <= writev;
            end if;
        end if;
    end if;
end process;

rav_out <= rf_reg(to_integer(unsigned(rna)));
rbv_out <= rf_reg(to_integer(unsigned(rnb)));

end rtl;
