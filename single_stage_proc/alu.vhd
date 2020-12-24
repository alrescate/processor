-- alu.vhd 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library hproc;
use hproc.hproc_pkg.all;

entity alu is
    generic ( G_SIM: integer := 0);
    port (
        left_v : in data_t;
        right_v : in data_t;
        alu_select : in ALU_OP_SELECT;
        
        alu_out : out data_t
    );
    
end entity alu;
    
architecture rtl of alu is 

signal mult32 : signed(31 downto 0);

begin

    mult32 <= signed(left_v) * signed(right_v);
    
    alu_p : process (left_v, right_v, alu_select, mult32)
    begin
        case alu_select is
            when OP_ADD =>
                alu_out <= std_logic_vector(signed(left_v) + signed(right_v));
            when OP_SUB =>
                alu_out <= std_logic_vector(signed(left_v) - signed(right_v));
            when OP_INC =>
                alu_out <= std_logic_vector(signed(left_v) + to_signed(1, 16));
            when OP_DEC =>
                alu_out <= std_logic_vector(signed(left_v) - to_signed(1, 16));
            when OP_AND =>
                alu_out <= left_v and right_v;
            when OP_IOR =>
                alu_out <= left_v or right_v;
            when OP_XOR =>
                alu_out <= left_v xor right_v;
            when OP_ASR =>
                alu_out <= std_logic_vector(shift_right(signed(left_v), to_integer(unsigned(right_v(4 downto 0)))));
            when OP_LSR =>
                alu_out <= std_logic_vector(shift_right(unsigned(left_v), to_integer(unsigned(right_v(4 downto 0)))));
            when OP_LSL =>
                alu_out <= std_logic_vector(shift_left(unsigned(left_v), to_integer(unsigned(right_v(4 downto 0)))));
            when OP_MULTL =>
                alu_out <= std_logic_vector(mult32(15 downto 0));
            when OP_MULTH =>
                alu_out <= std_logic_vector(mult32(31 downto 16));
            when OP_LT =>
                if (signed(left_v) < signed(right_v)) then alu_out <= ALU_TRUE;
                else                                       alu_out <= ALU_FALSE; end if;
            when OP_LE =>
                if (signed(left_v) <= signed(right_v)) then alu_out <= ALU_TRUE;
                else                                        alu_out <= ALU_FALSE; end if;
            when OP_GT =>
                if (signed(left_v) > signed(right_v)) then alu_out <= ALU_TRUE;
                else                                       alu_out <= ALU_FALSE; end if;
            when OP_GE =>
                if (signed(left_v) >= signed(right_v)) then alu_out <= ALU_TRUE;
                else                                        alu_out <= ALU_FALSE; end if;
            when OP_EQ =>
                if (signed(left_v) = signed(right_v)) then alu_out <= ALU_TRUE;
                else                                       alu_out <= ALU_FALSE; end if;
            when OP_NE =>
                if (signed(left_v) /= signed(right_v)) then alu_out <= ALU_TRUE;
                else                                        alu_out <= ALU_FALSE; end if;
            when OP_NEG =>
                alu_out <= std_logic_vector(-signed(left_v));
            when OP_COM =>
                alu_out <= not left_v;
            when OP_Z =>
                if (signed(left_v) = 0) then alu_out <= ALU_TRUE;
                else                         alu_out <= ALU_FALSE; end if;
            when OP_NZ =>
                if (signed(left_v) /= 0) then alu_out <= ALU_TRUE;
                else                          alu_out <= ALU_FALSE; end if;
            when OP_MI =>
                if (signed(left_v) < 0) then alu_out <= ALU_TRUE;
                else                         alu_out <= ALU_FALSE; end if;
            when OP_PL =>
                if (signed(left_v) >= 0) then alu_out <= ALU_TRUE;
                else                          alu_out <= ALU_FALSE; end if;
            when OP_NOP =>
                alu_out <= (OTHERS => 'X');
            when OP_CP =>
                alu_out <= left_v;
            when OP_SIGNEX =>
                alu_out <= std_logic_vector(resize(signed(left_v(7 downto 0)), 16));
            when OP_CONSTH =>
                alu_out <= right_v(7 downto 0) & left_v(7 downto 0); -- attaches high (from right) on top of current low (on left)
            when OTHERS =>
                alu_out <= (OTHERS => 'X');
        end case;
    end process;
end rtl;
