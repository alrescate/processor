-- decode.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pipe_proc;
use pipe_proc.pipe_proc_pkg.all;

entity decode is
    generic ( G_SIM: integer := 0);
    port (
        -- these fields are never in question due to hazards
        aclr : in std_logic;
        sclr : in std_logic;
        clk : in std_logic;
        clk_ena : in std_logic;
        
        -- because the previous phase always finishes before this phase, there is no hazard here
        IF_pc : in data_t;
        IF_instr : in data_t;
        
        -- out ports are not hazards
        rf_raddrA : out std_logic_vector(3 downto 0);
        rf_raddrB : out std_logic_vector(3 downto 0);
        
        -- the subject of read-before-write hazards
        rf_adata : in data_t;
        rf_bdata : in data_t;
        
        -- because we always read the fields, we must specify if we care
        rfa_matters : out std_logic;
        rfb_matters : out std_logic;
         
        -- used to control hazards at the processor level
        valid_in : in std_logic;
        
        -- the subject of another read-before-write hazard
        sp : in data_t;
        
        -- did we use the sp?
        read_sp : out std_logic;
        
        -- out ports are not hazards
        ID_valid : out std_logic;
        ID_ALU_op : out ALU_OP_SELECT; 
        ID_ALU_left : out data_t;
        ID_ALU_right : out data_t;
        ID_rf_waddr : out std_logic_vector(3 downto 0);
        ID_rf_wena : out std_logic;
        ID_rf_adata : out data_t;
        ID_MEM_rf_wena : out std_logic;
        ID_suppress_src : out std_logic_vector(1 downto 0);
        ID_pc_setena : out std_logic;
        ID_pc_out : out data_t;
        ID_MEM_pc_setena : out std_logic; 
        ID_mem_addr_src : out std_logic;
        ID_mem_wdata_src : out std_logic_vector(1 downto 0);
        ID_mem_wena : out std_logic;
        ID_sp_inc : out std_logic;
        ID_sp_dec : out std_logic;
        ID_sp_setena : out std_logic;
        ID_mem_rena : out std_logic;
        ID_halt : out std_logic;
        ID_reset : out std_logic;
        ID_clr : out std_logic;
        
        sys_out : out data_t;
        sys_imm : out std_logic_vector(3 downto 0)
        
        -- rav : in data_t;
        -- rbv : in data_t;
        -- 
        -- data_in : in data_t;
        -- 
        -- rna : out std_logic_vector(3 downto 0);
        -- rnb : out std_logic_vector(3 downto 0);
        -- reg_write_addr : out std_logic_vector(3 downto 0);
        -- reg_write_ena : out std_logic;
        -- rfsclr : out std_logic;
        -- 
        -- alu_out : in data_t;
        -- alu_left : out data_t;
        -- alu_right : out data_t;
        -- alu_op : out ALU_OP_SELECT;
        -- 
        -- code_addr  : out data_t;
        -- data_addr  : out data_t;
        -- data_out   : out data_t;
        -- code_read_ena  : out std_logic;
        -- data_read_ena  : out std_logic;
        -- data_write_ena : out std_logic
    );
    
end entity;

architecture rtl of decode is

signal instr_int : integer range 0 to 65535;

-- aliased ranges
signal reg_b_addr : std_logic_vector(3 downto 0);
signal reg_a_addr : std_logic_vector(3 downto 0);

signal signex_114_8 : std_logic_vector(15 downto 0);
signal signex_110_12 : std_logic_vector(15 downto 0);
signal signex_120_13 : std_logic_vector(15 downto 0);
signal signex_138_6 : std_logic_vector(15 downto 0);

signal SRC_sp_addr : std_logic;
signal SRC_ALU_out_addr : std_logic;

signal SRC_ALU_out_wdata : std_logic_vector(1 downto 0);
signal SRC_pc_wdata : std_logic_vector(1 downto 0);
signal SRC_rf_adata_wdata : std_logic_vector(1 downto 0);

begin

SRC_sp_addr <= '0';
SRC_ALU_out_addr <= '1';

SRC_ALU_out_wdata <= "00";
SRC_pc_wdata <= "01";
SRC_rf_adata_wdata <= "10";

instr_int <= to_integer(unsigned(IF_instr));
reg_b_addr <= IF_instr(3 downto 0);
reg_a_addr <= IF_instr(7 downto 4);
signex_114_8 <= std_logic_vector(resize(signed(IF_instr(11 downto 4)), 16));
signex_110_12 <= std_logic_vector(resize(signed(IF_instr(11 downto 0)), 16));
signex_120_13 <= std_logic_vector(resize(signed(IF_instr(12 downto 0)), 16));
signex_138_6 <= std_logic_vector(resize(signed(IF_instr(13 downto 8)), 16));

rf_raddrA <= reg_a_addr; -- the value from the register in the "a" fields will always be on rf_adata
rf_raddrB <= reg_b_addr; -- the value from the register in the "b" fields will always be on rf_bdata

rfread_decode_com : process (instr_int)
begin
    rfa_matters <= '0';
    rfb_matters <= '0';
    read_sp <= '0';
    -- a and b
    -- store, load, add, sub, and, ior, xor, lsftl, asftr, lsftr, multl, multh, move, 
    -- sklt, skgt, skle, skge, skeq, skne
    if ((instr_int and 16#c000#) = 0)        or -- high 2 bits are unique here
       ((instr_int and 16#c000#) = 16#4000#) or -- high 2 bits are unique here
       ((instr_int and 16#ff00#) = 16#e000#) or -- this was a bug source - the original decoding only  
       ((instr_int and 16#ff00#) = 16#e100#) or -- works in a strictly elsif context, where higher
       ((instr_int and 16#ff00#) = 16#e200#) or -- entries can exclude others. In this context, you
       ((instr_int and 16#ff00#) = 16#e300#) or -- have a serious false positive problem if you don't
       ((instr_int and 16#ff00#) = 16#e400#) or -- decode ALL of the opcode bits for these options
       ((instr_int and 16#ff00#) = 16#e500#) or
       ((instr_int and 16#ff00#) = 16#e600#) or
       ((instr_int and 16#ff00#) = 16#e700#) or
       ((instr_int and 16#ff00#) = 16#e800#) or
       ((instr_int and 16#ff00#) = 16#e900#) or
       ((instr_int and 16#ff00#) = 16#ea00#) or
       ((instr_int and 16#ff00#) = 16#f000#) or
       ((instr_int and 16#ff00#) = 16#f100#) or
       ((instr_int and 16#ff00#) = 16#f200#) or
       ((instr_int and 16#ff00#) = 16#f300#) or
       ((instr_int and 16#ff00#) = 16#f400#) or
       ((instr_int and 16#ff00#) = 16#f500#) then
        rfa_matters <= '1';
        rfb_matters <= '1';
    -- just b
    -- consth, inc, dec, neg, com, callr, jmpr, movrsp, pushr, 
    -- skz, sknz, skmi, skpl, sys
    elsif ((instr_int and 16#7000#) = 16#2000#) or
          ((instr_int and 16#fff0#) = 16#f800#) or -- see above about why these aren't the same
          ((instr_int and 16#fff0#) = 16#f810#) or -- decodes as the registered process
          ((instr_int and 16#fff0#) = 16#f820#) or
          ((instr_int and 16#fff0#) = 16#f830#) or
          ((instr_int and 16#fff0#) = 16#f840#) or
          ((instr_int and 16#fff0#) = 16#f850#) or
          ((instr_int and 16#fff0#) = 16#f860#) or
          ((instr_int and 16#fff0#) = 16#f880#) or
          ((instr_int and 16#fff0#) = 16#fc00#) or
          ((instr_int and 16#fff0#) = 16#fc10#) or
          ((instr_int and 16#fff0#) = 16#fc20#) or
          ((instr_int and 16#fff0#) = 16#fc30#) or 
          ((instr_int and 16#ff00#) = 16#ff00#) then -- except this, which is already unique
        rfb_matters <= '1';
    -- sp
    -- NOTE that anything that says SRC_sp (ex. callr) isn't a hazard because those fields don't get used until wb, when
    -- data hazards (the kind we're dealing with here) are impossible to have outstanding
    -- movspr, popr, retn
    elsif ((instr_int and 16#fff0#) = 16#f870#)  or -- same deal
          ((instr_int and 16#fff0#) = 16#f890#)  or
          ((instr_int               = 16#fe02#)) then -- but not you, because it's not a masked decode
        read_sp <= '1';
    end if;          
end process;

decode_reg : process (aclr, clk)
begin 
    if (aclr = '1') then
        ID_valid <= '0'; 
        ID_ALU_op <= OP_NOP;
        ID_ALU_left <= (OTHERS => '0');
        ID_ALU_right <= (OTHERS => '0');
        ID_rf_waddr <= (OTHERS => '0');
        ID_rf_wena <= '0';
        ID_rf_adata <= (OTHERS => '0');
        ID_MEM_rf_wena <= '0';
        ID_suppress_src <= "00";
        ID_pc_setena <= '0';
        ID_pc_out <= (OTHERS => '0');
        ID_MEM_pc_setena <= '0';
        ID_mem_addr_src <= '1';
        ID_mem_wdata_src <= (OTHERS => '0');
        ID_mem_wena <= '0';
        ID_sp_inc <= '0';
        ID_sp_dec <= '0';
        ID_sp_setena <= '0';
        ID_mem_rena <= '0';
        ID_halt <= '0';
        ID_reset <= '0';
        ID_clr <= '0';
        sys_out <= (OTHERS => '0');
    elsif RISING_EDGE(clk) then
        if (sclr = '1') then
            ID_valid <= '0';
        elsif (clk_ena = '1') then
            ID_valid <= valid_in;  
            ID_ALU_op <= OP_NOP;
            ID_ALU_left <= (OTHERS => '0');
            ID_ALU_right <= (OTHERS => '0');
            ID_rf_waddr <= (OTHERS => '0');
            ID_rf_wena <= '0';
            ID_rf_adata <= rf_adata;
            ID_MEM_rf_wena <= '0';
            ID_suppress_src <= "00";
            ID_pc_setena <= '0';
            ID_pc_out <= IF_pc;
            ID_MEM_pc_setena <= '0';
            ID_mem_addr_src <= '1';
            ID_mem_wdata_src <= (OTHERS => '0');
            ID_mem_wena <= '0';
            ID_sp_inc <= '0';
            ID_sp_dec <= '0';
            ID_sp_setena <= '0';
            ID_mem_rena <= '0';
            ID_halt <= '0';
            ID_reset <= '0';
            ID_clr <= '0';
            sys_out <= (OTHERS => '0');
            
            if (instr_int and 16#c000#) = 0 then 
                -- store instruction
                -- b is memory address, a is value
                ID_ALU_op <= OP_ADD;
                ID_ALU_left <= rf_bdata;
                ID_ALU_right <= signex_138_6;
                ID_mem_addr_src <= SRC_ALU_out_addr;
                ID_mem_wdata_src <= SRC_rf_adata_wdata;
                ID_mem_wena <= '1';
            elsif (instr_int and 16#c000#) = 16#4000# then
                -- load instruction
                -- read b to get the mem addr, put val in a
                ID_ALU_op <= OP_ADD;
                ID_ALU_left <= rf_bdata;
                ID_ALU_right <= signex_138_6;
                ID_rf_waddr <= reg_a_addr;
                ID_MEM_rf_wena <= '1';
                ID_mem_rena <= '1';
            elsif (instr_int and 16#7000#) = 0 then
                -- calli instruction
                ID_ALU_op <= OP_ADD;
                ID_ALU_left <= IF_pc;
                ID_ALU_right <= signex_110_12;
                ID_pc_setena <= '1';
                ID_mem_addr_src <= SRC_sp_addr;
                ID_mem_wdata_src <= SRC_pc_wdata;
                ID_mem_wena <= '1';
                ID_sp_dec <= '1';
            elsif (instr_int and 16#7000#) = 16#1000# then
                -- jmpi instruction
                ID_ALU_op <= OP_ADD;
                ID_ALU_left <= IF_pc;
                ID_ALU_right <= signex_110_12;
                ID_pc_setena <= '1';
            elsif (instr_int and 16#7000#) = 16#2000# then
                -- consth instruction
                ID_ALU_op <= OP_CONSTH;
                ID_ALU_left <= rf_bdata;
                ID_ALU_right <= signex_114_8; -- this will sign extend the immediate, but it doesnt matter since
                                              -- we're only going to use the low 8 bits anyways
                ID_rf_waddr <= reg_b_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#7000#) = 16#3000# then
                -- constl instruction
                ID_ALU_op <= OP_CP;
                ID_ALU_left <= signex_114_8; -- we don't need the ALU to signex this since we did it ourselves
                ID_rf_waddr <= reg_b_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#2000#) = 0 then
                -- pushi instruction
                ID_ALU_op <= OP_CP;
                ID_ALU_left <= signex_120_13;
                ID_mem_addr_src <= SRC_sp_addr;
                ID_mem_wdata_src <= SRC_ALU_out_wdata;
                ID_mem_wena <= '1';
                ID_sp_dec <= '1';
            elsif (instr_int and 16#1f00#) = 16#0000# then
                -- add instruction
                ID_ALU_op <= OP_ADD;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0100# then
                -- sub instruction
                ID_ALU_op <= OP_SUB;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0200# then
                -- and instruction
                ID_ALU_op <= OP_AND;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0300# then
                -- ior instruction
                ID_ALU_op <= OP_IOR;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0400# then
                -- xor instruction
                ID_ALU_op <= OP_XOR;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0500# then
                -- logical shift l instruction
                ID_ALU_op <= OP_LSL;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0600# then
                -- arithmetic shift r instruction
                ID_ALU_op <= OP_ASR;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0700# then
                -- logical shift r instruction
                ID_ALU_op <= OP_LSR;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0800# then
                -- multiply, store the l bits instruction
                ID_ALU_op <= OP_MULTL;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0900# then
                -- multiply, store the h bits instruction
                ID_ALU_op <= OP_MULTH;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#1f00#) = 16#0a00# then
                -- move instruction
                ID_ALU_op <= OP_CP;
                ID_ALU_left <= rf_bdata;
                ID_rf_waddr <= reg_a_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#0f00#) = 0 then
                -- skip less than instruction
                ID_ALU_op <= OP_LT;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#0f00#) = 16#0100# then
                -- skip greater than instruction
                ID_ALU_op <= OP_GT;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#0f00#) = 16#0200# then
                -- skip less than or equal to instruction
                ID_ALU_op <= OP_LE;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#0f00#) = 16#0300# then
                -- skip greater than or equal to instruction
                ID_ALU_op <= OP_GE;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#0f00#) = 16#0400# then
                -- skip equal to instruction
                ID_ALU_op <= OP_EQ;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#0f00#) = 16#0500# then
                -- skip not equal instruction
                ID_ALU_op <= OP_NE;
                ID_ALU_left <= rf_adata;
                ID_ALU_right <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#07f0#) = 0 then
                -- inc instruction
                ID_ALU_op <= OP_INC;
                ID_ALU_left <= rf_bdata;
                ID_rf_waddr <= reg_b_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#07f0#) = 16#0010# then
                -- dec instruction
                ID_ALU_op <= OP_DEC;
                ID_ALU_left <= rf_bdata;
                ID_rf_waddr <= reg_b_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#07f0#) = 16#0020# then
                -- negate instruction
                ID_ALU_op <= OP_NEG;
                ID_ALU_left <= rf_bdata;
                ID_rf_waddr <= reg_b_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#07f0#) = 16#0030# then
                -- complement instruction
                ID_ALU_op <= OP_COM;
                ID_ALU_left <= rf_bdata;
                ID_rf_waddr <= reg_b_addr;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#07f0#) = 16#0040# then
                -- call register instruction
                -- this had suppression behavior before, there's probably a pipeline stall involved in this
                ID_ALU_op <= OP_CP;
                ID_ALU_left <= rf_bdata;
                ID_pc_setena <= '1'; -- there is no pc_setv_src because it can be calculated from MEM_pc_setena (0 in this case)
                ID_mem_addr_src <= SRC_sp_addr;
                ID_mem_wdata_src <= SRC_pc_wdata;
                ID_mem_wena <= '1';
                ID_sp_dec <= '1';                
            elsif (instr_int and 16#07f0#) = 16#0050# then
                -- jump to register instruction
                ID_ALU_op <= OP_CP;
                ID_ALU_left <= rf_bdata;
                ID_pc_setena <= '1';
            elsif (instr_int and 16#07f0#) = 16#0060# then
                -- move reg into sp instruction
                -- there is no sp_setv_src because it's always ALU_out
                ID_ALU_op <= OP_CP;
                ID_ALU_left <= rf_bdata;
                ID_sp_setena <= '1';
            elsif (instr_int and 16#07f0#) = 16#0070# then
                -- move sp into reg instruction
                ID_rf_waddr <= reg_b_addr;
                ID_ALU_op <= OP_CP;
                ID_ALU_left <= sp;
                ID_rf_wena <= '1';
            elsif (instr_int and 16#07f0#) = 16#0080# then
                -- push reg onto stack instruction
                ID_ALU_op <= OP_CP;
                ID_ALU_left <= rf_bdata;
                ID_mem_addr_src <= SRC_sp_addr;
                ID_mem_wdata_src <= SRC_ALU_out_wdata;
                ID_mem_wena <= '1';
                ID_sp_dec <= '1';
            elsif (instr_int and 16#07f0#) = 16#0090# then
                -- pop last on stack into reg
                -- this is a 5 cycle instruction, so this takes all kinds of special stall magic
                ID_rf_waddr <= reg_b_addr;
                ID_ALU_op <= OP_INC;
                ID_ALU_left <= sp;
                ID_MEM_rf_wena <= '1';
                ID_mem_rena <= '1'; -- there is no raddr here because we always read at the ALU_out
                ID_sp_inc <= '1';
            elsif (instr_int and 16#03f0#) = 0 then
                -- skip zero instruction
                ID_ALU_op <= OP_Z;
                ID_ALU_left <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#03f0#) = 16#0010# then
                -- skip not zero instruction
                ID_ALU_op <= OP_NZ;
                ID_ALU_left <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#03f0#) = 16#0020# then
                -- skip minus instruction
                ID_ALU_op <= OP_MI;
                ID_ALU_left <= rf_bdata;
                ID_suppress_src <= "10";
            elsif (instr_int and 16#03f0#) = 16#0030# then
                -- skip plus instruction
                ID_ALU_op <= OP_PL;
                ID_ALU_left <= rf_bdata;
                ID_suppress_src <= "10";
            elsif instr_int = 16#fe00# then
                -- halt instruction
                ID_halt <= '1';
            elsif instr_int = 16#fe01# then
                -- reset instruction
                ID_reset <= '1';
            elsif instr_int = 16#fe02# then
                -- return instruction
                -- note, this returns from exactly one (the most recent) call.
                -- note that this is a 5 cycle and control modifying instruction, so we need stall magic
                ID_ALU_op <= OP_INC;
                ID_ALU_left <= sp;
                ID_MEM_pc_setena <= '1';
                ID_mem_rena <= '1';
                ID_sp_inc <= '1';
            elsif instr_int = 16#fe03# then
                -- clr instruction
                ID_clr <= '1';
            -- sys instructions
            elsif (instr_int and 16#ff00#) = 16#ff00# then
                -- sys instruction puts the bdata on the out line, changes nothing else
                sys_out <= rf_bdata;
                sys_imm <= reg_a_addr; -- this isn't actually reg_a, it's just the same bits
            end if;
        end if;
    end if;
end process;

end architecture;
