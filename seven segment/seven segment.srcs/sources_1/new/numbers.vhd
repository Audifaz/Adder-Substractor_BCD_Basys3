library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
entity seven_segment_display_VHDL is
    Port ( clock_100Mhz, cin : in STD_LOGIC;-- 100Mhz clock on Basys 3 FPGA board
           reset : in STD_LOGIC; -- reset
           x, y  :IN STD_LOGIC_VECTOR(4 DOWNTO 0);        
           Anode_Activate : out STD_LOGIC_VECTOR (3 downto 0);-- 4 Anode signals
           LED_out : out STD_LOGIC_VECTOR (6 downto 0));-- Cathode patterns of 7-segment display
end seven_segment_display_VHDL;

architecture Behavioral of seven_segment_display_VHDL is
signal one_second_counter: STD_LOGIC_VECTOR (27 downto 0);
-- counter for generating 1-second clock enable
signal one_second_enable: std_logic;
-- one second enable for counting numbers
signal displayed_number: STD_LOGIC_VECTOR (15 downto 0);
-- counting decimal number to be displayed on 4-digit 7-segment display
signal LED_BCD: STD_LOGIC_VECTOR (3 downto 0);
signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0);
SIGNAL Z: STD_LOGIC_VECTOR(4 DOWNTO 0);
signal S: STD_LOGIC_VECTOR(5 downto 0);
-- creating 10.5ms refresh period
signal LED_activating_counter: std_logic_vector(1 downto 0);
-- the other 2-bit for creating 4 LED-activating signals
-- count         0    ->  1  ->  2  ->  3
-- activates    LED1    LED2   LED3   LED4
-- and repeat
begin
-- VHDL code for BCD to 7-segment decoder
-- Cathode patterns of the 7-segment LED display 
    Z<=('0' & X(3 downto 0)+Y(3 downto 0)) when  ((cin = '1' and (x(4) = not y(4))) or ((cin = '0') and (x(4) = y(4))))
     else ('0' & x(3 downto 0) +((not y( 3 downto 0))+1));
    S(5)<='0' when ((cin = '0' and ((x(4) = y(4)) and x(4)='0'))
     or (cin = '1' and (x(4) = not y(4)) and y(4)='1') 
     or (cin = '1' and ((x(4) =  y(4)) and z(4)='0') and x(4)='1')
     or (cin = '1' and ((x(4) =  y(4)) and z(4)='1') and x(4)='0')
     or (cin = '0' and ((x(4) =  not y(4)) and z(4)='0') and y(4)='0'))
     else '1'; 
    S(4 downto 0)<= ('0' & ((not Z(3 downto 0))+1)) when (z(4)= '0' and (((x(4) = y(4) and cin='1' and y(4)='0') 
    or (x(4) = not y(4) and cin='0')
    or (x(4) = y(4) and cin='1' and y(4)='1') )))
    else (Z +6) when ((z>9) and (((cin = '1' and (x(4) = not y(4))) or ((cin = '0') and (x(4) = y(4))))))  
    else ('0' & Z(3 downto 0)) when (z(4)='1' and ((x(4)=y(4) and cin='1') or (x(4)= not y(4) and cin='0'))) 
    else Z;  

process(LED_BCD)
begin
    case LED_BCD is
    when "0000" => LED_out <= "0000001"; -- "0"     
    when "0001" => LED_out <= "1001111"; -- "1" 
    when "0010" => LED_out <= "0010010"; -- "2" 
    when "0011" => LED_out <= "0000110"; -- "3" 
    when "0100" => LED_out <= "1001100"; -- "4" 
    when "0101" => LED_out <= "0100100"; -- "5" 
    when "0110" => LED_out <= "0100000"; -- "6" 
    when "0111" => LED_out <= "0001111"; -- "7" 
    when "1000" => LED_out <= "0000000"; -- "8"     
    when "1001" => LED_out <= "0000100"; -- "9" 
    when "1010" => LED_out <= "0000010"; -- a
    when "1011" => LED_out <= "1100000"; -- b
    when "1100" => LED_out <= "0000001"; -- 0
    when "1110" => LED_out <= "1111110"; -- -0
    when "1101" => LED_out <= "1001111"; -- 1
    when "1111" => LED_out <= "1001110"; -- -1
    end case;
  
end process;
-- 7-segment display controller
-- generate refresh period of 10.5ms
process(clock_100Mhz,reset)
begin 
    if(reset='1') then
        refresh_counter <= (others => '0');
    elsif(rising_edge(clock_100Mhz)) then
        refresh_counter <= refresh_counter + 1;
    end if;
end process;
 LED_activating_counter <= refresh_counter(19 downto 18);
-- 4-to-1 MUX to generate anode activating signals for 4 LEDs 
process(LED_activating_counter,S,displayed_number)
begin
    case LED_activating_counter is
    when "00" =>
        Anode_Activate <= "0111"; 
        -- activate LED1 and Deactivate LED2, LED3, LED4
        LED_BCD <= displayed_number(15 downto 12);
        -- the first hex digit of the 16-bit number
    when "01" =>
        Anode_Activate <= "1011"; 
        -- activate LED2 and Deactivate LED1, LED3, LED4
        LED_BCD <= displayed_number(11 downto 8);
        -- the second hex digit of the 16-bit number
    when "10" =>
        Anode_Activate <= "1101"; 
        -- activate LED3 and Deactivate LED2, LED1, LED4
        LED_BCD <= displayed_number(7 downto 4);
        -- the third hex digit of the 16-bit number
    when "11" =>
        Anode_Activate <= "1110"; 
        -- activate LED4 and Deactivate LED2, LED3, LED1
        LED_BCD <= displayed_number(3 downto 0);
        -- the fourth hex digit of the 16-bit number    
    end case;
end process;
-- Counting the number to be displayed on 4-digit 7-segment Display 
-- on Basys 3 FPGA board
process(LED_BCD,S)
begin
displayed_number(3 downto 0)<=S(3 downto 0);
displayed_number(7 downto 4)<="11" & S(5 downto 4);
displayed_number (11 downto 8)<="0000";
displayed_number(15 downto 12)<="0000";
end process;

end Behavioral;
