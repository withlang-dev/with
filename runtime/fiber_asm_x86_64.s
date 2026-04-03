// Fiber context switch for x86_64 (macOS/Linux, SysV ABI).
//
// We reuse the FiberContext layout from fiber.c:
//   regs[10] (offset 80) = rbp
//   regs[11] (offset 88) = rip
//   regs[12] (offset 96) = rsp
//   regs[0..4]           = rbx, r12, r13, r14, r15

.text
.globl _with_fiber_switch
.globl with_fiber_switch
.globl _with_fiber_prepare_initial_context
.globl with_fiber_prepare_initial_context
.p2align 4
_with_fiber_switch:
with_fiber_switch:
    // rdi = save context, rsi = restore context

    // Save callee-saved registers.
    movq %rbx, 0(%rdi)
    movq %r12, 8(%rdi)
    movq %r13, 16(%rdi)
    movq %r14, 24(%rdi)
    movq %r15, 32(%rdi)
    movq %rbp, 80(%rdi)

    // Save resume IP and caller stack pointer.
    movq (%rsp), %rax
    movq %rax, 88(%rdi)
    leaq 8(%rsp), %rax
    movq %rax, 96(%rdi)

    // Restore callee-saved registers.
    movq 0(%rsi), %rbx
    movq 8(%rsi), %r12
    movq 16(%rsi), %r13
    movq 24(%rsi), %r14
    movq 32(%rsi), %r15
    movq 80(%rsi), %rbp

    // Switch stack and jump to target IP.
    movq 96(%rsi), %rsp
    movq 88(%rsi), %rax
    jmp *%rax

.p2align 4
_with_fiber_prepare_initial_context:
with_fiber_prepare_initial_context:
    // rdi = context pointer
    // rsi = usable stack base
    // rdx = usable stack size
    leaq (%rsi,%rdx), %rax
    andq $-16, %rax
    subq $8, %rax
    movq $0, (%rax)
    movq %rax, 80(%rdi)             // rbp
    leaq _with_fiber_start(%rip), %rcx
    movq %rcx, 88(%rdi)             // rip
    movq %rax, 96(%rdi)             // rsp
    ret

.globl _with_fiber_start
.p2align 4
_with_fiber_start:
    subq $32, %rsp
    movq %rsp, %rdi
    leaq 8(%rsp), %rsi
    leaq 16(%rsp), %rdx
    callq _with_fiber_bootstrap_load
    movq (%rsp), %rax
    movq 8(%rsp), %rdi
    movq 16(%rsp), %rsi
    callq *%rax
    callq _with_fiber_bootstrap_finish
    ud2
