-- rf.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;
use pipe_proc.pipe_proc_pkg.all;

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
        write_ena2 : in std_logic;
        write_addr2 : in std_logic_vector(3 downto 0);
        writev2 : in data_t;
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
            else 
                if (write_ena2 = '1') then
                    rf_reg(to_integer(unsigned(write_addr2))) <= writev2;
                end if;
                -- the first port is given precedence over the second because 
                -- in the case of a conflict, the first port should take precedence
                if(write_ena = '1') then
                    rf_reg(to_integer(unsigned(write_addr))) <= writev;
                end if;
            end if;
        end if;
    end if;
end process;

-- note that this is an asynchronous process 
-- but writing the register file is a synchronous process
-- therefore, you can read in a single cycle, but not write
rav_out <= rf_reg(to_integer(unsigned(rna)));
rbv_out <= rf_reg(to_integer(unsigned(rnb)));

end rtl;
