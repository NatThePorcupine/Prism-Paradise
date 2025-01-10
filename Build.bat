@echo off

set ROM=ROM
set /a "PAD=1"

IF EXIST %ROM%.mdrv move /Y %ROM%.mdrv %ROM%_prev.mdrv >NUL

Utilities\Assembler\AS\asw.exe -cpu Z80 -gnuerrors -a -A -L -E -xx Sound\Driver\Z80.asm
IF NOT EXIST Sound\Driver\Z80.p goto Z80ERROR
Utilities\Assembler\AS\p2bin.exe Sound\Driver\Z80.p "Sound\Driver\Driver Program.bin" -r 0x-0x

Utilities\Assembler\asm68k.exe /m /p Main.asm, %ROM%.mdrv, , _LISTINGS.lst>_ERROR.log
type _ERROR.log
if not exist %ROM%.mdrv pause & exit
echo.

if "%PAD%"=="1" Utilities\rompad.exe %ROM%.mdrv 255 0
Utilities\fixheadr.exe %ROM%.mdrv
Config\Error\ConvSym.exe _SYMBOLS.sym %ROM%.mdrv -input asm68k_sym -a

del _Z80ERR.log
del _ERROR.log
del _SYMBOLS.sym

del "Sound\Driver\Driver Program.bin"
del Sound\Driver\Z80.p

move Sound\Driver\Z80.lst
del Sound\Driver\Z80.lst
del _Z80LIST.lst
ren Z80.lst _Z80LIST.lst

echo.
exit

:Z80ERROR
del "Sound\Driver\Driver Program.bin"
del Sound\Driver\Z80.inc

move Sound\Driver\Z80.log
del Sound\Driver\Z80.log
del _Z80ERR.log
ren Z80.log _Z80ERR.log

move Sound\Driver\Z80.lst
del Sound\Driver\Z80.lst
del _Z80LIST.lst
ren Z80.lst _Z80LIST.lst