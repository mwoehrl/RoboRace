;IX points to player struct
Random16Bit:
  LD HL, (RandomSeed)      ; seed must not be 0
  
  ld a,h
  rra
  ld a,l
  rra
  xor h
  ld h,a
  ld a,l
  rra
  ld a,h
  rra
  xor l
  ld l,a
  xor h
  ld h,a
  LD (RandomSeed), HL
  ret

mult_a_de      ;HL=A*DE
   ld	c, 0
   ld	h, c
   ld	l, h

   add	a, a		; optimised 1st iteration
   jr	nc, $+4
   ld	h,d
   ld	l,e

   ld b, 7
mult_loop:
   add	hl, hl
   rla
   jr	nc, $+4
   add	hl, de
   adc	a, c            ; yes this is actually adc a, 0 but since c is free we set it to zero and so we can save 1 byte and up to 3 T-states per iteration

   djnz	mult_loop
   ret

;The following routine divides d by e and places the quotient in d and the remainder in a
div_d_e:
   xor	a
   ld	b, 8
div_d_e_loop:
   sla	d
   rla
   cp	e
   jr	c, $+4
   sub	e
   inc	d
   djnz div_d_e_loop
   ret

;The following routine divides hl by c and places the quotient in hl and the remainder in a
div_hl_c:
   xor	a
   ld	b, 16
div_hl_c_loop:
   add	hl, hl
   rla
   jr	c, $+5
   cp	c
   jr	c, $+4
   sub	c
   inc	l
   djnz	div_hl_c_loop
   ret
 