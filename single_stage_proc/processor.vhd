-- processor.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hproc;
use hproc.hproc_pkg.all;

entity processor is
    generic ( G_SIM: integer := 0);
    port (
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        
        data_addr : out std_logic_vector(15 downto 0);

        data_write_ena : out std_logic;
        data_write_data : out std_logic_vector(15 downto 0);

        data_read_ena : out std_logic;
        data_read_data : in std_logic_vector(15 downto 0);
        
        code_addr : out std_logic_vector(15 downto 0);

        code_read_ena : out std_logic;
        code_read_data : in std_logic_vector(15 downto 0)
        
    );
    
end entity;
    
architecture rtl of processor is 

signal rav :  std_logic_vector(15 downto 0);
signal rbv :  std_logic_vector(15 downto 0);
signal rna :  std_logic_vector(3 downto 0);
signal rnb :  std_logic_vector(3 downto 0);
signal reg_write_addr : std_logic_vector(3 downto 0);
signal reg_write_ena : std_logic;
signal rfsclr : std_logic;
signal alu_left : std_logic_vector(15 downto 0);
signal alu_right : std_logic_vector(15 downto 0);
signal alu_op : ALU_OP_SELECT;
signal alu_out : std_logic_vector(15 downto 0);

begin

u_seq : entity hproc.sequencer
    generic map ( G_SIM => G_SIM)
    port map (
        aclr => aclr,
        sclr => sclr,
        clk => clk,
        clk_ena => '1',
        
        rav => rav,
        rbv => rbv,
        
        instr_in => code_read_data,
        data_in => data_read_data,
        
        rna => rna,
        rnb => rnb,
        reg_write_addr => reg_write_addr,
        reg_write_ena => reg_write_ena,
        rfsclr => rfsclr,
        
        alu_out => alu_out,
        alu_left => alu_left,
        alu_right => alu_right,
        alu_op => alu_op,
        
        code_addr => code_addr,
        data_addr => data_addr,
        data_out => data_write_data,
        code_read_ena => code_read_ena,
        data_read_ena => data_read_ena,
        data_write_ena => data_write_ena
    );
    
u_reg : entity hproc.register_file
    generic map ( G_SIM => G_SIM)
    port map (
        aclr => aclr,
        sclr => rfsclr,
        clk => clk,
        clk_ena => '1',
        write_ena => reg_write_ena,
        write_addr => reg_write_addr,
        writev => alu_out,
        rna => rna,
        rnb => rnb,
        
        rav_out => rav,
        rbv_out => rbv
    );
    
u_alu : entity hproc.alu
    generic map ( G_SIM => G_SIM)
    port map (
        left_v => alu_left,
        right_v => alu_right,
        alu_select => alu_op,
        
        alu_out => alu_out
    );
    
end rtl;
