; ------------------------------------------------------------------------------
; Copyright (c) 2025 Devon Artmeier and Clownacy
;
; Permission to use, copy, modify, and/or distribute this software
; for any purpose with or without fee is hereby granted.
;
; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
; WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIE
; WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
; AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
; DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
; PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER 
; TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
; PERFORMANCE OF THIS SOFTWARE.
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Hard reset
; ------------------------------------------------------------------------------

HardReset:
	move.w	#$2700,sr					; Disable interrupts
	lea	stack_base,sp					; Reset stack pointer
	
	tst.l	IO_CTRL_1-1					; Has there been a soft reset?
	bne.s	SoftReset					; If so, branch
	tst.w	IO_CTRL_3-1
	bne.s	SoftReset					; If so, branch
	
	moveq	#$F,d0						; Does this console have TMSS?
	and.b	VERSION,d0
	beq.s	.NoTmss						; If not, branch
	move.l	BIOS+$100,TMSS_SEGA				; If so, satisfy TMSS

.NoTmss:
	moveq	#0,d0						; Set d0 to 0
	movea.w	d0,a0						; End of Work RAM
	
	move.w	#$8000/16-1,d1					; Clear Work RAM up to the initial program

.ClearWorkRam:
	move.l	d0,-(a0)
	move.l	d0,-(a0)
	move.l	d0,-(a0)
	move.l	d0,-(a0)
	dbf	d1,.ClearWorkRam
	
; ------------------------------------------------------------------------------
; Soft reset
; ------------------------------------------------------------------------------

SoftReset:
	move.w	#$2700,sr					; Disable interrupts
	clr.l	vblank_flags					; Clear V-BLANK handler flags

	bsr.w	WaitVdpDma					; Wait for any leftover DMA to finish
	bsr.w	SetDefaultVdpRegs				; Set the default VDP register values
	bsr.w	ClearVdp					; Clear VDP memory
	bsr.w	ClearPalette					; Clear palette
	bsr.w	ClearSprites					; Clear sprites
	bsr.w	ClearMcdCommRegs				; Clear communication registers
	bsr.w	SetupCallTable					; Set up call table in RAM
	
	moveq	#$FFFFFF9F,d0					; PSG1 silence value
	moveq	#4-1,d1						; 4 PSG channels
	
.SilencePsg:
	move.b	d0,PSG_CTRL					; Silence channel
	addi.b	#$20,d0						; Next channel
	dbf	d1,.SilencePsg					; Loop until finished
	
	bsr.w	InitZ80						; Initalize the Z80
	bsr.w	InitControllers					; Initialize the controllers

.ResetSubCpu:
	bclr	#0,MCD_RESET					; Set the Sub CPU to reset
	bne.s	.ResetSubCpu

.ReqSubCpuBus:
	bset	#1,MCD_RESET					; Request the Sub CPU's bus
	beq.s	.ReqSubCpuBus

	move.b	#0,MCD_PROTECT					; Disable write protection

	lea	SubCpuBios,a0					; Decompress Sub CPU BIOS
	lea	PRG_RAM,a1
	bsr.w	KosDec

	move.b	#$2A,MCD_PROTECT				; Enable write protection

.RunSubCpu:
	bset	#0,MCD_RESET					; Set the Sub CPU to run
	beq.s	.RunSubCpu

.GiveSubCpuBus:
	bclr	#1,MCD_RESET					; Give back the Sub CPU's bus
	bne.s	.GiveSubCpuBus

	movem.l	.Zero(pc),d0-a6					; Clear registers
	move.l	a6,usp

	jmp	WORK_RAM					; Go to the initial program

; ------------------------------------------------------------------------------

.Zero:
	dcb.l	8+7, 0

; ------------------------------------------------------------------------------