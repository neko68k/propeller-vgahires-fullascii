'' ===========================================================================
''  VGA High-Res Text UI Elements Base UI Support Functions  v1.2
''
''  File: InputField.spin
''  Author: Allen Marincak
''  Copyright (c) 2009 Allen MArincak
''  See end of file for terms of use
'' ===========================================================================
''
''============================================================================
'' Simple Keyboard Input Handler
''============================================================================
''
'' Creates a simple one line input field. The input field manages characters
'' from the keyboard. The contol was designed for simple commands or value
'' entry. The only editing is via the backspace key. The enter key signals
'' completion and it is up to the calling application to do as required with
'' the input.


OBJ
  SBOX          : "SimpleBox"


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
  byte varStatus      '0 = unselected   1 =  selected
  byte varColIdx      'index to current col to be written
  byte varCursorCol   'column the text cursor is in  
  byte varVgaCols     'width of screen in columns


PUB Init ( pRow, pCol, pWidth, pType, pTitlePtr, pVgaPtr, pVgaWidth ) | vgaIdx

  varVgaCols    := pVgaWidth
  varRow        := pRow
  varCol        := pCol
  varWidth      := pWidth
  varTitleWidth := strsize( pTitlePtr )
  varColIdx     := 0
  varScreenPtr  := pVgaPtr
  varCol2       := varCol + varWidth
  varCxPtr      := 0
  varCursorCol  := varCol + varTitleWidth + varColIdx + 2
  
  SBOX.DrawBox( pRow, pCol, pWidth, 3, 0, pVgaPtr, pVgaWidth )

  vgaIdx := varRow * varVgaCols + varCol

  if pType == 1
    byte[varScreenPtr][vgaIdx] := 204            'left 'tee' char
    byte[varScreenPtr][vgaIdx+pWidth-1] := 185   'right 'tee' char

  vgaIdx += varTitleWidth + 1
  
  byte[varScreenPtr][vgaIdx] := 203              'top 'tee' char
  vgaIdx += varVgaCols
  byte[varScreenPtr][vgaIdx] := 186              'vertical line char
  vgaIdx += varVgaCols
  byte[varScreenPtr][vgaIdx] := 202              'bottom 'tee' char

  vgaIdx -= ( varVgaCols + varTitleWidth )
  bytemove( @byte[varScreenPtr][vgaIdx], pTitlePtr, varTitleWidth )

  varVgaPos := (varRow+1)*varVgaCols+varCol+2+varTitleWidth 'save input area start
  

PUB Handler( pKeyCode ) | retVal, vgaIdx
'Handles key codes for a basic one line input field intended for simple data
'or commands (it is not a text editor :-)). The control uses the screen as a
'buffer so no extra memory is required to pass back the data to the caller.
'When the user presses enter a return value is bitfield encoded containing
'the address and size of the text entered. The caller then must get or use the
'data entered and then call the CLEAR method to reset the input field.
'
' returns 0       = ok, no action required
'         1       = not selected
'         MSB set = enter pressed, caller to read string and clear field
'                   Returned word is bitfield encoded to return the address
'                   and size of the string entered. Encoded as follows:
'                       %100a_aaaa_aaaa_aaaa_0000_0000_ssss_ssss
'                          a = 13bit address  s = 8 bit size
'
  retVal := 0  
  vgaIdx := varVgaPos + varColIdx

  if varStatus == 0
    retVal := 1
  else
    case pKeyCode
      $20 .. $7E:                               'standard ASCII characters
        if varColIdx < varWidth - 3 - varTitleWidth
          byte[varScreenPtr][vgaIdx] := pKeyCode
          varColIdx++
          varCursorCol++
          byte[varCxPtr][0] := varCursorCol     'move text cursor
          
      $0D:                                      'carriage return
        retval := $80000000                     ' set MSB
     
      $C8:                                      'backspace
        if ( varColIdx )
          vgaIdx--
          varColIdx--
          varCursorCol--
          byte[varScreenPtr][vgaIdx] := " "
          byte[varCxPtr][0] := varCursorCol     'move text cursor
          
  return retVal


PUB IsIn( pCx, pCy ) | retVal

  retVal := false

    if ( pCx => varCol ) AND ( pCx =< varCol2 )
      if pCy == varRow + 1 
        retVal := true

  return retVal


PUB clear
  bytefill( @byte[varScreenPtr][varVgaPos], 32, varWidth - varTitleWidth - 3 )
  varColIdx := 0
  varCursorCol := varCol + varTitleWidth + varColIdx + 2 
  byte[varCxPtr][0] := varCursorCol     'move text cursor


PUB Select( pSel, pCxPtr, pCyPtr )

  if pSel <> -1
    varStatus := pSel
  else
    if varStatus == 0
      varStatus := 1
    else
      varStatus := 0

  if varStatus == 1
    varCxPtr := pCxPtr
    byte[varCxPtr][0] := varCursorCol
    byte[pCyPtr][0] := varRow + 1


PUB GetStringCode | retval

  retval := varVgaPos << 16             ' encode address
  retval |= $80000000                   ' set MSB
  retval += varColIdx                   ' set size

  return retval


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