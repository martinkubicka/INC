-- uart.vhd: UART controller - receiving part
-- Author(s): Martin Kubièka (xkubic45)
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------
entity UART_RX is
port(	
    CLK: 	    in std_logic;
	RST: 	    in std_logic;
	DIN: 	    in std_logic;
	DOUT: 	    out std_logic_vector(7 downto 0);
	DOUT_VLD: 	out std_logic
);
end UART_RX;  

-------------------------------------------------
architecture behavioral of UART_RX is

-- init
signal cnt_start : std_logic_vector(4 downto 0):="00000";
signal cnt_nbits : std_logic_vector(3 downto 0):="0000";
signal cnt_stopbit : std_logic_vector(3 downto 0):="0000";
signal rx_en : std_logic := '0';
signal cnt_en : std_logic := '0';
signal data_vld : std_logic := '0';

begin
	 FSM: entity work.UART_FSM(behavioral)
    port map (
        CLK 	    => CLK,
        RST 	    => RST,
        DIN 	    => DIN,
        CNT_START => cnt_start,
        CNT_NBITS	=> cnt_nbits,
		  CNT_STOPBIT => cnt_stopbit,
		  RX_EN => rx_en,
		  CNT_EN => cnt_en,
		  DATA_VLD => data_vld
    );

	process (CLK) begin
		if rising_edge(CLK) then
		
			-- set default value of DOUT_VLD to 0
			DOUT_VLD <= '0'; 
		
			-- if counter is enabled start counting to get mid bit
			if cnt_en = '1' then
				cnt_start <= cnt_start + "1";
			-- else there will be WAIT_FOR_STOPBIT state
			else 
				-- if all nedded 8 bits were received start cnt_stopbit counting
				if cnt_nbits = "1000" then
					cnt_stopbit <= cnt_stopbit + "1";
					-- if we we are at the end of stopbit -> reset values
					if cnt_stopbit = "1000" then
						cnt_nbits <= "0000";
						cnt_stopbit <= "0000";
						DOUT_VLD <= '1';
					end if;
				end if;
			end if;
			
			-- if receive data is enabled
			if rx_en = '1' then
				-- if bit on 4th position is 1 (it means that if cnt_start >= 20) -> reason why in fsm is 22 instead of 24
				if cnt_start(4) = '1' then 
					-- reset cnt_start
					cnt_start <= "00000";
					-- switch -> cnt_nbits == 3 -> we want to write 3rd bit on DOUT.. 
					case cnt_nbits is
					when "0000" => DOUT(0) <= DIN;
					when "0001" => DOUT(1) <= DIN;
					when "0010" => DOUT(2) <= DIN;
					when "0011" => DOUT(3) <= DIN;
					when "0100" => DOUT(4) <= DIN;
					when "0101" => DOUT(5) <= DIN;
					when "0110" => DOUT(6) <= DIN;
					when "0111" => DOUT(7) <= DIN;
					when others => null;
					end case;
					-- counting received bits
					cnt_nbits <= cnt_nbits + "1";
				end if;
			end if;
		end if;
	end process;
end behavioral;
