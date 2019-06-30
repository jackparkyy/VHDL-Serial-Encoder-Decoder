library IEEE; -- include ieee library
use IEEE.STD_LOGIC_1164.all; -- include STD_LOGIC_1164 package from IEEE library to use the std_logic and
									  -- std_logic_vector data types which adds U (undefined) and Z (high impedance) assignments to the
									  -- standard VHDL bit and bit_vector data types
use IEEE.STD_LOGIC_UNSIGNED.all; -- Include STD_LOGIC_UNSIGNED package from IEEE library to be able to perform arithmetic,
											-- conversion and comparison operations on the std_logic_vector data type

-- define the interface between the generic linear sequential coding system (lss) and its external environment
ENTITY lssGeneric IS
	GENERIC (errorBits : NATURAL := 4); -- define the number of error bits e.g. if set to 3 then the lss will be a 7/4
	PORT (
		clk, res, test, sin : IN STD_LOGIC; -- define the single point input ports (clock, reset, serial-in & test)
		dout : OUT STD_LOGIC_VECTOR(2**errorBits - (errorBits + 2) downto 0) -- define the output port (data-out) and set it to
																								   -- be as wide as the number of data bits
	);
END lssGeneric;

-- define the internal organisation and operation of the generic lss
ARCHITECTURE rtl OF lssGeneric IS
	-- architecture declarations
	SIGNAL tl 		: STD_LOGIC; -- define the serial transmision line between the output of the encoder and input of the decoder

	-- concurrent statements
	BEGIN
		-- combination logic to instantiate the generic encoder and generic decoder entities inside the generic lss
		encoderGeneric : ENTITY work.encoderGeneric(rtl)
			GENERIC MAP (
				errorBits => errorBits -- pass the number of error bits set in the generic lss to the generic encoder
			)
			PORT MAP (
				sin => sin, -- connect the sin port of the generic encoder directly to the sin port of the generic lss
				clk => clk, -- connect the clk port of the generic encoder directly to the clk port of the generic lss
				res => res, -- connect the res port of the generic encoder directly to the res port of the generic lss
				sout => tl  -- connect the sin port of the generic encoder to the transmision line
			);		
		
		decoderGeneric : ENTITY work.decoderGeneric(rtl)
			GENERIC MAP (
				errorBits => errorBits -- pass the number of error bits set in the generic lss to the generic decoder
			)
			PORT MAP (
				sin	=> tl XOR test, -- connect the sin port of the generic decoder to the transmision line XOR'ed with the test
											 -- port of the generic lss. This allows errors to be indroduced as the signal coming out of
											 -- the generic encoder will be inverted when the test port is set high
				clk	=> clk, -- connect the clk port of the generic encoder directly to the clk port of the generic lss
				res	=> res, -- connect the res port of the generic encoder directly to the res port of the generic lss
				dout	=> dout  -- connect the dout port of the generic encoder directly to the dout port of the generic lss
			);
END rtl;