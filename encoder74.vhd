library IEEE; -- include ieee library
use IEEE.STD_LOGIC_1164.all; -- include STD_LOGIC_1164 package from IEEE library to use the std_logic and
									  -- std_logic_vector data types which adds U (undefined) and Z (high impedance) assignments to the
									  -- standard VHDL bit and bit_vector data types
use IEEE.STD_LOGIC_UNSIGNED.all; -- Include STD_LOGIC_UNSIGNED package from IEEE library to be able to perform arithmetic,
											-- conversion and comparison operations on the std_logic_vector data type

-- define the interface between the 7/4 encoder and its external environment
ENTITY encoder74 IS
	PORT (
		clk, res, sin : IN STD_LOGIC; -- define the single point input ports (clock, reset & serial-in)
		sout 			  : OUT STD_LOGIC -- define the single point output port (serial-out)
	);
END encoder74;

-- define the internal organisation and operation of the 7/4 encoder
ARCHITECTURE rtl OF encoder74 IS
	-- architecture declarations
	SIGNAL rxlss : STD_LOGIC_VECTOR(0 to 2); -- define the 3-bit rxlss (receive-linear-sequential-system) shift register

	-- concurrent statements
	BEGIN
		-- combination logic to send encoded data out on the sout port by XOR'ing the sin port with the MSB and LSB of the rxlss
		-- register
		sout <= sin XOR rxlss(0) XOR rxlss(2);
		
		-- define all linear sequential logic as a single process
		PROCESS BEGIN
			WAIT UNTIL RISING_EDGE (clk); -- ensures that each line of code in this process is dependent on a rising clock edge
			
			-- when the reset port is set high, reset register to known state
			IF (res = '1') THEN
				rxlss <= "000";
			-- when the reset port is set low, assign the LSB of the rxlss register to the sin port and shift it to the next MSB
			-- of the rxlss register
			ELSIF (res = '0') THEN
				rxlss <= sin & rxlss(0 to 1);
			END IF;
		END PROCESS;
END rtl;