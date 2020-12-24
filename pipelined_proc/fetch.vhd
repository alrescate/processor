-- fetch.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;
use pipe_proc.pipe_proc_pkg.all;

entity fetch is
    generic ( G_SIM: integer := 0);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        clk_ena : in std_logic;
        
        instr_in : in data_t;
        pc_setena : in std_logic;
        pc_setv : in data_t;
        
        valid_in : in std_logic;
        
        code_addr : out data_t;
        
        IF_valid : out std_logic;
        IF_instr : out data_t;
        IF_pc : out data_t
    );
    
end entity;

architecture rtl of fetch is

signal pc_reg : data_t;

begin

code_addr <= pc_reg;

reg_pc : process(aclr, clk)
begin
    if (aclr = '1') then
        pc_reg <= (OTHERS => '0');
    elsif RISING_EDGE(clk) then
        if (clk_ena = '1') then
            if (sclr = '1') then
                pc_reg <= (OTHERS => '0');
            else
                pc_reg <= std_logic_vector(unsigned(pc_reg) + 1);
            end if;
        end if;
        if ((pc_setena = '1') and (sclr = '0')) then
            pc_reg <= pc_setv;
        end if;
    end if;
end process;

reg_valid : process(aclr, clk)
begin 
    if (aclr = '1') then
        IF_valid <= '0';
    elsif RISING_EDGE(clk) then
        if (sclr = '1') then
            IF_valid <= '0';
        else
            IF_valid <= valid_in;
        end if;
    end if;
end process;

reg_instr : process(aclr, clk)
begin
    if (aclr = '1') then
        IF_instr <= (OTHERS => '0');
        IF_pc <= (OTHERS => '0');
    elsif RISING_EDGE(clk) then
        if (sclr = '1') then
            IF_instr <= (OTHERS => '0');
            IF_pc <= (OTHERS => '0');
        elsif (clk_ena = '1') then
            IF_instr <= instr_in;
            IF_pc <= pc_reg;
        end if;
    end if;
end process;

end architecture;