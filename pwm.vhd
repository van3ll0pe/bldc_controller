library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM is
    generic(
        DUTY_SIZE : natural := 8;
        MAX_CPT : natural := 20000
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        duty : in std_logic_vector(DUTY_SIZE-1 downto 0);
        dout : out std_logic
    );
end PWM;

architecture behavior of PWM is
    signal duty_value : natural range 0 to 100 := 0;
    signal nbr_count : natural range 0 to (MAX_CPT-1) := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            duty_value <= (to_integer(unsigned(duty)) * 100)  / ((2**DUTY_SIZE) - 1);
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            nbr_count <= (duty_value * MAX_CPT) / 100;
        end if;
    end process;

    process(clk, rst)
        variable counter : natural range 0 to (MAX_CPT - 1) := 0;
    begin
        if rising_edge(clk) then
            if rst = '0' then
                counter := 0;
                dout <= '0';
            else
                dout <= '0';
                
                if counter = MAX_CPT - 1 then
                    counter := 0;
                else
                    counter := counter + 1;
                end if;

                if counter < nbr_count then
                    dout <= '1';
                end if;
            end if;
        end if;
    end process;
end behavior;
