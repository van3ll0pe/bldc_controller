library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BLDC_project is
    generic(
        DUTY_SIZE : natural := 8;
        PWM_CYCLE : natural := 10000; -- 10 KHz
        BLDC_CYCLE : natural := 1000000;        -- 1 MHz
        MOTOR_CYCLE: natural := 50      -- 50Hz  
    );
    port(
        duty : in std_logic_vector(DUTY_SIZE-1 downto 0);
        clk : in std_logic;
        rst: in std_logic;
        en: in std_logic;
        U: out std_logic;
        Un: out std_logic;
        V: out std_logic;
        Vn: out std_logic;
        W: out std_logic;
        Wn: out std_logic
    );
end BLDC_project;

architecture behavior of BLDC_project is
    signal sigU, sigUn, sigV, sigVn, sigW, sigWn : std_logic;
    signal sig_state : std_logic_vector(5 downto 0);
begin

sigUUn: entity work.BLDC
        generic map(
           DUTY_SIZE => DUTY_SIZE,
            PWM_CYCLE => PWM_CYCLE,
            BLDC_CYCLE => BLDC_CYCLE,
            MOTOR_CYCLE => MOTOR_CYCLE
        )
        port map(
            DUTY_IN => duty,
            CLK => clk,
            RST => rst,
    
            D => sigU,
            DN => sigUn
        );

sigVVn: entity work.BLDC
        generic map(
           DUTY_SIZE => DUTY_SIZE,
            PWM_CYCLE => PWM_CYCLE,
            BLDC_CYCLE => BLDC_CYCLE,
            MOTOR_CYCLE => MOTOR_CYCLE
        )
        port map(
            DUTY_IN => duty,
            CLK => clk,
            RST => rst,
    
            D => sigV,
            DN => sigVn
        );

sigWWn: entity work.BLDC
        generic map(
           DUTY_SIZE => DUTY_SIZE,
            PWM_CYCLE => PWM_CYCLE,
            BLDC_CYCLE => BLDC_CYCLE,
            MOTOR_CYCLE => MOTOR_CYCLE
        )
        port map(
            DUTY_IN => duty,
            CLK => clk,
            RST => rst,
    
            D => sigW,
            DN => sigWn
        );

    
stateMachine: entity work.state_machine
                port map(
                    clk => clk,  
                    rst =>rst,  
                    state_signals => sig_state
                );


process(sig_state)
begin
    if (en = '1') then
        case sig_state is
            when "000001" =>U <= sigU; Un <= '0'; V <= '0'; Vn <= sigVn; W <= '0'; Wn <= '0';
            when "000010" =>U <= sigU; Un <= '0'; V <= '0'; Vn <= '0'; W <= '0'; Wn <= sigWn;
            when "000100" =>U <= '0'; Un <= '0'; V <= sigV; Vn <= '0'; W <= '0'; Wn <= sigWn;
            when "001000" =>U <= '0'; Un <= sigUn; V <= sigV; Vn <= '0'; W <= '0'; Wn <= '0';
            when "010000" =>U <= '0'; Un <= sigUn; V <= '0'; Vn <= '0'; W <= sigW; Wn <= '0';
            when "100000" =>U <= '0'; Un <= '0'; V <= '0'; Vn <= sigVn; W <= sigW; Wn <= '0';
            when others =>
        end case;
    end if;
end process;
end behavior;