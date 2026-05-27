// Fiber context switch for Linux x86_64 SysV ABI.

.text
.globl with_fiber_switch
.globl with_fiber_prepare_initial_context
.p2align 4
with_fiber_switch:
    // rdi = save context, rsi = restore context
    movq %rbx, 0(%rdi)
    movq %r12, 8(%rdi)
    movq %r13, 16(%rdi)
    movq %r14, 24(%rdi)
    movq %r15, 32(%rdi)
    movq %rbp, 80(%rdi)

    movq (%rsp), %rax
    movq %rax, 88(%rdi)
    leaq 8(%rsp), %rax
    movq %rax, 96(%rdi)

    movq 0(%rsi), %rbx
    movq 8(%rsi), %r12
    movq 16(%rsi), %r13
    movq 24(%rsi), %r14
    movq 32(%rsi), %r15
    movq 80(%rsi), %rbp

    movq 96(%rsi), %rsp
    movq 88(%rsi), %rax
    jmp *%rax

.p2align 4
with_fiber_prepare_initial_context:
    // rdi = context pointer
    // rsi = usable stack base
    // rdx = usable stack size
    leaq (%rsi,%rdx), %rax
    andq $-16, %rax
    subq $8, %rax
    movq $0, (%rax)
    movq %rax, 80(%rdi)
    leaq with_fiber_start(%rip), %rcx
    movq %rcx, 88(%rdi)
    movq %rax, 96(%rdi)
    ret

.globl with_fiber_start
.p2align 4
with_fiber_start:
    subq $32, %rsp
    movq %rsp, %rdi
    leaq 8(%rsp), %rsi
    leaq 16(%rsp), %rdx
    callq with_fiber_bootstrap_load
    movq (%rsp), %rax
    movq 8(%rsp), %rdi
    movq 16(%rsp), %rsi
    callq *%rax
    callq with_fiber_bootstrap_finish
    ud2
