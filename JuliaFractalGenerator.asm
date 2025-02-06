# AUTOR: Mateusz Woźniak
# PROJEKT: FRAKTAL JULII - WYNIK W BMP	
	.eqv PRINT_STR 4
	.eqv READ_INT 5
	.eqv EXIT 10
	.eqv OPEN_FILE 1024
	.eqv WRITE 64
	.eqv READ 63
	.eqv CLOSE 57
	
	.data
msg1:	.asciz "Enter width:\n"
msg2:	.asciz "Enter height:\n"
msg3:	.asciz "Enter max iterations:\n"
error1: .asciz "Invalid max iterations!"
error3: .asciz "File not found!"
f_name:	.asciz "julia.bmp"
	.align 2
header: .space 56
	.text
main:
	li a7, PRINT_STR
	la a0, msg3
	ecall
	
	li a7, READ_INT
	ecall

	# save max iterations to s8
	mv s8, a0
	blez s8, end_error1
	
	# open file
	li a7, OPEN_FILE
	la a0, f_name
	li a1, 0
	ecall
	
	# save file descriptor
	mv s2, a0
	li t6, -1
	beq s2, t6, end_f_not_found
	
	# save header buffer address
	la t0, header
	addi t0, t0, 2
	
	# save header
	li a7, 63
	mv a1, t0
	li a2, 54
	ecall
	
	# close file
	li a7, CLOSE
	mv a0, s2
	ecall
	
	# save width to s6
	lw s6, 18(t0)
	
	# save height to s7
	lw s7, 22(t0)
	
	# save file size
	lw s0, 2(t0)
calculate_padding:
	# width in bytes stored in t3
	addi t4, t4, 3
	mul t3, s6, t4
	andi t2, t3, 3
	
	# skips padding if width modulo 4 is equal 0
	beqz t2, allocate_memory
	li  t5, 4
	
	# s9 stores number of padding bytes
	sub s9, t5, t2
allocate_memory:
	# allocates memory on heap
	li a7, 9
	mv a0, s0
	ecall
	
	# s1 stores address to allocated memory
	mv s1, a0
save_header:
	# open file
	li a7, OPEN_FILE
	la a0, f_name
	li a1, 0
	ecall
	
	# save file descriptor
	mv s2, a0
	li t6, -1
	beq s2, t6, end_f_not_found
	
	# save header to buffer
	li a7, READ
	mv a1, s1
	mv a2, s0
	ecall
	
	# close file
	li a7, CLOSE
	mv a0, s2
	ecall
fractal_preparation:
	# save address of first pixel to s5 (bottom left corner)
	# fixed point - 22/12
	mv s5, s1
	addi s5, s5, 54
	
	# x
	li t1, 0
	# y
	li t2, 0
	# c real part
	li s10, 0x000005AE
	# li s10, -0x00001000
	# c imaginary part
	li s11, 0x000005AE
	# li s11, 0x00000000
	# x adapted to complex number
	li a0, -0x00002000
	# y adapted to complex number
	li a1, -0x00002000
	# 4 in fixed point for comparison
	li a2, 0x00004000
	# width step
	li a3, 0x00004000
	div a3, a3, s6
	# height step
	li a4, 0x00004000
	div a4, a4, s7
	# padding counter
	mv t3, s9
begin_fractal:
	# reset iteration counter
	li t0, 0
	
	# set complex x
	mul a5, t1, a3
	add a5, a0, a5
	
	# set complex y
	mul a6, t2, a4
	add a6, a1, a6
	
	addi t1, t1, 1
fractal_loop:
	# increment iteration
	addi t0, t0, 1
	
	# calculate imaginary part
	mul t4, a5, a6
	slli t4, t4, 1
	srai t4, t4, 12
	
	# calculate real part
	mul t5, a5, a5
	mul t6, a6, a6
	sub t5, t5, t6
	srai t5, t5, 12
	
	# add c
	add a5, t5, s10
	add a6, t4, s11
	
	mul t4, a5, a5
	mul t5, a6, a6
	add t6, t5, t4
	srai t6, t6, 12
	
	# check conditions
	beq t0, s8, calculate_pixel_color
	blt t6, a2, fractal_loop
calculate_pixel_color:
	# ratio = iterations / max iterations
	# pixel_color = ratio * 255
	# pixel_color = 255 - pixel_color
	mv t4, s8
	mv t5, t0
	slli t5, t5, 12
	div t4, t5, t4
	li t6, 255
	slli t6, t6, 12
	mul t6, t6, t4
	srai t5, t6, 24
	li t4, 255
	sub t0, t4, t5
color_pixel:
	# coloring pixel
	sb zero, (s5)
	sb t5, 1(s5)
	sb t0, 2(s5)
	addi s5, s5, 3
	blt t1, s6, begin_fractal
padding:
	beqz s9, next_row
	sb zero, (s5)
	addi s5, s5, 1
	addi t3, t3, -1
	bnez t3, padding
next_row:
	mv t3, s9
	li t1, 0
	addi t2, t2, 1
	blt t2, s7, begin_fractal
end:
	# open file
	li a7, OPEN_FILE
	la a0, f_name
	li a1, 1
	ecall
	
	# save file descriptor to t0
	mv t0, a0
	
	# write to file
	li a7, WRITE
	mv a1, s1
	mv a2, s0
	ecall
	
	# close file
	li a7, CLOSE
	mv a0, t0
	ecall
	
	# end program
	li a7, EXIT
	ecall
end_error1:
	# end program with error message1
	li a7, PRINT_STR
	la a0, error1
	ecall
	
	li a7, EXIT
	ecall
end_f_not_found:
	# end program with error message3
	li a7, PRINT_STR
	la a0, error3
	ecall
	
	li a7, EXIT
	ecall
