@Echo Off

..\Utilities\Assembler\AS\asw.exe -cpu Z80 -gnuerrors -c -A -L -E -xx Driver\Z80.asm
..\Utilities\Assembler\AS\p2bin.exe Driver\Z80.p "Driver\Driver Program.bin" -r 0x-0x
IF NOT EXIST Driver\Z80.p goto DPERROR
 
:DPERROR
DEL Driver\Z80.p
DEL Driver\Z80.h

Pause

:END