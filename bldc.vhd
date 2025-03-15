library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BLDC is
    generic(
        DUTY_SIZE : natural := 8;
        PWM_CYCLE : natural := 10000; -- 10 KHz
        CLK_CYCLE: natural := 1000000;        -- 1 MHz
        MOTOR_CYCLE: natural := 50      -- 50Hz
    );
    port(
        DUTY: in std_logic_vector(DUTY_SIZE - 1 downto 0);
        CLK: in std_logic;
        RST: in std_logic;

        U: out std_logic;
        V: out std_logic;
        W: out std_logic;
        Un: out std_logic;
        Vn: out std_logic;
        Wn: out std_logic
    );
end BLDC;

architecture behavior of BLDC is
    signal pwmU: std_logic;
    signal pwmV: std_logic;
    signal pwmW: std_logic;
    signal S_duty: std_logic_vector(DUTY_SIZE-1 downto 0);
begin

    process(CLK)
    variable cycle_count : natural range 0 to (CLK_CYCLE / MOTOR_CYCLE) - 1 := 0;
    variable duty_inc : natural range 0 to (2**DUTY_SIZE) - 1 := 0;
    variable acc : natural := 0; -- Accumulateur pour gérer les fractions
    variable dir : boolean := true; -- true = montée, false = descente
begin
    if rising_edge(CLK) then
        if cycle_count = (CLK_CYCLE / MOTOR_CYCLE) / 2 - 1 then
            cycle_count := 0;
            dir := not dir;
        else
            cycle_count := cycle_count + 1;
        end if;


        acc := acc + to_integer(unsigned(DUTY));
        if acc >= 10000 then
            if dir then
                if duty_inc < to_integer(unsigned(DUTY)) then
                    duty_inc := duty_inc + 1;
                end if;
            else
                if duty_inc > 0 then
                    duty_inc := duty_inc - 1;
                end if;
            end if;
            acc := acc - 10000;
        end if;

        -- Convertir en std_logic_vector
        S_duty <= std_logic_vector(to_unsigned(duty_inc, DUTY_SIZE));
    end if;
end process;

    U_pwm: entity work.pwm(behavior)
            generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=> (CLK_CYCLE / PWM_CYCLE))
            port map (clk => CLK,
                        rst => RST,
                        duty=> S_duty,
                        dout => pwmU);

    V_pwm: entity work.pwm(behavior)
            generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=>(CLK_CYCLE / PWM_CYCLE))
            port map (clk => CLK,
                        rst => RST,
                        duty=> S_duty,
                        dout => pwmV);

    W_pwm: entity work.pwm(behavior)
            generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=>(CLK_CYCLE / PWM_CYCLE))
            port map (clk => CLK,
                        rst => RST,
                        duty=> S_duty,
                        dout => pwmW);

    
    U <= pwmU;
    V <= pwmV;
    W <= pwmW;
    Un <= not pwmU;
    Vn <= not pwmV;
    Wn <= not pwmW;


end behavior;