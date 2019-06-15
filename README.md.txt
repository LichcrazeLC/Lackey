COMPILE: 
 nasm -fbin bootloader.asm -o bootloader.bin
  nasm -fbin kernel.asm -o kernel.bin
  cat bootloader.bin kernel.bin > lackey.IMG
  truncate -s 1474560 lackey.IMG

kernel is loaded at sector 303


'flappy' command to enter flappy bird game.
Hit enter while playing to go back to CLI.
'w' while playing to jump with the bird.

'about' to read the data stored in sector 302

'clear' to clear the cli
'read' to read from floppy (parameters drive nr/track/sector/head)
'write' to write to floppy (parameters drive nr/track/sector/head/data to write)
