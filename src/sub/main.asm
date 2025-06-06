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
	moveq	#0,d0						; Clear communication registers
	move.b	d0,MCD_SUB_FLAG
	move.l	d0,MCD_SUB_COMM_0
	move.l	d0,MCD_SUB_COMM_4
	move.l	d0,MCD_SUB_COMM_8
	move.l	d0,MCD_SUB_COMM_12

	bclr	#0,MCD_RESET					; Reset periphery
	move.b	d0,MCD_IRQ_MASK					; Disable interrupts

.SetMode2M:
	bclr	#2,MCD_MEM_MODE					; Set Word RAM to 2M mode
	bne.s	.SetMode2M

.GiveWordRam:
	bset	#0,MCD_MEM_MODE					; Give Word RAM to Main CPU
	beq.s	.GiveWordRam

	move.w	d0,MCD_STOPWATCH				; Reset stopwatch

	lea	PRG_RAM+$5800,a0				; Clear RAM up to system program
	moveq	#0,d0
	moveq	#$800/16-1,d1

.ClearVariables:
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	dbf	d1,.ClearVariables

	bsr.w	InitPcm						; Initialize PCM
	bsr.w	SetupCallTable					; Set up call table

	ori.b	#%00010100,MCD_IRQ_MASK				; Enable Mega Drive and CDD interrupts

	lea	_USERCALL0,a0					; Set up module
	lea	PRG_RAM+$6000,a1
	bsr.w	SetupModule
	
	movem.l	.Zero(pc),d0-a6					; Clear registers
	move.l	a6,usp

; ------------------------------------------------------------------------------

.ModuleInit:
	move	#$2200,sr					; Disable IRQ1 and IRQ2
	bsr.w	_USERCALL0					; Run system program initialization
	move	#$2000,sr					; Enable IRQ1 and IRQ2
	
.ModuleLoop:
	bsr.w	VSync						; VSync

	move.w	return_code,d0					; Get previous return code
	bsr.w	_USERCALL1					; Run system program
	move.w	d0,return_code					; Set return code

	cmpi.w	#-1,d0						; Did it return -1?
	bne.s	.ModuleLoop					; If not, branch

	movem.l	.Zero(pc),d0-a6					; Clear registers
	move.l	a6,usp

	bra.s	.ModuleInit					; Re-initialize module

; ------------------------------------------------------------------------------

.Zero:
	dcb.l	8+7, 0

; ------------------------------------------------------------------------------