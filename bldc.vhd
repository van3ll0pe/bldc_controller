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
        HALL: in std_logic_vector(2 downto 0);

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
    signal pwmUN: std_logic;
    signal pwmVN: std_logic;
    signal pwmWN: std_logic;
    signal S_duty: std_logic_vector(DUTY_SIZE-1 downto 0);
begin

process(CLK) --process pour gérer la vitesse progressivement
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

UN_pwm: entity work.pwm(behavior)
        generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=>(CLK_CYCLE / PWM_CYCLE))
        port map (clk => CLK,
                    rst => RST,
                    duty=> S_duty,
                    dout => pwmUN);

VN_pwm: entity work.pwm(behavior)
        generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=>(CLK_CYCLE / PWM_CYCLE))
        port map (clk => CLK,
                    rst => RST,
                    duty=> S_duty,
                    dout => pwmVN);

WN_pwm: entity work.pwm(behavior)
        generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=>(CLK_CYCLE / PWM_CYCLE))
        port map (clk => CLK,
                    rst => RST,
                    duty=> S_duty,
                    dout => pwmWN);

process(CLK) -- gestion des capteurs Hall qui gère aussi le décalage
begin
    case HALL is
        when "001" =>
                        U <= pwmU; Un <= '0'; V <= '0'; Vn <= pwmVn; W <= '0'; Wn <= '0';
        when "010" =>
                        U <= pwmU; Un <= '0'; V <= '0'; Vn <= '0'; W <= '0'; Wn <= pwmWN;
        when "011" =>
                        U <= '0'; Un <= '0'; V <= pwmV; Vn <= '0'; W <= '0'; Wn <= pwmWN;
        when "100" =>
                        U <= '0'; Un <= pwmUN; V <= pwmV; Vn <= '0'; W <= '0'; Wn <= '0';
        when "101" =>
                        U <= '0'; Un <= pwmUN; V <= '0'; Vn <= '0'; W <= pwmW; Wn <= '0';
        when "110" =>
                        U <= '0'; Un <= '0'; V <= '0'; Vn <= pwmVn; W <= pwmW; Wn <= '0';
        when others => U <= '0'; Un <= '0'; V <= '0'; Vn <= '0'; W <= '0'; Wn <= '0'; 
    end case;

end process;


end behavior;