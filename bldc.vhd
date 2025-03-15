library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BLDC is
    generic(
        DUTY_SIZE : natural := 8;
        PWM_CYCLE_MAX : natural := 100;
        MAX_CPT : natural := 1E6/50
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
    signal pwmU_reg: std_logic;
    signal pwmV_reg: std_logic;
    signal pwmW_reg: std_logic;
    signal S_duty: std_logic_vector(DUTY_SIZE-1 downto 0);
    
begin

    process(CLK)
        variable count_cycle: natural range 0 to MAX_CPT - 1 := 0;    -- pour compter le nombre de cycle du moteur
        variable duty_inc: natural range 0 to 2**DUTY_SIZE - 1 := 0;
        variable step : natural range 0 to 2**DUTY_SIZE - 1:= 0;
    begin
        if rising_edge(CLK) then
            step := (to_integer(unsigned(DUTY))) / (((MAX_CPT) / 2));
            if step = 0 then
                step := 1; -- Évite que step soit nul
            end if;
            -- Compteur global pour la synchronisation
            if count_cycle = MAX_CPT - 1 then
                count_cycle := 0;
            else
                count_cycle := count_cycle + 1;
            end if;
            
            if count_cycle < (MAX_CPT / 2) then
                if duty_inc + step >= to_integer(unsigned(DUTY)) then
                    duty_inc := to_integer(unsigned(DUTY));
                else
                    duty_inc := duty_inc + step;
                end if;
            else
                if duty_inc - step <= 0 then
                    duty_inc := 0;
                else
                    duty_inc := duty_inc - step;
                end if;
                
            end if;
            
             S_duty <= std_logic_vector(to_unsigned(duty_inc, DUTY_SIZE));       
        end if;
    end process;

    

    U_pwm: entity work.pwm(behavior)
            generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=>PWM_CYCLE_MAX)
            port map (clk => CLK,
                        rst => RST,
                        duty=> S_duty,
                        dout => pwmU);

    V_pwm: entity work.pwm(behavior)
            generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=>PWM_CYCLE_MAX)
            port map (clk => CLK,
                        rst => RST,
                        duty=> S_duty,
                        dout => pwmV);

    W_pwm: entity work.pwm(behavior)
            generic map (DUTY_SIZE=>DUTY_SIZE, MAX_CPT=>PWM_CYCLE_MAX)
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