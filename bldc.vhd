library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BLDC is
    generic(
        DUTY_SIZE : natural := 8;
        PWM_CYCLE : natural := 10000; -- 10 KHz
        BLDC_CYCLE : natural := 1000000;        -- 1 MHz
        MOTOR_CYCLE: natural := 50      -- 50Hz  
    );
    port(
        DUTY_IN: in std_logic_vector(DUTY_SIZE - 1 downto 0);
        CLK: in std_logic;
        RST: in std_logic;

        D: out std_logic;
        DN: out std_logic
    );
end BLDC;

architecture behavior of BLDC is
    constant MAX_CPT : natural := BLDC_CYCLE / MOTOR_CYCLE;
    constant MAX_DUTY : natural := (2**DUTY_SIZE) - 1;
    constant MIN_DUTY : natural := (2**DUTY_SIZE) / 2; --LE MIN VAUT 50%

    signal S_duty_D, S_duty_DN: std_logic_vector(DUTY_SIZE-1 downto 0);

    signal state_out : std_logic_vector(5 downto 0);
    
begin



process(CLK) --process pour gérer la vitesse progressivement
    variable duty : natural range 0 to (2**DUTY_SIZE) - 1 := MIN_DUTY;
    variable cycle_count : natural range 0 to (MAX_CPT - 1) := 0;
    variable duty_D, duty_DN : natural range 0 to ((2**DUTY_SIZE)-1) := MIN_DUTY;
    variable cycle_step : natural range 0 to (MAX_CPT - 1) := 0;
    variable cycle_step_count : natural range 0 to (MAX_CPT-1) := 0;
    variable step : natural range 0 to 1:= 0;
begin
    if rising_edge(CLK) then
        if RST = '0' then
            cycle_count := 0;
        else

            --toujours set DUTY à DUTY_MIN si inferieur sinon on donne la valeur de DUTY
            if to_integer(unsigned(DUTY_IN)) > MIN_DUTY then
                duty := to_integer(unsigned(DUTY_IN));
            else
                duty := MIN_DUTY;
            end if;
            
            --calcul du step (le nombre de cycle pour incrémenter à 1 les dutys)
            if (duty - MIN_DUTY > 0) then
                cycle_step := (MAX_CPT/4) / (duty - MIN_DUTY);
            else
                cycle_step := MAX_CPT - 1;
            end if;


           
            
            if cycle_step_count >= cycle_step then
                cycle_step_count := 0;
                step := 1;
            elsif cycle_step_count < (MAX_CPT - 1) then
                cycle_step_count := cycle_step_count + 1;
                step := 0;
            end if;
            

            --remettre à 0 les signaux de sortie en fonction du nombre de cycle
            if cycle_count = (MAX_CPT / 2) then
                duty_D := 0;
                duty_DN:= MIN_DUTY;
            elsif cycle_count = 0 then
                duty_DN := 0;
                DUTY_D := MIN_DUTY;
            end if;
            
            --incrémenter et décrementer les signaux en fonction de la position du cycle_count
            if cycle_count < (MAX_CPT / 2) / 2 then
                duty_D := duty_D + step;
            elsif cycle_count < (MAX_CPT / 2) then
                duty_D := duty_D - step;
            elsif cycle_count < ((MAX_CPT) / 2) + ((MAX_CPT / 2)/2) then
                duty_DN := duty_DN + step;
            else
                duty_DN := duty_DN - step;
            end if;
            
             --gestion du cycle_count du BLDC
             if cycle_count = (MAX_CPT-1) then
                cycle_count := 0;
            else
                cycle_count := cycle_count + 1;
            end if;

            -- Convertir en std_logic_vector
            S_duty_D <= std_logic_vector(to_unsigned(duty_D, DUTY_SIZE));
            S_duty_DN <= std_logic_vector(to_unsigned(duty_DN, DUTY_SIZE));
           
        end if;
    end if;
end process;

pwmD: entity work.pwm
        generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (BLDC_CYCLE/PWM_CYCLE))
        port map (clk => CLK,
                    rst => RST,
                    duty=> S_duty_D,
                    dout =>D);

pwmDN: entity work.pwm
    generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (BLDC_CYCLE/PWM_CYCLE))
    port map (clk => CLK,
            rst => RST,
            duty=> S_duty_DN,
            dout => Dn);


end behavior;