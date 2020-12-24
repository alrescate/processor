-- mem_wb.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;
use pipe_proc.pipe_proc_pkg.all;

entity mem_wb is
    generic ( G_SIM: integer := 0);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        clk_ena : in std_logic;
        
        MEM_valid : in std_logic;
        MEM_rf_waddr : in std_logic_vector(3 downto 0);
        MEM_rf_wena : in std_logic; 
        MEM_pc_setena : in std_logic;
        
        WB2_valid : out std_logic;
        WB2_rf_waddr : out std_logic_vector(3 downto 0);
        WB2_rf_wena : out std_logic;
        WB2_pc_setena : out std_logic
    );
    
end entity;

architecture rtl of mem_wb is

begin

WB2_valid <= MEM_valid;
WB2_rf_waddr <= MEM_rf_waddr;
WB2_rf_wena <= MEM_rf_wena;
WB2_pc_setena <= MEM_pc_setena;

reg_memwb : process(clk, aclr)
begin
    if (aclr = '1') then
        WB2_valid <= '0';
    elsif RISING_EDGE(clk) then
        if (sclr = '1') then
            WB2_valid <= '0';
        end if;
    end if;
end process;

end architecture;