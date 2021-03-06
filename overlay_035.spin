'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │  OverlayLoader Object v0.035                                             │
'' │  Author: Ray Rodrick                                                     │
'' │  Copyright (c) 2008 Ray Rodrick "Cluso99"                                │
'' │  See end of file for terms of use.                                       │
'' └──────────────────────────────────────────────────────────────────────────┘
''      This code is a concept for fast overlaying assembler routines within a COG.
''      Timing:  28-43 clocks overhead + (16 * longs) transferred in clock cycles (12.5nS @ 80MHz)
''      Flags c and z are preserved (not used).
''
''      The OVERLAY_LOAD routine is used as follows...
''            mov       OVERLAY_PAR,overlay_01          '\\ copy overlay01's parameters     
''            jmp       #OVERLAY_LOAD                   '// load & execute overlay01    
''
''      The OVERLAY_LOAD routine can also be used to "call" an overlay...
''      However, the overlay will execute first and it will be the responsibility of the overlay
''      (programmer) to execute a return instruction...
''      Therefore, this type of overlay should only be called from resident_code, not an overlay !! 
''            mov       OVERLAY_PAR,overlay_02          '\\ copy overlay02's parameters  
''            call      #OVERLAY_LOAD                   '|| load & execute overlay02
''            nop       '<-- any instructions           '|| execution will return here PROVIDED the first instruction
''      The overlay returns by...
''            jmp       OVERLAY_LOAD_RET                'return (indirect) to calling routine
''
''      Overlay 00 is loaded as a "freebie" and should follow immediately after the Overlay Loader.
''      By "freebie" I mean that if it follows the loader it will automatically be loaded by cognew.
''
''      Special thanks to kuroneko and Phil Pilgrim for their ideas to speedup the block moves
''      between hub to cog memory.
''      I have used a modified version of Phil Pilgrim's (PhiPi) code to achieve the "sweet spot"
''      which yields a transfer of one long per 16 clock cycles.
''      There must be an even number of longs and it will pad the overlay to meet this requirement.
''
'' RR20080610   commence code  (sample concept)
'' RR20080611   concept working
'' RR20080611   uses the "sweet spot"
'' RR20080614   speed setup to load overlay 32-47 clocks + (16 * no.on.instuctions)
'' RR20080614   Release v030 (remove all debug code)
'' RR20080814   Release v035 (reduce setup to  load overlay 28-43 clocks + (16 * no.on.instuctions)
''              and requires the overlay to be an even length. Flags c and z are preserved and are not used.

CON
  overlay_size = $140           'MUST be EVEN
  
PUB Start  
'The following code places the Overlay Load Parameters into hub memory (so it will be preset in the Cog area by CogNew)
  Overlay_00 := OverlayParams(@overlay00, @overlay00_end)      'copy parameters for overlay00 in hub before loading
  Overlay_01 := OverlayParams(@overlay01, @overlay01_end)       'copy parameters for overlay01 in hub before loading
  Overlay_02 := OverlayParams(@overlay02, @overlay02_end)       'copy parameters for overlay02 in hub before loading
' Overlay_03 := OverlayParams(@overlay03, @overlay03_end)       'copy parameters for overlay03 in hub before loading
'....... add more overlays as required.

  cognew(@overlay_load_ret, 0)                                  'start the base overlay (00)

  repeat                                                        'note this Cog could be stopped

PUB OverlayParams (o_start, o_end) : params | len, hubend, cogend
'This code sets up the parameters for an overlay (in a format to increase overlay loading speed)
  len := o_end - o_start                                        'length of hub overlay (bytes)
  hubend := o_start + len - 1                                   'hub END address (last long) +3 (speed quirk in overlay loader)
  cogend := ((@OVERLAY_START - @entry + len) / 4) - 1           'cog END address (last long)
  params := hubend << 16 + cogend                               'set parameters

DAT

'
'  │ ON INITIAL LOAD, JMP TO ... (can be used for RET instruction later)      │
'  └──────────────────────────────────────────────────────────────────────────┘
              org                         
entry
OVERLAY_LOAD_RET                            '\\ Select one of the following jumps for the first time CogNew execution... 
              jmp       #RESIDENT_CODE      '|| Go execute resident  code first (loaded automatically at CogNew)
'             jmp       #overlay00          '|| Go execute overlay00 code first (loaded automatically at CogNew)
                                            '// Can use as a RET instruction AFTER execution of the loaded overlay        
'
'  │ RESIDENT ROUTINES follow...                                              │
'  └──────────────────────────────────────────────────────────────────────────┘
RESIDENT_CODE 
'  Code (including subroutines) can be included here...
'  They will remain resident but will reduce the overlay space available.

' This resident_code may load (load/execute) another (load/execute) overlay as follows...
              mov       OVERLAY_PAR,overlay_01          '\\ copy overlay01's parameters     
              jmp       #OVERLAY_LOAD                   '// load & execute overlay01    

' This resident_code may also "call" a special (called) overlay as follows...
' ONLY resident_code may "call" a special (called) overlay and it may NEVER be loaded (load/execute)
              mov       OVERLAY_PAR,overlay_02          '\\ copy overlay02's parameters  
              call      #OVERLAY_LOAD                   '|| load & execute overlay02
              nop       '<-- any instructions           '|| execution will return here PROVIDED the first instruction
                                                        '//   of the overlay is "jmp OVERLAY_LOAD_RET"

' WARNING: Do NOT use "res" for reserving longs in the resident_code section as this will crash the "freeloading"
'          of overlay00.

' The following code can be used to check if the required overlay is already loaded
'             mov       t1,OVERLAY_PAR                  '\\ will be =0 if already loaded
'             sub       t1,OVERLAY_xx                   '//
'             tjz       t1,#OVERLAY_START               'already loaded
'             mov       OVERLAY_PAR,overlay_xx          '\\ copy overlayXX's parameters     
'             jmp       #OVERLAY_LOAD                   '// load & execute overlay01    

'
'  │ OVERLAY LOADER follows...                                                │
'  │    An even number of longs will be loaded (for efficiency)               │
'  │    Flags c & z will be maintained                                        │
'  └──────────────────────────────────────────────────────────────────────────┘

Overlay_par   long      0-0                             'overlay parameters for the OVERLAY_LOAD
Overlay_00    long      0-0                             '\\ parameters for overlay 00+ (preset by spin code)
Overlay_01    long      0-0                             '||   bits 31..16 = hub END+3 address (must be even length)
Overlay_02    long      0-0                             '||   bits  8..0  = cog END address
Overlay_03    long      0-0                             '|| (<-- add as required)                

_0x400        long      $0000_0400                      'inc/decrement destination by 2
_djnz0        djnz      overlay_par,#overlay_copy2      'prototype instruction (moved to overlay instruction)
t1            long      0                               'used to determine if overlay already loaded (can be used by other code)

OVERLAY_LOAD
              mov       OVERLAY_START,_djnz0            'Copy djnz instruction to head of overlay area.
              movd      overlay_copy2,overlay_par       'move cog END address into rdlong instruction
              sub       overlay_par,#1                  'decrement cog End address by 1
              movd      overlay_copy1,overlay_par       'move cog END-1 address into rdlong instruction
              shr       overlay_par,#16                 'extract the overlay## hub END address (remove cog address)
overlay_copy2 rdlong    0-0,overlay_par                 'copy long from hub to cog   (hptr ignores last 2 bits!)
              sub       overlay_par,#7                  'decrement hub ptr by 1 long (prev by 1, now by 7)
              sub       overlay_copy2,_0x400            'decrement cog (destination) address by 2
overlay_copy1 rdlong    0-0,overlay_par                 'copy long from hub to cog
              sub       overlay_copy1,_0x400            'decrement cog (destination) address by 2 
'
OVERLAY_START '<--- djnz  overlay_par,#overlay_copy2    'decrement hub ptr by 1 long (now by 1, next by 7)
              '^^^ The above instruction is moved in by the loader and is overwritten by the first overlay
              '    instruction during the final overlay load (rdlong) instruction. (loading is done in reverse)     
'

'
'  │ OVERLAY 00 (This overlay loads automatically with CogNew)                │
'  └──────────────────────────────────────────────────────────────────────────┘
              org       OVERLAY_START
overlay00     nop       '<-- any instructions            

' WARNING: This type of overlay (load/execute) may not be "called" and may NOT "call" an overlay !!
'          It may be loaded (load/execute) from resident_code or from another overlay.

' This overlay may load (load/execute) another (load/execute) overlay as follows...
              mov       OVERLAY_PAR,overlay_01          '\\ copy overlay01's parameters     
              jmp       #OVERLAY_LOAD                   '// load & execute overlay01    

              long      $0[($ - OVERLAY_START) // 2]    'fill to even number of longs (REQUIRED)
overlay00_end
              fit       $1F0
              
'
'  │ OVERLAY 01 (example of a typical "load/execute" overlay)                 │
'  └──────────────────────────────────────────────────────────────────────────┘
              org       OVERLAY_START
overlay01     nop       '<-- any instructions

' WARNING: This type of overlay (load/execute) may not be "called" and may NOT "call" an overlay !!
'          It may be loaded (load/execute) from resident_code or from another overlay.

' This overlay may load (load/execute) another (load/execute) overlay as follows...
              mov       OVERLAY_PAR,overlay_00          '\\ copy overlay00's parameters     
              jmp       #OVERLAY_LOAD                   '// load & execute overlay00    
 
              long      $0[($ - OVERLAY_START) // 2]    'fill to even number of longs (REQUIRED)
overlay01_end 
              fit       $1F0

'
'  │ OVERLAY 02 (example of a special "called" overlay)                       │
'  └──────────────────────────────────────────────────────────────────────────┘
              org       OVERLAY_START
overlay02     jmp       OVERLAY_LOAD_RET                'return (indirect) to calling routine
              nop       '<-- any instructions
' WARNING: This type of overlay (called) may ONLY be "called" from a resident_code routine.
'          An example of it's use could be for loading a library of routines which could then be called from
'          resident_code.

' This overlay may load (load/execute) another (load/execute) overlay as follows...
              mov       OVERLAY_PAR,overlay_00          '\\ copy overlay00's parameters     
              jmp       #OVERLAY_LOAD                   '// load & execute overlay00    
 
              long      $0[($ - OVERLAY_START) // 2]    'fill to even number of longs (REQUIRED)
overlay02_end 
              fit       $1F0

'

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}�