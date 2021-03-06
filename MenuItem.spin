'' ===========================================================================
''  VGA High-Res Text UI Elements Base UI Support Functions  v1.2
''
''  File: MenuItem.spin
''  Author: Allen Marincak
''  Copyright (c) 2009 Allen MArincak
''  See end of file for terms of use
'' ===========================================================================
''
''============================================================================
'' MenuItem Control
''============================================================================
''
'' Creates a menu item. This is really like a text button, but when placed with
'' others and inside a simple box it can look like a menu bar. User determined
'' state information may be assigned to it.


VAR
  word varGdx         'GUI control variable
  long varScreenPtr   'screen buffer pointer
  long varVgaPos      'starting position of the menu item
  byte varTextN[18]   'normal text, 15 chars MAX, with room for terminating Null and bracketing spaces
  byte varTextI[18]   'inverted text, 15 chars MAX, with room for terminating Null and bracketing spaces
  byte varRow         'top row location
  byte varCol         'left col location
  byte varCol2        'right col location
  byte varWidth       'width of text
  byte varStatus      '0=normal else user defined value
  byte varVgaCols     'width of screen in columns
  

PUB Init( pRow, pCol, pTextPtr, pVgaPtr, pVgaWidth ) | strIdx

  varVgaCols    := pVgaWidth
  varRow        := pRow
  varCol        := pCol
  varScreenPtr  := pVgaPtr
  varStatus     := 0  
  varWidth  := strsize( pTextPtr ) + 2
  varCol2   := varCol + varWidth - 1
    
  varTextN[0] := 32
  bytemove( @varTextN[1], pTextPtr, varWidth - 2 ) 'copy menu item text string
  varTextN[varWidth - 1] := 32
  varTextN[varWidth] := 0
  strIdx := 0
  'repeat varWidth
    'varTextI[strIdx] := varTextN[strIdx]+128    'invert the string
    'strIdx++
    
  varTextI[strIdx] := 0
 
  varVgaPos := varRow * varVgaCols + varCol     'now draw the menu item                                   
  bytemove( @byte[varScreenPtr][varVgaPos], @varTextN, varWidth )
  
  
PUB DrawText( pMode )

  if pMode & 1
    bytemove( @byte[varScreenPtr][varVgaPos], @varTextN, varWidth )
  else  
    bytemove( @byte[varScreenPtr][varVgaPos], @varTextN, varWidth )
 

PUB IsIn( pCx, pCy ) : qq
     
  qq := false

    if ( pCx => varCol ) AND ( pCx =< varCol2 )
      if pCy == varRow
        qq := true

  return qq


PUB SetText( pPtr ) | strIdx

  bytefill( @varTextN[1], 32, varWidth - 2 )    'clear it first
  bytemove( @varTextN[1], pPtr, strsize(pPtr) ) 'copy menu item text string
  strIdx := 0
  repeat varWidth
    varTextI[strIdx] := varTextN[strIdx]+128    'invert the string
    strIdx++ 
  bytemove( @byte[varScreenPtr][varVgaPos], varTextI, varWidth )


PUB SetStatus( pStat )
  varStatus := pStat    'user defined status value


Pub GetStatus
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