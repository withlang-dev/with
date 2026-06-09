// Fiber context switch for Windows x86_64 ABI.
//
// Context layout mirrors the existing fiber core:
//   0   rbx
//   8   r12
//   16  r13
//   24  r14
//   32  r15
//   40  rdi
//   48  rsi
//   80  rbp
//   88  rip
//   96  rsp
//   104 xmm6
//   120 xmm7
//   136 xmm8
//   152 xmm9
//   168 xmm10
//   184 xmm11
//   200 xmm12
//   216 xmm13
//   232 xmm14
//   248 xmm15

        .text
        .globl with_fiber_switch
        .globl with_fiber_prepare_initial_context
        .p2align 4
with_fiber_switch:
        // rcx = save context, rdx = restore context
        movq %rbx, 0(%rcx)
        movq %r12, 8(%rcx)
        movq %r13, 16(%rcx)
        movq %r14, 24(%rcx)
        movq %r15, 32(%rcx)
        movq %rdi, 40(%rcx)
        movq %rsi, 48(%rcx)
        movq %rbp, 80(%rcx)
        movdqu %xmm6, 104(%rcx)
        movdqu %xmm7, 120(%rcx)
        movdqu %xmm8, 136(%rcx)
        movdqu %xmm9, 152(%rcx)
        movdqu %xmm10, 168(%rcx)
        movdqu %xmm11, 184(%rcx)
        movdqu %xmm12, 200(%rcx)
        movdqu %xmm13, 216(%rcx)
        movdqu %xmm14, 232(%rcx)
        movdqu %xmm15, 248(%rcx)

        movq (%rsp), %rax
        movq %rax, 88(%rcx)
        leaq 8(%rsp), %rax
        movq %rax, 96(%rcx)

        movq 0(%rdx), %rbx
        movq 8(%rdx), %r12
        movq 16(%rdx), %r13
        movq 24(%rdx), %r14
        movq 32(%rdx), %r15
        movq 40(%rdx), %rdi
        movq 48(%rdx), %rsi
        movq 80(%rdx), %rbp
        movdqu 104(%rdx), %xmm6
        movdqu 120(%rdx), %xmm7
        movdqu 136(%rdx), %xmm8
        movdqu 152(%rdx), %xmm9
        movdqu 168(%rdx), %xmm10
        movdqu 184(%rdx), %xmm11
        movdqu 200(%rdx), %xmm12
        movdqu 216(%rdx), %xmm13
        movdqu 232(%rdx), %xmm14
        movdqu 248(%rdx), %xmm15

        movq 96(%rdx), %rsp
        movq 88(%rdx), %rax
        jmp *%rax

        .p2align 4
with_fiber_prepare_initial_context:
        // rcx = context pointer
        // rdx = usable stack base
        // r8  = usable stack size
        leaq (%rdx,%r8), %rax
        andq $-16, %rax
        subq $8, %rax
        movq $0, (%rax)
        movq %rax, 80(%rcx)
        leaq with_fiber_start(%rip), %r9
        movq %r9, 88(%rcx)
        movq %rax, 96(%rcx)
        ret

        .globl with_fiber_start
        .p2align 4
with_fiber_start:
        subq $56, %rsp
        leaq 32(%rsp), %rcx
        leaq 40(%rsp), %rdx
        leaq 48(%rsp), %r8
        callq with_fiber_bootstrap_load
        movq 32(%rsp), %rax
        movq 40(%rsp), %rcx
        movq 48(%rsp), %rdx
        callq *%rax
        callq with_fiber_bootstrap_finish
        ud2
