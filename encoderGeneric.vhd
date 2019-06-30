library IEEE; -- include ieee library
use IEEE.STD_LOGIC_1164.all; -- include STD_LOGIC_1164 package from IEEE library to use the std_logic and
									  -- std_logic_vector data types which adds U (undefined) and Z (high impedance) assignments to the
									  -- standard VHDL bit and bit_vector data types
use IEEE.STD_LOGIC_UNSIGNED.all; -- Include STD_LOGIC_UNSIGNED package from IEEE library to be able to perform arithmetic,
											-- conversion and comparison operations on the std_logic_vector data type

-- define the interface between the generic encoder and its external environment
ENTITY encoderGeneric IS
	GENERIC (errorBits : NATURAL := 3); -- define the number of error bits e.g. if set to 3 then the encoder will be a 7/4
													-- encoder
	PORT (
		clk, res, sin	: IN STD_LOGIC; -- define the single point input ports (clock, reset & serial-in)
		sout 				: OUT STD_LOGIC -- define the single point output port (serial-out)
	);
END encoderGeneric;

-- define the internal organisation and operation of the generic encoder
ARCHITECTURE rtl OF encoderGeneric IS
	-- architecture declarations
	SIGNAL rxlss : STD_LOGIC_VECTOR(0 to errorBits - 1) := (others => '0'); -- define the rxlss (receive-linear-sequential-
																									-- system) shift register and set it to be as
																									-- wide as the number of error bits

	-- concurrent statements
	BEGIN
		-- combination logic to send encoded data out on the sout port by XOR'ing the sin port with the two MSB's of the rxlss
		-- register
		sout <= sin XOR rxlss(errorBits - 2) XOR rxlss(errorBits - 1);
		
		-- define all linear sequential logic as a single process
		PROCESS BEGIN
			WAIT UNTIL RISING_EDGE (clk); -- ensures that each line of code in this process is dependent on a rising clock edge
			
			-- when the reset port is set high, reset register to known state
			IF (res = '1') THEN
				rxlss <= (others => '0'); -- set all bits low
			-- when the reset port is set low, assign the LSB of the rxlss register to the sin port and shift each bit of the
			-- rxlss register up to the next MSB
			ELSIF (res = '0') THEN
				rxlss <= sin & rxlss(0 to errorBits - 2);
			END IF;
		END PROCESS;
END rtl;