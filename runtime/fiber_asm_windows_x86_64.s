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
