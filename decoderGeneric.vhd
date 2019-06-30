library IEEE; -- include ieee library
use IEEE.STD_LOGIC_1164.all; -- include STD_LOGIC_1164 package from IEEE library to use the std_logic and
									  -- std_logic_vector data types which adds U (undefined) and Z (high impedance) assignments to the
									  -- standard VHDL bit and bit_vector data types
use IEEE.STD_LOGIC_UNSIGNED.all; -- Include STD_LOGIC_UNSIGNED package from IEEE library to be able to perform arithmetic,
											-- conversion and comparison operations on the std_logic_vector data type

-- define the interface between the generic decoder and its external environment
ENTITY decoderGeneric IS
	GENERIC (errorBits	: NATURAL := 3); -- define the number of error bits e.g. if set to 3 then the decoder will be a 7/4
													  -- decoder
	PORT (
		clk, res, sin 	: IN STD_LOGIC; -- define the single point input ports (clock, reset & serial-in)
		dout 				: OUT STD_LOGIC_VECTOR(2**errorBits - (errorBits + 2) downto 0) -- define the output port (data-out) and
																												 -- set it to be as wide as the number of
																												 -- data bits
	);
END decoderGeneric;

-- define the internal organisation and operation of the generic decoder
ARCHITECTURE rtl OF decoderGeneric IS
	-- architecture declarations
	
	-- calculate the number of data bits and total number of bits (error bits + data bits) given the number of error bits and
	-- define them as constants
	CONSTANT dataBits	: NATURAL 												:= 2**errorBits - (errorBits + 1);
	CONSTANT allBits	: NATURAL 												:= errorBits + dataBits;
	
	SIGNAL 	rxlss 	: STD_LOGIC_VECTOR(errorBits - 1 downto 0) 	:= (errorBits - 1 downto 0 => '0'); -- define the rxlss
																																		-- (receive-linear-
																																		-- sequential-system)
																																		-- shift register and
																																		-- set it to be as wide
																																		-- as the number of
																																		-- error bits
	SIGNAL 	control	: STD_LOGIC_VECTOR(allBits - 1 downto 0); -- define the control shift register and set it to be as
																					-- wide as the total number of bits
	SIGNAL 	sipo 		: STD_LOGIC_VECTOR(allBits - 1 downto 0) 		:= (allBits - 1 downto 0 => '0'); -- define the sipo
																																	 -- (serial-in-parallel-
																																	 -- out) shift register
																																	 -- and set set it to be
																																	 -- as wide as the total
																																	 -- number of bits
	-- concurrent statements
	BEGIN
		-- define all linear sequential logic as a single process
		PROCESS BEGIN
			WAIT UNTIL RISING_EDGE (clk); -- ensures that each line of code in this process is dependent on a rising clock edge
			
			-- when the reset port is set high, reset all registers to known state
			IF (res = '1') THEN
				control <= '1' & (allBits - 2 downto 0 => '0');  -- set the MSB high and all other bits low
				rxlss <= (errorBits - 1 downto 0 => '0'); -- set all bits low
				sipo <= (allBits - 1 downto 0 => '0');  -- set all bits low
			-- when the reset port is set low, decode data coming in on the sin port sequentially and correct single bit errors
			ELSIF (res = '0') THEN
				-- decode the data coming in on the sin port by assigning the LSB of the rxlss register to the sin port XOR'ed
				-- with the two MSB's of the rxlss regiester. However, when all bits have been received on the sin port (MSB of
				-- the control register is low) set the LSB of the rxlss register low
				rxlss(0) <= (sin XOR rxlss(errorBits - 2) XOR rxlss(errorBits - 1)) AND NOT(control(0));
				
				-- shift the current value of each bit in the rxlss register up to the next MSB but set them low when all bits
				-- have been received
				FOR i IN 1 TO errorBits - 1 LOOP
					rxlss(i) <= rxlss(i - 1) AND NOT(control(0));
				END LOOP;
				
				-- store decoded data in sipo register by assigning the MSB to the sin port XOR'ed with the two MSB's of the
			   -- rxlss register and shifting the current value of each bit down to the next LSB
				sipo <= (sin XOR rxlss(errorBits - 2) XOR rxlss(errorBits - 1)) & sipo(allBits - 1 downto 1);
				
				-- keep track of the number of bits received sequentially on the sin port by shifting each bit of the control 
				-- register to the next LSB and looping the LSB back round to the MSB (a single bit will always be high while the
				-- others are low)
				control <= control(0) & control(allBits - 1 downto 1);
				
				-- when the number of the error bits has been set to 3 and the sipo register has been filled (all 7-bits have been
				-- received on sin port and decoded), comapre the 3 MSB's of the sipo register (error bits) with the noise look-up
				-- table for a 7/4 decoder
				IF (control(allBits - 1) = '1') AND errorBits = 3 THEN
					CASE (sipo(allBits - 1 downto dataBits)) IS
						-- when single bit error is present XOR data bits of sipo with appropriate value from look-up table and send
						-- out the corrected data in parallel on the dout port
						WHEN "001" => dout <= (sipo(3 downto 0)) XOR ("1101");
						WHEN "011" => dout <= (sipo(3 downto 0)) XOR ("1010");
						WHEN "111" => dout <= (sipo(3 downto 0)) XOR ("0100");
						WHEN "110" => dout <= (sipo(3 downto 0)) XOR ("1000");
						-- when no single bit error is present or the data bits of sipo are "000" send out the data bits of sipo in
						-- parallel on the dout port
						WHEN OTHERS => dout <= sipo(3 downto 0);
					END CASE;
				-- when the number of the error bits has been set to 4 and the sipo register has been filled (all 15-bits have been
				-- received on sin port and decoded), comapre the 4 MSB's of the sipo register (error bits) with the noise look-up
				-- table for a 15/11 decoder
				ELSIF (control(allBits - 1) = '1') AND errorBits = 4 THEN
					CASE (sipo(allBits - 1 downto dataBits)) IS
						-- when single bit error is present XOR data bits of sipo with appropriate value from look-up table and send
						-- out the corrected data in parallel on the dout port
						WHEN "0001" => dout <= (sipo(10 downto 0)) XOR ("11101011001");
						WHEN "0011" => dout <= (sipo(10 downto 0)) XOR ("11010110010");
						WHEN "0111" => dout <= (sipo(10 downto 0)) XOR ("10101100100");
						WHEN "1111" => dout <= (sipo(10 downto 0)) XOR ("01011001000");
						WHEN "1110" => dout <= (sipo(10 downto 0)) XOR ("10110010000");
						WHEN "1101" => dout <= (sipo(10 downto 0)) XOR ("01100100000");
						WHEN "1010" => dout <= (sipo(10 downto 0)) XOR ("11001000000");
						WHEN "0101" => dout <= (sipo(10 downto 0)) XOR ("10010000000");
						WHEN "1011" => dout <= (sipo(10 downto 0)) XOR ("00100000000");
						WHEN "0110" => dout <= (sipo(10 downto 0)) XOR ("01000000000");
						WHEN "1100" => dout <= (sipo(10 downto 0)) XOR ("10000000000");
						-- when no single bit error is present or the data bits of sipo are "000" send out the data bits of sipo in
						-- parallel on the dout port
						WHEN OTHERS => dout <= sipo(10 downto 0);
					END CASE;
				END IF;
			END IF;
		END PROCESS;
END rtl;