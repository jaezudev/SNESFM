;!!!!NOTES!!!!


;ROM NOTES
;#030000 [#068000] - Palette information
;#032000 [#06A000] - Tile information
;#038000 [#078000] - Tilemap information
;VAR NOTES
;$7FFFFD - Modulation Strength
;RAM Map:
;$00F0-00FE: Columns list (00 means empty)
;$00FF - Row tile number
incsrc "header.asm"
incsrc "initSNES.asm"

org $068000
incbin "palette.pal"
org $028000
incbin "tilesetUnicode.chr"
org $06FC00
incbin "sinetable.bin"
org $07A000
incbin "bg3map.map"
org $07FFFF ;set size of the file, irrelevant lmao
db $00


;========================
; Start
;========================

org $008129
    LDA #$01            ;   Enable FastROM
    STA $420D           ;__
    lda #$80            ;    Turn on screen, full brightness
    sta $2100           ;__
SPCTransfer:         ;__
    PEA $0000       ;   set dp to 00 since RAM
    PLD				;__

SPCTransferLoop00:
    LDA $2140
    CMP #$AA
    BNE SPCTransferLoop00
    LDA $2141
    CMP #$BB
    BNE SPCTransferLoop00
                    ;__
    LDX #$81E0      ;
    STX $01         ;   Base address: $81E000
    STZ $00         ;__
SPCTA:
    LDY #$0002      ;
    LDA [$00],Y     ;
    STA $2142       ;
    INY             ;   Give address to SPC
    LDA [$00],Y     ;
    STA $2143       ;__
    LDY #$0000      ;
    LDA [$00],Y     ;
    STA $04         ;
    INY             ;   Get the length, put it in $04-$05
    LDA [$00],Y     ;
    STA $05         ;__
    LDX $04         ;   If length = 0 it's a jump, therefore end transmission
    BEQ SPCTransferJump;__
    LDA #$CC
    STA $2140
    STA $2141
    INY
SPCTransferLoop01:
    LDA $2140
    CMP #$CC
    BNE SPCTransferLoop01
    LDY #$0000
    CLC
    LDA $00
    ADC #$04
    STA $00
    LDA $01
    ADC #$00
    STA $01
SPCTransferLoop02:
    LDA [$00],Y
    STA $2141
    TYA
    STA $2140
    STA $03
SPCTransferLoop03:
    LDA $2140
    CMP $03
    BNE SPCTransferLoop03
    INY
    CPY $04
    BNE SPCTransferLoop02
    TYA
    CLC
    ADC $00
    STA $00
    LDA $01
    ADC $05
    STA $01
    TYA
    INC A
    INC A
    INC A
    STA $2140
    JMP SPCTA

SPCTransferJump:
    LDA #$00
    STA $2141
    STA $2140
    LDA #$0F
    STA $60
dmaToCGRAM:
    
    PEA $4300
    PLD				;set dp to 43
    
    REP #%00010000	;set xy to 16bit
    SEP #%00100000 	;set a to 8bit
    LDA #$00		;Address to write to in CGRAM
    STA $2121		;Write it to tell Snes that
    LDA #$22		;CGRAM Write register
    STA $01			;DMA 0 B Address
    LDA #$06		;Bank of palette
    STA $04			;DMA 0 A Bank
    LDX #$8000		;Address of palette
    STX $02			;DMA 0 A Offset
    LDX #$0200		;Amount of data
    STX $05			;DMA 0 Number of bytes
    LDA #%00000000	;Settings d--uummm (Direction (0 = A to B) Update (00 = increment) Mode (000 = 1 byte, write once)
    STA $00
    LDA #%00000001	;bit 2 corresponds to channel 0
    STA $420B		;Init
dmaToVRAM1:
    STZ $0000
    STZ $0001
    JSL DecompressUnicodeBlock
    LDA #$01
    STA $0000
    STA $0001
    JSL DecompressUnicodeBlock
dmaToVRAM2:
    LDX #$7000		;Address to write to in VRAM
    STX $2116		;Write it to tell Snes that
    LDA #$18		;VRAM Write register
    STA $21			;DMA 2 B Address
    LDA #$07		;Bank of tilemap
    STA $24			;DMA 2 A Bank
    LDX #$A000		;Address of tilemap
    STX $22			;DMA 2 A Offset
    LDX #$0800		;Amount of data
    STX $25			;DMA 2 Number of bytes
    LDA #%00000001	;Settings d--uummm (Direction (0 = A to B) Update (00 = increment) Mode (001 = 2 bytes, write once)
    STA $20
    LDA #%00000100	;bit 2 corresponds to channel 0
    STA $420B		;Init
EmptyPlotData:
    LDX #$1000		;Address to write to in VRAM
    STX $2116		;Write it to tell Snes that
    LDA #$18		;VRAM Write register
    STA $11			;DMA 1 B Address
    LDA #$06		;Bank of tileset
    STA $14			;DMA 1 A Bank
    LDX #$A0C0		;Address of tiles
    STX $12			;DMA 1 A Offset
    LDX #$0200		;Amount of data
    STX $15			;DMA 1 Number of bytes
    LDA #%00001001	;Settings d--uummm (Direction (0 = A to B) Update (01 = don't) Mode (001 = 2 bytes, write once)
    STA $10
    LDA #%00001010  ;bit 2 corresponds to channel 0
    STA $420B		;Init

TurnOnScreen:
    REP #%00010000 ;set xy to 16bit
    SEP #%00100000 ;A 8-bit
    
    lda #%00000001
    sta $4200
    LDA #%00000101	; = 8/8/8/8 px tile size, mode 5
    STA $2105
    STZ $210E
    LDA #%00000011
    STA $212C
    STA $212D
    LDA #%01110010
    STA $2107
    LDA #%01111010
    STA $2108
    LDA #$03|$04      ;Interlace|Overscan
    ;LDA #$04    ;Overscan
    STA $2133
    LDA #$40
    STA $210B
    STZ $210D
    STZ $210D
    STZ $210E
    STZ $210E
    STZ $210F
    STZ $210F
    STZ $2110
    STZ $2110
    lda #$80            ; = 10000000
    sta $2100           ; F-Blank
    LDA #$00
    PEA $0000
    PLD				;set dp to 00
    JSL tableROMtoWRAM
    JSL clearPaletteData
    JSL RoutineSelect
    JSL Decompress
    SEP #%00100000 ;A 8-bit
    lda #$0F            ; = 00001111
    sta $2100           ; Turn on screen, full brightness
    lda #%10000001
    sta $4200
    STZ $2115
forever:
        jmp forever
org $008400
nmi:
    lda #$8F            ; = 10001111
    sta $2100           ; F-BLANK
    JSR DrawColumn

    ; Plot the graph
    JSL Decompress

    lda #$0F             ; = 00001111
    sta $2100           ; Turn on screen, full brightness

    ;Update the mod strength number
    LDX #$72CC
    STX $2116

    LDA $10
    AND #$F0
    LSR
    LSR
    LSR
    LSR
    ORA #$10
    STA $2118

    LDA $10
    AND #$0F
    ORA #$10
    STA $2118

    LDX #$72EC
    STX $2116

    LDA $11
    STA $2118
    LDA $12
    STA $2118
    PHA
    PHP
    REP #%00100000 ;set xy to 8bit
    SEP #%00010000 ;set a to 16bit

incsrc "controllerRoutine.asm"

REP #%00010000 ;set XY to 16bit
SEP #%00100000 ;set A to 8bit


lda #$0F            ; = 00001111
sta $2100           ; Turn on screen, full brightness

lda #%00000001
sta $4200
LDA #$00
PEA $0000
PLD				;set dp to 00
lda #$08            ; = 00000111
sta $2100           ; Turn on screen, half brightness
JSL clearPaletteData
JSL RoutineSelect
SEP #%00100000 ;A 8-bit
lda $60            ; = 00001111
sta $2100           ; Turn on screen, full or quarter brightness
lda #%10000001
sta $4200

LDA $2140
CMP #$89
BNE NMIEnd
LDA $2141
CMP #$AB
BNE NMIEnd
LDA $2142
CMP #$CD
BNE NMIEnd
LDA $2143
CMP #$EF
BNE NMIEnd
LDA #$0C
STA $60

NMIEnd:

PLP
PLA
RTI 

DrawColumn:
    PHB             ;
    PHD             ;   Back up some registers
    PHP             ;__
    PEA $2100       ;   Set Direct Page to $2100 
    PLD             ;__ because PPU registers
    REP #%00100000  ;   Set XY to 8 bit
    SEP #%00010000  ;__ Set A to 16 bit
    LDX #%10000001  ;   Increment by 32
    STX $15         ;__
    LDA #$0003      ;
    LSR A           ;   Choose BG1 or BG2 tilemap
    BCC +           ;
    ADC #$07FF      ;__
+:                  ;
    ORA #$7000      ;   Write the address
    STA $16         ;__
    LDY #$00
-:
    LDA #$0006
    CPY $00FF
    BNE +
    DEC A
+   ASL A
    STA $18
    INY
    CPY #$40
    BNE -

    PLP
    PLD
    PLB
RTS


;Mem table:
;$00 - Unicode block to use
;$01 - VRAM block to write to - 0..3
DecompressUnicodeBlock:
    PHB             ;
    PHD             ;   Back up some registers
    PHP             ;__
    PEA $0000       ;   Set Direct Page to 0
    PLD             ;__
    PEA $8282       ;
    PLB             ;   Set Data Bank to 82
    PLB             ;__
    REP #%00110000  ;__ Set XY, A to 16 bit
    LDA $00         ;
    ASL A           ;
    ASL A           ;
    ASL A           ;   Set up the source pointer
    AND #$00FF      ;
    ORA #$0080      ;
    XBA             ;
    STA $10         ;__
    LDY #$0000
    LDX #$0000
-:
    LDA ($10), Y    ;
    STA $0110, X    ;   Line 1/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $0112, X    ;   Line 2/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $0114, X    ;   Line 3/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $0116, X    ;   Line 4/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $0118, X    ;   Line 5/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $011A, X    ;   Line 6/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $011C, X    ;   Line 7/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $011E, X    ;   Line 8/8 of tile
    INY             ;
    INY             ;__
    TXA             ;
    CLC             ;
    ADC #$0020      ;   Update tile pointer
    TAX             ;
    CMP #$1000      ;__
    BNE -
;DMA TRANSFER 0: 2BPP
    PEA $4300       ;
    PLD				;set dp to 43
    SEP #%00100000 	;set a to 8bit
    LDA $0001
    ASL A
    ASL A    
    ASL A
    AND #$18
    ORA #$40
    STA $0013
    STZ $0012
    LDX $0012		;Address to write to in VRAM
    STX $2116		;Write it to tell Snes that
    LDA #$18		;VRAM Write register
    STA $11			;DMA 1 B Address
    LDX #$7E01		;Address of tileset
    STX $13			;DMA 1 A Bank
    STZ $12
    LDX #$1000		;Amount of data
    STX $15			;DMA 1 Number of bytes
    LDA #%00000001	;Settings d--uummm (Direction (0 = A to B) Update (00 = increment) Mode (001 = 2 bytes, write once)
    STA $10
    LDA #%00000010	;bit 1 corresponds to channel 1
    STA $420B		;Init
    PEA $0000       ;   Set Direct Page to 0
    PLD             ;__
; 4bpp
.4bpp:
    STZ $001F
    REP #%00110000  ;__ Set XY, A to 16 bit
    LDX #$0000
-:
    STZ $0100, X
    INX
    CPX #$1000
    BNE -
    LDA $00         ;
    ASL A           ;
    ASL A           ;
    ASL A           ;   Set up the source pointer
    AND #$00FF      ;
    ORA #$0080      ;
    XBA             ;
    STA $10         ;__
    LDY #$0000
    LDX #$0000
-:
    LDA ($10), Y    ;
    STA $0100, X    ;   Line 1/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $0102, X    ;   Line 2/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $0104, X    ;   Line 3/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $0106, X    ;   Line 4/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $0108, X    ;   Line 5/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $010A, X    ;   Line 6/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $010C, X    ;   Line 7/8 of tile
    INY             ;
    INY             ;__
    LDA ($10), Y    ;
    STA $010E, X    ;   Line 8/8 of tile
    INY             ;
    INY             ;__
    TXA             ;
    CLC             ;
    ADC #$0040      ;   Update tile pointer
    TAX             ;
    CMP #$1000      ;__
    BNE -
    PHY
;DMA TRANSFER 1/2: 4BPP
    PEA $4300       ;
    PLD				;set dp to 43
    SEP #%00100000 	;set a to 8bit
    LDA $0001
    ASL A
    ORA $001F
    ASL A    
    ASL A
    ASL A
    AND #$38
    STA $0013
    STZ $0012
    LDX $0012		;Address to write to in VRAM
    STX $2116		;Write it to tell Snes that
    LDA #$18		;VRAM Write register
    STA $11			;DMA 1 B Address
    LDX #$7E01		;Address of tileset
    STX $13			;DMA 1 A Bank
    STZ $12
    LDX #$1000		;Amount of data
    STX $15			;DMA 1 Number of bytes
    LDA #%00000001	;Settings d--uummm (Direction (0 = A to B) Update (00 = increment) Mode (001 = 2 bytes, write once)
    STA $10
    LDA #%00000010	;bit 1 corresponds to channel 1
    STA $420B		;Init

    INC $001F
    LDA $001F
    BIT #$01
    BEQ +
    PEA $0000       ;   Set Direct Page to 0
    PLD             ;__
    REP #%00110000  ;__ Set XY, A to 16 bit
    PLY
    LDX #$0000
    JMP -
+:
    PEA $0000       ;   Set Direct Page to 0
    PLD             ;__
    REP #%00110000  ;__ Set XY, A to 16 bit
    LDX #$0000      ;
    --:             ;
    STZ $0100, X    ;   Clear the graphics buffer
    INX             ;
    CPX #$1000      ;
    BNE --          ;__
    PLY
    PLP
    PLD
    PLB
RTS

DecompressUnicodeBlock4bpp:
    PHD
    PHP
    PEA $4300
    PLD				;set dp to 43
    
    REP #%00010000	;set xy to 16bit
    SEP #%00100000 	;set a to 8bit
    LDA $0001
    ASL A
    ASL A    
    ASL A
    ASL A
    STA $0002
    STZ $0001
    LDY $0001		;Address to write to in VRAM
    LDA #%10001111
    STA $2115
    LDA #$18		;VRAM Write register
    STA $11			;DMA 1 B Address
    LDA #$02		;Bank of tileset
    STA $14			;DMA 1 A Bank
    LDA $0000
    ASL A
    ASL A
    ASL A
    ORA #$80
    STA $13			;DMA 1 A Offset
    STZ $12
    LDA #%00000001	;Settings d--uummm (Direction (0 = A to B) Update (00 = increment) Mode (001 = 2 bytes, write once)
    STA $10
-:
    LDX #$0020		;Amount of data
    STX $15			;DMA 1 Number of bytes
    LDA #%00000010	;bit 2 corresponds to channel 0
    STA $420B		;Init
    INY
    INY
    INY
    INY
    TYA
    CMP #$80
    BNE -

    LDA #%10000000
    STA $2115
    PLP
    PLD
RTS
org $018000 ;The plotting engine for now
;1bpp to 2bpp converter

tableROMtoWRAM:		
	PEA $4300
    PLD				;set dp to 43

	LDA #$01        ;WRAM Bank
	STA $2183
    LDX #$0800		;Address to write to in WRAM
    STX $2181		;Write it to tell Snes that
    LDA #$80		;WRAM Write register
    STA $01			;DMA 1 B Address
    LDA #$06		;Bank of tileset
    STA $04			;DMA 1 A Bank
    LDX #$FC00		;Address of tiles
    STX $02			;DMA 1 A Offset
    LDX #$0400		;Amount of data
    STX $05			;DMA 1 Number of bytes
    LDA #%00000000	;Settings d--uummm (Direction (0 = A to B) Update (00 = Increment) Mode (000 = 1 byte, write once)
    STA $00
	LDA #%00000001  ;bit 2 corresponds to channel 0
    STA $420B		;Init
tableROMtoWRAM2:		
    ;JMP clearPaletteData
	LDA #$01        ;WRAM Bank
	STA $2183
    LDX #$0C00		;Address to write to in WRAM
    STX $2181		;Write it to tell Snes that
    LDA #$80		;WRAM Write register
    STA $01			;DMA 1 B Address
    LDA #$06		;Bank of tileset
    STA $04			;DMA 1 A Bank
    LDX #$FC00		;Address of tiles
    STX $02			;DMA 1 A Offset
    LDX #$0400		;Amount of data
    STX $05			;DMA 1 Number of bytes
    LDA #%00000000	;Settings d--uummm (Direction (0 = A to B) Update (00 = Increment) Mode (000 = 1 byte, write once)
    STA $00
	LDA #%00000001  ;bit 2 corresponds to channel 0
    STA $420B		;Init
    RTL
clearPaletteData:		
    PEA $4300
    PLD				;set dp to 43
	LDA #$01        ;WRAM Bank
	STA $2183
    LDX #$FE00		;Address to write to in WRAM
    STX $2181		;Write it to tell Snes that
    LDA #$80		;WRAM Write register
    STA $01			;DMA 1 B Address
    LDA #$01		;Bank of tileset
    STA $04			;DMA 1 A Bank
    LDX #$FFFF		;Address of tiles
    STX $02			;DMA 1 A Offset
    LDX #$0200		;Amount of data
    STX $05			;DMA 1 Number of bytes
    LDA #%00001000	;Settings d--uummm (Direction (0 = A to B) Update (01 = don't) Mode (010 = 2 bytes, write twice)
    STA $00
    LDA #%00000001  ;bit 2 corresponds to channel 0
    STA $420B		;Init
    RTL
Decompress:
    REP #%00010000 ;set xy to 16bit
    SEP #%00100000 ;set a to 8bit
    PEA $0000
    PLD				;set db to 7f
    LDA #$7F
    PHA
    PLB
    LDX #$00FF
    LDY #$003F
DecompressLoop:
    LDA $0000, X
    EOR #$80
    STA $FDC0, Y
    STX $00
    LDA $00
    SEC
    SBC #$04
    STA $00
    LDA $01
    SBC #$00
    STA $01
    LDX $00
    DEY
    BPL DecompressLoop
Plot:
    REP #%00110000 ;set xy and a to 16bit
    LDA #$01C0
    LDY #$0000
PlotLoop:
    TAX
    SEP #%00100000 ;set a to 8bit
	LDA #$FF
    STA $FE01,X
    STA $FE03,X
    STA $FE05,X
    STA $FE07,X
    STA $FE09,X
    STA $FE0B,X
    STA $FE0D,X
    STA $FE0F,X
    STA $FE11,X
    STA $FE13,X
    STA $FE15,X
    STA $FE17,X
    STA $FE19,X
    STA $FE1B,X
    STA $FE1D,X
    STA $FE1F,X
    STA $FE21,X
    STA $FE23,X
    STA $FE25,X
    STA $FE27,X
    STA $FE29,X
    STA $FE2B,X
    STA $FE2D,X
    STA $FE2F,X
    STA $FE31,X
    STA $FE33,X
    STA $FE35,X
    STA $FE37,X
    STA $FE39,X
    STA $FE3B,X
    STA $FE3D,X
    STA $FE3F,X
    REP #%00110000 ;set xy and a to 16bit
    TXA         ;\
    LSR A       ; |
    LSR A       ; | Get the index of the 
    LSR A       ; | entry in the input table
    ADC #$0007  ; |
    TAY         ;/
; bit 7
    LDA $FDC0, Y
    LSR A
    LSR A
    AND #%0000000000111110
    EOR #%0000000000111110
    STX $0000
    ORA $0000
    PHY
    TAY

    LDA #$FF01
    ORA $FE00, Y
    STA $FE00, Y
; bit 6
    PLY
    DEY
    LDA $FDC0, Y
    LSR A
    LSR A
    AND #%0000000000111110
    EOR #%0000000000111110
    STX $0000
    ORA $0000
    PHY
    TAY

    LDA #$FF02
    ORA $FE00, Y
    STA $FE00, Y
; bit 5
    PLY
    DEY
    LDA $FDC0, Y
    LSR A
    LSR A
    AND #%0000000000111110
    EOR #%0000000000111110
    STX $0000
    ORA $0000
    PHY
    TAY

    LDA #$FF04
    ORA $FE00, Y
    STA $FE00, Y
; bit 4
    PLY
    DEY
    LDA $FDC0, Y
    LSR A
    LSR A
    AND #%0000000000111110
    EOR #%0000000000111110
    STX $0000
    ORA $0000
    PHY
    TAY

    LDA #$FF08
    ORA $FE00, Y
    STA $FE00, Y
; bit 3
    PLY
    DEY
    LDA $FDC0, Y
    LSR A
    LSR A
    AND #%0000000000111110
    EOR #%0000000000111110
    STX $0000
    ORA $0000
    PHY
    TAY

    LDA #$FF10
    ORA $FE00, Y
    STA $FE00, Y
; bit 2
    PLY
    DEY
    LDA $FDC0, Y
    LSR A
    LSR A
    AND #%0000000000111110
    EOR #%0000000000111110
    STX $0000
    ORA $0000
    PHY
    TAY

    LDA #$FF20
    ORA $FE00, Y
    STA $FE00, Y
; bit 1
    PLY
    DEY
    LDA $FDC0, Y
    LSR A
    LSR A
    AND #%0000000000111110
    EOR #%0000000000111110
    STX $0000
    ORA $0000
    PHY
    TAY

    LDA #$FF40
    ORA $FE00, Y
    STA $FE00, Y
; bit 0
    PLY
    DEY
    LDA $FDC0, Y
    LSR A
    LSR A
    AND #%0000000000111110
    EOR #%0000000000111110
    STX $0000
    ORA $0000
    TAY

    LDA #$FF80
    ORA $FE00, Y
    STA $FE00, Y
;final
    TXA
    SEC
    SBC #$0040
    BMI Afterloop
    JML PlotLoop
Afterloop:
    REP #%00010000 ;set xy to 16bit
    SEP #%00100000 ;set a to 8bit
    PEA $4300
    PLD	;set dp to 43
    LDA #$00
    PHA
	PLB
WRAMtoVRAM:
	lda #$80            ; = 10000000
    sta $2100           ; F-Blank
    LDX #$1000		;Address to write to in VRAM
    STX $2116		;Write it to tell Snes that
    LDA #$18		;VRAM Write register
    STA $01			;DMA 1 B Address
    LDA #$7F		;Bank of tileset
    STA $04			;DMA 1 A Bank
    LDX #$FE00		;Address of tiles
    STX $02			;DMA 1 A Offset
    LDX #$0200		;Amount of data
    STX $05			;DMA 1 Number of bytes
    LDA #%00000001	;Settings d--uummm (Direction (0 = A to B) Update (00 = Increment) Mode (001 = 2 bytes, write once)
    STA $00
    LDA #%00000001  ;bit 2 corresponds to channel 0
    STA $420B		;Init
    PEA $0000
    PLD				;set dp to 00
	lda #$0F            ; = 00001111
    sta $2100           ; Turn on screen, full brightness
RTL

RoutineSelect:
    ;Input: Carrier wavetable at $7F0800, $0400 bytes long
    ;Input: Modulator wavetable at $7F0C00, $0400 bytes long
    ;Output: Modulated Wavetable at $7F0000, $0400 bytes long
    SEP #%00100000 ;set a to 8bit
    LDA $0020
    STA $7FFFFD
    PEA $2100
    PLD				;set db to 7f
    LDA #$7F
    PHA
    PLB
    LDY #$00FE
    LDA $FFFD
    SEC
    SBC #$80
    BPL PhaseModulation10
PhaseModulation20:
    LDA #$3C
    STA $000011
    LDA #$3A
    STA $000012
    REP #%00110000 ;set a to 16bit
PhaseModulation20Loop:
    ;SLOW AS CRAP, needs fixing
    TYA             ;2
    ASL             ;2
    ASL             ;2
    TAX             ;2
    SEP #$20        ;3
    LDA $0C00, X    ;5
    STA $1B         ;3
    LDA $0C01, X    ;5 _ 16
    STA $1B         ;3
    LDA $FFFD       ;4, Mod strength
    STA $1C         ;3
    REP #$20        ;3
    LDA $35         ;3
    LSR             ;2
    LSR             ;2
    LSR             ;2 _ 23

    STX $FFFE       ;5
    ADC $FFFE       ;5
    AND #$03FE      ;3
    TAX             ;2 _ 15
    ADC #$0C00
    STA $0100, Y
    LDA $0800, X    ;6
    STA $0000, Y    ;5
    DEY             ;2
    DEY             ;2 _ 15
    CPY #$0000
    BPL PhaseModulation20Loop ;2
    JML PhaseModulationFinish

PhaseModulation10:
    SEC
    SBC #$40
    BPL PhaseModulation08
    LDA $FFFD
    SEC
    SBC #$40
    STA $FFFD
    LDA #$3B
    STA $000011
    LDA #$3A
    STA $000012
    REP #%00110000 ;set a to 16bit
PhaseModulation10Loop:
    ;SLOW AS CRAP, needs fixing
    TYA             ;2
    ASL             ;2
    ASL             ;2
    TAX             ;2
    SEP #$20        ;3
    LDA $0C00, X    ;5
    STA $1B         ;3
    LDA $0C01, X    ;5 _ 16
    STA $1B         ;3
    LDA $FFFD       ;4, Mod strength
    STA $1C         ;3
    REP #$20        ;3
    LDA $35         ;3
    LSR             ;2
    LSR             ;2 _ 21

    STX $FFFE       ;5
    ADC $FFFE       ;5
    AND #$03FE      ;3
    TAX             ;2 _ 15
    LDA $0800, X    ;6
    STA $0000, Y    ;5
    DEY             ;2
    DEY             ;2 _ 15
    CPY #$0000
    BPL PhaseModulation10Loop ;2
    JMP PhaseModulationFinish

PhaseModulation08:
    LDA $FFFD
    SEC
    SBC #$80
    STA $FFFD
    LDA #$3A
    STA $000011
    LDA #$3E
    STA $000012
    REP #%00110000 ;set a to 16bit
PhaseModulation08Loop:
    ;SLOW AS CRAP, needs fixing
    TYA             ;2
    ASL             ;2
    ASL             ;2
    TAX             ;2
    SEP #$20        ;3
    LDA $0C00, X    ;5
    STA $1B         ;3
    LDA $0C01, X    ;5 _ 16
    STA $1B         ;3
    LDA $FFFD       ;4, Mod strength
    STA $1C         ;3
    REP #$20        ;3
    LDA $35         ;3
    LSR             ;2 _ 23

    STX $FFFE       ;5
    ADC $FFFE       ;5
    AND #$03FE      ;3
    TAX             ;2 _ 15
    LDA $0800, X    ;6
    STA $0000, Y    ;5
    DEY             ;2
    DEY             ;2 _ 15
    CPY #$0000
    BPL PhaseModulation08Loop ;2

PhaseModulationFinish:
    SEP #%00100000 ;set a to 8bit
    LDA $FFFD
    STA $000010
    STZ $FFFD
    PEA $0000
    PLD				;set db to 00
    LDA #$00
    PHA
    PLB
    RTL

org $01E000
arch spc700-inline
incsrc "SNESFM.asm"