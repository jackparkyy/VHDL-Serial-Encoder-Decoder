library IEEE; -- include ieee library
use IEEE.STD_LOGIC_1164.all; -- include STD_LOGIC_1164 package from IEEE library to use the std_logic and
									  -- std_logic_vector data types which adds U (undefined) and Z (high impedance) assignments to the
									  -- standard VHDL bit and bit_vector data types
use IEEE.STD_LOGIC_UNSIGNED.all; -- Include STD_LOGIC_UNSIGNED package from IEEE library to be able to perform arithmetic,
											-- conversion and comparison operations on the std_logic_vector data type

-- define the interface between the generic encoder and its external environment
ENTITY pisoEncoderGeneric IS
	GENERIC (errorBits : NATURAL := 3); -- define the number of error bits e.g. if set to 3 then the encoder will be a 7/4
													-- encoder
	PORT (
		clk, res	: IN STD_LOGIC; -- define the single point input ports (clock & reset)
		pin		: IN STD_LOGIC_VECTOR(2**errorBits - (errorBits + 2) downto 0); -- define the input port (parellel-in) and
																										 -- set it to be as wide as the number of
																										 -- data bits
		sout 		: OUT STD_LOGIC -- define the single point output port (serial-out)
	);
END pisoEncoderGeneric;

-- define the internal organisation and operation of the generic encoder
ARCHITECTURE rtl OF pisoEncoderGeneric IS
	-- architecture declarations
	
	-- calculate the number of data bits and total number of bits (error bits + data bits) given the number of error bits and
	-- define them as constants
	CONSTANT dataBits	: NATURAL 											:= 2**errorBits - (errorBits + 1);
	CONSTANT allBits	: NATURAL 											:= errorBits + dataBits;
	
	SIGNAL data			: STD_LOGIC_VECTOR(dataBits - 1 downto 0) := (others => '0'); -- define the data shift register and set
																											  -- it to be as wide as the number of data
																											  -- bits
	SIGNAL control 	: STD_LOGIC_VECTOR(allBits - 1 downto 0); -- define the control shift register and set it to be as
																					-- wide as the total number of bits
	SIGNAL rxlss 		: STD_LOGIC_VECTOR(0 to errorBits - 1) 	:= (others => '0'); -- define the rxlss (receive-linear-
																											  -- sequential-system) shift register and
																											  --  set it to be as wide as the number of
																											  --  error bits
	
	-- concurrent statements
	BEGIN
		-- combination logic to send encoded data out on the sout port by XOR'ing the sin port with the two MSB's of the rxlss
		-- register
		sout <= data(dataBits - 1) XOR rxlss(errorBits - 2) XOR rxlss(errorBits - 1);
		
		-- define all linear sequential logic as a single process
		PROCESS BEGIN
			WAIT UNTIL RISING_EDGE (clk); -- ensures that each line of code in this process is dependent on a rising clock edge
			
			-- when the reset port is set high, reset register to known state
			IF (res = '1') THEN
				control <= '1' & (allBits - 2 downto 0 => '0');  -- set the MSB high and all other bits low
				rxlss <= (others => '0'); -- set all bits low
				data <= (others => '0'); -- set all bits low
			-- when the reset port is set low, shift data out of the data register serially and encode it
			ELSIF (res = '0') THEN				
				-- assign the LSB of the rxlss register to the MSB of the data register and shift each bit of the rxlss register
				-- up to the next MSB
				rxlss(0) <= data(dataBits - 1);
				FOR i IN 1 TO errorBits - 1 LOOP
					rxlss(i) <= rxlss(i - 1);
				END LOOP;
				
				-- shift each bit of the data register up to the next MSB
				data <= data(dataBits - 2 downto 0) & '0';
				
				-- keep track of the number of bits shifted out of the data register sequentially by shifting each bit to the 
				-- next LSB and looping the LSB back round to the MSB (a single bit will always be high while the others are low)
				control <= control(0) & control(allBits - 1 downto 1);
				
				-- when the encoder is reset or all bits of the previous data set have been encoded (MSB of the control register
				-- is high), load data on the pin port into the data register in parellel
				IF (control(allBits - 1) = '1') THEN
					FOR i IN 0 TO dataBits - 1 LOOP
						data(i) <= pin(i);
					END LOOP;
				END IF;
			END IF;
		END PROCESS;
END rtl;