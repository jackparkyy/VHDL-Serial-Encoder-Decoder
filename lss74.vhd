library IEEE; -- include ieee library
use IEEE.STD_LOGIC_1164.all; -- include STD_LOGIC_1164 package from IEEE library to use the std_logic and
									  -- std_logic_vector data types which adds U (undefined) and Z (high impedance) assignments to the
									  -- standard VHDL bit and bit_vector data types
use IEEE.STD_LOGIC_UNSIGNED.all; -- Include STD_LOGIC_UNSIGNED package from IEEE library to be able to perform arithmetic,
											-- conversion and comparison operations on the std_logic_vector data type

-- define the interface between the 7/4 linear sequential coding system (lss) and its external environment
ENTITY lss74 IS
	PORT (
		clk, res, sin, test : IN STD_LOGIC; -- define the single point input ports (clock, reset, serial-in & test)
		dout : OUT STD_LOGIC_VECTOR(3 downto 0) -- define the 4 point output port (data-out)
	);
END lss74;

-- define the internal organisation and operation of the 7/4 lss
ARCHITECTURE rtl OF lss74 IS
	-- architecture declarations
	SIGNAL tl : STD_LOGIC; -- define the serial transmision line between the output of the encoder and input of the decoder

	-- concurrent statements
	BEGIN
		-- combination logic to instantiate the 7/4 encoder and 7/4 decoder entities inside the 7/4 lss
		encoder74 : ENTITY work.encoder74(rtl) PORT MAP (
			sin => sin, -- connect the sin port of the 7/4 encoder directly to the sin port of the 7/4 lss
			clk => clk, -- connect the clk port of the 7/4 encoder directly to the clk port of the 7/4 lss
			res => res, -- connect the res port of the 7/4 encoder directly to the res port of the 7/4 lss
			sout => tl -- connect the sin port of the 7/4 encoder to the transmision line
		);
		
		decoder74 : ENTITY work.decoder74(rtl) PORT MAP (
			sin	=> tl XOR test, -- connect the sin port of the 7/4 decoder to the transmision line XOR'ed with the test port
										 -- of the 7/4 lss. This allows errors to be indroduced as the signal coming out of the 7/4
										 -- encoder will be inverted when the test port is set high
			clk	=> clk,  -- connect the clk port of the 7/4 decoder directly to the clk port of the 7/4 lss
			res	=> res,  -- connect the res port of the 7/4 encoder directly to the res port of the 7/4 lss
			dout	=> dout  -- connect the dout port of the 7/4 encoder directly to the dout port of the 7/4 lss
		);
END rtl;