---------------------------------------
-- Pulse generator test architecture
--
-- For GHDL users:
-- ghdl -a --ieee=synopsys -fexplicit pulse_gen.vhd test_pulse_gen.vhd
-- ghdl -e --ieee=synopsys -fexplicit test_pulse_gen
-- ghdl -r --ieee=synopsys -fexplicit test_pulse_gen --wave=test_pulse_gen.ghw
-- gtkwave test_pulse_gen.ghw
--
-- F.Thiebolt
---------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- component definition
entity test_bldc is
end test_bldc;

-- architecture definition
architecture behaviour of test_bldc is

    -- constant defintions
	constant TIMEOUT 	: time := 8000 ms; -- simulation timeout
    constant clkpulse   : Time := 500 ns; -- 1/2 periode horloge

    -- types/subtypes definitions

    -- signal definitions
    signal E_CLK  : std_logic;
    signal E_RST        : std_logic := '1'; -- active low
    signal E_DUTY : std_logic_vector(7 downto 0) := "11000000";
    signal E_U : std_logic := '0';
    signal E_V : std_logic := '0';
    signal E_W : std_logic := '0';
    signal E_Un : std_logic := '0';
    signal E_Vn : std_logic := '0';
    signal E_Wn : std_logic := '0';
    signal E_HALL : std_logic_vector(2 downto 0):= "000";
    signal E_DUTY_U : natural := 0;

begin

--------------------------
-- definition de l'horloge
P_E_CLK: process
begin
	E_CLK <= '1';
	wait for clkpulse;
	E_CLK <= '0';
	wait for clkpulse;
end process P_E_CLK;

-----------------------------------------
-- definition du timeout de la simulation
P_TIMEOUT: process
begin
	wait for TIMEOUT;
	assert FALSE report "SIMULATION TIMEOUT!!!" severity FAILURE;
end process P_TIMEOUT;

--------------------------------------------------
-- instantiation et mapping du composant registres
pgen0 : entity work.BLDC(behavior)
			generic map (8, 10000, 1E6, 50)
			port map (CLK => E_CLK,
                      RST => E_RST,
                        DUTY_IN=> E_DUTY,
                        U => E_U,
                        V => E_V, 
                        W => E_W,  
                        Un=> E_Un, 
                        Vn=> E_Vn, 
                        Wn=> E_Wn,
                        duty_u_out => E_DUTY_U
                        ); 

-----------------------------


-- Test process
P_TEST: process
begin

	-- initialisations
	E_RST <= '1';
    --E_CLK <= '0'; -- DON'T DO THAT ... guess why ???

	-- sequence RESET
	--E_RST <= '0';
	--wait for clkpulse*3;
	--E_RST <= '1';
	--wait for clkpulse/2;

    E_DUTY <= "10000000";

    wait for 2000 ms;

    E_DUTY <= "11000000";

    wait for 2000 ms;

    E_DUTY <= "11111111";

    wait for 2000 ms;
    E_DUTY <= "00000000";

    wait for 2000 ms;
	-- LATEST COMMAND (NE PAS ENLEVER !!!)
	wait until (E_CLK='0'); wait for clkpulse*3;
	assert FALSE report "FIN DE SIMULATION" severity FAILURE;

end process P_TEST;

end behaviour;