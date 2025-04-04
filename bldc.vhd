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

        U: out std_logic;
        V: out std_logic;
        W: out std_logic;
        Un: out std_logic;
        Vn: out std_logic;
        Wn: out std_logic;

        duty_u_out : out natural
    );
end BLDC;

architecture behavior of BLDC is
    constant MAX_CPT : natural := BLDC_CYCLE / MOTOR_CYCLE;
    constant MAX_DUTY : natural := (2**DUTY_SIZE) - 1;
    constant MIN_DUTY : natural := (2**DUTY_SIZE) / 2; --LE MIN VAUT 50%

    signal pwm_U, pwm_Un, pwm_V, pwm_Vn, pwm_W, pwm_Wn : std_logic;
    signal S_duty_U, S_duty_Un, S_duty_V, S_duty_Vn, S_duty_W, S_duty_Wn: std_logic_vector(DUTY_SIZE-1 downto 0);
    
begin



process(CLK) --process pour gérer la vitesse progressivement
    variable duty : natural range 0 to (2**DUTY_SIZE) - 1 := MIN_DUTY;
    variable cycle_count : natural range 0 to (MAX_CPT - 1) := 0;
    variable duty_U, duty_Un, duty_V, duty_Vn, duty_W, duty_Wn : natural range 0 to ((2**DUTY_SIZE)-1) := MIN_DUTY;
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


            --gestion du cycle_count du BLDC
            if cycle_count = (MAX_CPT-1) then
                cycle_count := 0;
            else
                cycle_count := cycle_count + 1;
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
                duty_Un := MIN_DUTY;
                duty_Vn := MIN_DUTY;
                duty_Wn := MIN_DUTY;
                duty_U := 0;
                duty_V := 0;
                duty_W := 0;
            elsif cycle_count = 0 then
                duty_U := MIN_DUTY;
                duty_V := MIN_DUTY;
                duty_W := MIN_DUTY;
                duty_Un := 0;
                duty_Vn := 0;
                duty_Wn := 0;
            end if;
            
            --incrémenter et décrementer les signaux en fonction de la position du cycle_count
            if cycle_count < (MAX_CPT / 2) / 2 then
                duty_U := duty_U + step;
                duty_V := duty_V + step;
                duty_W := duty_W + step;
            elsif cycle_count < (MAX_CPT / 2) then
                duty_U := duty_U - step;
                duty_V := duty_V - step;
                duty_W := duty_W - step;
            elsif cycle_count < ((MAX_CPT) / 2) + ((MAX_CPT / 2)/2) then
                duty_Un := duty_Un + step;
                duty_Vn := duty_Vn + step;
                duty_Wn := duty_Wn + step;
            else
                duty_Un := duty_Un - step;
                duty_Vn := duty_Vn - step;
                duty_Wn := duty_Wn - step;
            end if;
            report "duty_u value is : " & integer'image(duty_U);
            report "cycle_step is : " & integer'image(cycle_step);
            report "cycle_step_count :" & integer'image(cycle_step_count);
            duty_u_out <= duty_U;
            -- Convertir en std_logic_vector
            S_duty_U <= std_logic_vector(to_unsigned(duty_U, DUTY_SIZE));
            S_duty_Un <= std_logic_vector(to_unsigned(duty_Un, DUTY_SIZE));
            S_duty_V <= std_logic_vector(to_unsigned(duty_V, DUTY_SIZE));
            S_duty_Vn <= std_logic_vector(to_unsigned(duty_Vn, DUTY_SIZE));
            S_duty_W <= std_logic_vector(to_unsigned(duty_W, DUTY_SIZE));
            S_duty_Wn <= std_logic_vector(to_unsigned(duty_Wn, DUTY_SIZE));
        end if;
    end if;
end process;

pwmU: entity work.pwm
        generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (BLDC_CYCLE/PWM_CYCLE))
        port map (clk => CLK,
                    rst => RST,
                    duty=> S_duty_U,
                    dout => pwm_U);

pwmUn: entity work.pwm
    generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (BLDC_CYCLE/PWM_CYCLE))
    port map (clk => CLK,
            rst => RST,
            duty=> S_duty_Un,
            dout => pwm_Un);

pwmV: entity work.pwm
    generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (BLDC_CYCLE/PWM_CYCLE))
    port map (clk => CLK,
            rst => RST,
            duty=> S_duty_V,
            dout => pwm_V);

pwmVn: entity work.pwm
    generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (BLDC_CYCLE/PWM_CYCLE))
    port map (clk => CLK,
            rst => RST,
            duty=> S_duty_Vn,
            dout => pwm_Vn);


pwmW: entity work.pwm
    generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (BLDC_CYCLE/PWM_CYCLE))
    port map (clk => CLK,
            rst => RST,
            duty=> S_duty_W,
            dout => pwm_W);
    
pwmWn: entity work.pwm
    generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (BLDC_CYCLE/PWM_CYCLE))
    port map (clk => CLK,
        rst => RST,
        duty=> S_duty_Wn,
        dout => pwm_Wn);

U <= pwm_U;
Un <= pwm_Un;
V <= pwm_V;
Vn <= pwm_Vn;
W <= pwm_W;
Wn <= pwm_Wn;

end behavior;