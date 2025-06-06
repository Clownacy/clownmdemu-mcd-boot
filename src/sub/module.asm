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
; Set up module
; ------------------------------------------------------------------------------
; PARAMETERS:
;	a0.l - Pointer to jump table entries in RAM
;	a1.l - Pointer to module
; ------------------------------------------------------------------------------

SetupModule:
	move.l	a2,-(sp)					; Save a2

; ------------------------------------------------------------------------------

.CheckModuleType:
	lea	.ModuleTypes(pc),a2				; Module types
	
.CheckModuleTypeLoop:
	move.w	(a2)+,d1					; Get module name offset
	bmi.s	.End						; If we are done, branch

	move.l	(a2)+,d0					; Get string to compare
	cmp.l	(a1,d1.w),d0					; Is this a valid module?
	beq.s	.GotModule					; If so, branch
	
	bra.s	.CheckModuleTypeLoop				; Check the next module type

; ------------------------------------------------------------------------------

.GotModule:
	movea.l	a1,a2						; Get module start
	adda.l	$18(a2),a1
	tst.b	$B(a2)						; Does this module start with code?
	beq.s	.SetJumpTable					; If not, branch

	jsr	(a1)						; Execute code
	bcc.s	.CheckLinkedModule				; If we shouldn't set up a jump table, branch

.SetJumpTable:
	move.l	a1,d1						; Get start of jump table

.SetJumpTableLoop:
	move.w	(a1)+,d0					; Are we at the end?
	beq.s	.CheckLinkedModule				; If so, branch
	
	ext.l	d0						; Set jump table entry
	add.l	d1,d0
	move.w	#$4EF9,(a0)+
	move.l	d0,(a0)+

	bra.s	.SetJumpTableLoop				; Get the next jump table entry

; ------------------------------------------------------------------------------

.CheckLinkedModule:
	movea.l	a2,a1						; Get linked module
	move.l	$10(a1),d0
	beq.s	.End						; If there is none, branch
	
	adda.l	d0,a1						; Go to linked module
	bra.s	.CheckModuleType

.End:
	movea.l	(sp)+,a2					; Restore a2
	rts

; ------------------------------------------------------------------------------

.ModuleTypes:
	dc.w	0
	dc.b	"MAIN"
	dc.w	8
	dc.b	"SYS", 0
	dc.w	8
	dc.b	"SUB", 0
	dc.w	8
	dc.b	"DAT", 0
	dc.w	-1

; ------------------------------------------------------------------------------