-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s): Martin Kubièka (xkubic45)
--
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------
entity UART_FSM is
port(
   CLK : in std_logic;
   RST : in std_logic;
	DIN : in std_logic;
	CNT_START : in std_logic_vector (4 downto 0); -- getting mid bit
	CNT_NBITS : in std_logic_vector (3 downto 0); -- counting number of bits loaded
	CNT_STOPBIT : in std_logic_vector (3 downto 0); -- counting last 8 bits of stopbit
	RX_EN : out std_logic; -- receiver enabled
	CNT_EN : out std_logic; -- counter enabled
	DATA_VLD : out std_logic
   );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
type STATE_T is (WAIT_FOR_STARTBIT, GET_MID_BIT, READ_BITS, WAIT_FOR_STOPBIT, DATA_VALID);
signal present_state, next_state : STATE_T := WAIT_FOR_STARTBIT; 
begin
	
	
	-- fsm present state logic
	p_logic: process (RST, CLK) begin
		if (CLK'event) and (CLK='1') then
			present_state <= next_state;
		end if;
	end process;
	
	-- fsm next state logic
	p_next_state_logic: process (present_state, DIN, CNT_START, CNT_NBITS, CNT_STOPBIT) begin
		next_state <= present_state;
		case present_state is
			-- if start bit (DIN == 0) is detected go to GET_MID_BIT state
			when WAIT_FOR_STARTBIT => if DIN = '0' then
													next_state <= GET_MID_BIT;
												end if;
			-- if we are on mid bit (CNT_START == 22) go to READ_BITS state
			when GET_MID_BIT => if CNT_START = "10110" then
											 next_state <= READ_BITS;
										end if;
			-- if we received 8 bits go to WAIT_FOR_STOPBIT state
			when READ_BITS => if CNT_NBITS = "1000" then
										next_state <= WAIT_FOR_STOPBIT;
									end if;
			-- if we are at the end of stop bit (from mid bit + 8) then go to DATA_VALID state
			when WAIT_FOR_STOPBIT => if CNT_STOPBIT = "1000" then
												next_state <= DATA_VALID;
											 end if;
			-- go back to initial state
			when DATA_VALID => next_state <= WAIT_FOR_STARTBIT;
			-- ignore others
			when others => null;
		end case;
	end process;
	
	-- fsm output logic
	p_output_logic: process (present_state) begin
		case present_state is
			when WAIT_FOR_STARTBIT => RX_EN <= '0';
												CNT_EN <= '0';
												DATA_VLD <= '0';			
			when GET_MID_BIT => RX_EN <= '0';
												CNT_EN <= '1';
												DATA_VLD <= '0';
			when READ_BITS => RX_EN <= '1';
												CNT_EN <= '1';
												DATA_VLD <= '0';
			when WAIT_FOR_STOPBIT => RX_EN <= '0';
												CNT_EN <= '0';
												DATA_VLD <= '0';
			when DATA_VALID => RX_EN <= '0';
												CNT_EN <= '0';
												DATA_VLD <= '1';
			when others => RX_EN <= '0';
								CNT_EN <= '0';
								DATA_VLD <= '0';
		end case;
	end process;
	
end behavioral;
