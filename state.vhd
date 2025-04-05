library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity state_machine is
    port(
        clk : in std_logic;    
        rst : in std_logic;   
        state_signals : out std_logic_vector(5 downto 0)
    );
end state_machine;

architecture behavior of state_machine is

    -- Déclaration des états
    type state_type is (S0, S1, S2, S3, S4, S5);
    signal current_state, next_state : state_type;

begin


    process(clk, rst)
    begin
        if rst = '0' then
            current_state <= S0;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

  
    process(current_state)
    begin
        case current_state is
            when S0 =>
                next_state <= S1;

            when S1 =>
                next_state <= S2;

            when S2 =>
                next_state <= S3;

            when S3 =>
                next_state <= S4;

            when S4 =>
                next_state <= S5; 

            when S5 =>
                next_state <= S0;

        end case;
    end process;

    
    process(current_state)
    begin

        case current_state is
            when S0 =>
                state_signals <= "000001";

            when S1 =>
                state_signals <= "000010";

            when S2 =>
                state_signals <= "000100";

            when S3 =>
                state_signals <= "001000";
            when S4 =>
                state_signals <= "010000";

            when S5 =>
                state_signals <= "100000";
        end case;
    end process;

end behavior;
