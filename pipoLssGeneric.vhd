library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY pipoLssGeneric IS
	GENERIC (errorBits : NATURAL := 3);
	PORT (
		clk, res, test : IN STD_LOGIC;
		din		: IN STD_LOGIC_VECTOR(2**errorBits - (errorBits + 2) downto 0);
		dout : OUT STD_LOGIC_VECTOR(2**errorBits - (errorBits + 2) downto 0)
	);
END pipoLssGeneric;

ARCHITECTURE rtl OF pipoLssGeneric IS
	SIGNAL tl 		: STD_LOGIC;

BEGIN
	encoderGeneric : ENTITY work.pisoEncoderGeneric(rtl)
		GENERIC MAP (
			errorBits => errorBits
		)
		PORT MAP (
			pin => din,
			clk => clk,
			res => res,
			sout => tl
		);		
	
	decoderGeneric : ENTITY work.decoderGeneric(rtl)
		GENERIC MAP (
			errorBits => errorBits
		)
		PORT MAP (
			sin	=> tl XOR test,
			clk	=> clk,
			res	=> res,
			dout	=> dout
		);
END rtl;