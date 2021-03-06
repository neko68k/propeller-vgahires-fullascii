'' ===========================================================================
''  VGA High-Res Text UI Elements Base UI Support Functions  v1.2
''
''  File: StatusLamp.spin
''  Author: Allen Marincak
''  Copyright (c) 2009 Allen MArincak
''  See end of file for terms of use
'' ===========================================================================
''
''============================================================================
'' Status Lamp
''============================================================================
''
'' Creates status lamp to provide visual feedback of conditions.
''
'' You create this item with the Init() function then you must set a status
'' right away, on or off (or else it will not show anything).


VAR
  word varGdx         'GUI control variable
  long varVgaPos      'screen location of start of input area
  long varScreenPtr   'screen buffer pointer
  long varCxPtr       'points to the text cursor x position variable
  byte varRow         'top row location
  byte varCol         'left col location
  byte varCol2        'right col location
  byte varWidth       'width ... text width is 2 less than total width
  byte varTitleWidth  'number of rows used for title area ( 0 or 2 )
  byte varStatus      '0 = off   1 = on
  byte varVgaCols     'width of screen in columns


PUB Init ( pRow, pCol, pWidth, pTitlePtr, pVgaPtr, pVgaWidth ) | vgaIdx

  varVgaCols    := pVgaWidth
  varRow        := pRow
  varCol        := pCol
  varWidth      := pWidth
  varTitleWidth := strsize( pTitlePtr )
  varScreenPtr  := pVgaPtr
  varCol2       := varCol + varWidth
  
  vgaIdx := varRow * varVgaCols + varCol
  bytefill( @byte[varScreenPtr][vgaIdx], 32, varWidth )
  bytemove( @byte[varScreenPtr][vgaIdx], pTitlePtr, varTitleWidth )

  varVgaPos := varRow*varVgaCols+varCol+varWidth-4 'save status text area start
  byte[varScreenPtr][varVgaPos-2] := ":"


PUB IsIn( pCx, pCy ) : qq

  qq := false

    if ( pCx => varCol ) AND ( pCx =< varCol2 )
      if pCy == varRow
        qq := true

  return qq


PUB Set( pSet, pStr ) | strLen

  varStatus := pSet

  strLen := strsize( pStr )
  strLen := 1 #> strLen <# 4

  bytefill( @byte[varScreenPtr][varVgaPos], 32, 4 )
  bytemove( @byte[varScreenPtr][varVgaPos], pStr, strLen )
  
  'if varStatus == 1
   ' byte[varScreenPtr][varVgaPos+0] += 128
    'byte[varScreenPtr][varVgaPos+1] += 128
    'byte[varScreenPtr][varVgaPos+2] += 128
    'byte[varScreenPtr][varVgaPos+3] += 128


PUB GetStatus
  return varStatus



PUB set_gzidx( gzidx )
  varGdx := gzidx


PUB get_gzidx
  return varGdx

  
{{
┌────────────────────────────────────────────────────────────────────────────┐
│                     TERMS OF USE: MIT License                              │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy│
│of this software and associated documentation files (the "Software"), to    │
│deal in the Software without restriction, including without limitation the  │
│rights to use, copy, modify, merge, publish, distribute, sublicense, and/or │
│sell copies of the Software, and to permit persons to whom the Software is  │
│furnished to do so, subject to the following conditions:                    │
│                                                                            │
│The above copyright notice and this permission notice shall be included in  │
│all copies or substantial portions of the Software.                         │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  │
│IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE │
│AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS│
│IN THE SOFTWARE.                                                            │
└────────────────────────────────────────────────────────────────────────────┘
}}   