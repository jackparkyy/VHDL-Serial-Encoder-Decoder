library IEEE; -- include ieee library
use IEEE.STD_LOGIC_1164.all; -- include STD_LOGIC_1164 package from IEEE library to use the std_logic and
									  -- std_logic_vector data types which adds U (undefined) and Z (high impedance) assignments to the
									  -- standard VHDL bit and bit_vector data types
use IEEE.STD_LOGIC_UNSIGNED.all; -- Include STD_LOGIC_UNSIGNED package from IEEE library to be able to perform arithmetic,
											-- conversion and comparison operations on the std_logic_vector data type

-- define the interface between the 7/4 decoder and its external environment
ENTITY decoder74 IS
	PORT (
		clk, res, sin : IN STD_LOGIC; -- define the single point input ports (clock, reset & serial-in)
		dout 			  : OUT STD_LOGIC_VECTOR(3 downto 0) -- define the 4 point output port (data-out)
	);
END decoder74;

-- define the internal organisation and operation of the 7/4 decoder
ARCHITECTURE rtl OF decoder74 IS
	-- architecture declarations
	SIGNAL control 	: STD_LOGIC_VECTOR(6 downto 0); -- define the 7-bit control shift register
	SIGNAL rxlss 		: STD_LOGIC_VECTOR(2 downto 0); -- define the 3-bit rxlss (receive-linear-sequential-system) shift register
	SIGNAL sipo 		: STD_LOGIC_VECTOR(6 downto 0); -- define the 7-bit sipo (serial-in-parallel-out) shift register
	
	-- concurrent statements
	BEGIN
		-- define all linear sequential logic as a single process
		PROCESS BEGIN
			WAIT UNTIL RISING_EDGE (clk); -- ensures that each line of code in this process is dependent on a rising clock edge
			
			-- when the reset port is set high, reset all registers to known state
			IF (res = '1') THEN
				control <= "1000000";
				rxlss <= "000";
				sipo <= "0000000";
			-- when the reset port is set low, decode data coming in on the sin port sequentially and correct single bit errors
			ELSIF (res = '0') THEN
				rxlss(0) <= (sin XOR rxlss(2) XOR rxlss(0)) AND NOT(control(0)); -- decode the data coming in on the sin port by 
																									  -- assigning the LSB of the rxlss register to the
																									  -- sin port XOR'ed with the MSB and LSB of the
																									  -- rxlss regiester. However, when all 7-bits
																									  -- have been received on the sin port (MSB of the
																									  -- control register is low) set the LSB of the
																									  -- rxlss register low
																									  
				-- shift the current value of each bit in the rxlss register to the next MSB but set them low when all 7-bits
				-- have been received
				rxlss(1) <= rxlss(0) AND NOT(control(0));
				rxlss(2) <= rxlss(1) AND NOT (control(0));
				
				-- store decoded data in sipo register by assigning the MSB to the sin port XOR'ed with the MSB and LSB of the
			   -- rxlss register and shifting the current value of each bit down to the next LSB
				sipo <= (sin XOR rxlss(2) XOR rxlss(0)) & sipo(6 downto 1);
				
				-- keep track of the number of bits received sequentially on the sin port by shifting each bit to the next LSB and
				-- looping the LSB back round to the MSB (a single bit will always be high while the others are low)
				control <= (control(0)) & (control(6 downto 1));
				
				-- when the sipo register has been filled (all 7-bits have been received on sin port and decoded) check for single
				-- bit errors and correct them by comparing the 3 MSB's of the sipo register (error bits) with the noise look-up
				-- table
				IF (control(6) = '1') THEN
					CASE (sipo(6 downto 4)) IS
						-- when single bit error is present XOR data bits of sipo with appropriate value from look-up table and send
						-- out the corrected data in parallel on the dout port
						WHEN "001" => dout <= (sipo(3 downto 0)) XOR ("0111");
						WHEN "010" => dout <= (sipo(3 downto 0)) XOR ("1110");
						WHEN "101" => dout <= (sipo(3 downto 0)) XOR ("1100");
						WHEN "011" => dout <= (sipo(3 downto 0)) XOR ("1000");
						-- when no single bit error is present or the data bits of sipo are "000" send out the data bits of sipo in
						-- parallel on the dout port
						WHEN OTHERS => dout <= sipo(3 downto 0);
					END CASE;
				END IF;
			END IF;
		END PROCESS;
END rtl;