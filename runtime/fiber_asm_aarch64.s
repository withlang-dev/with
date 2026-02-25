// Fiber context switch for aarch64 (macOS/Linux)
// Context layout (saved registers):
//   [0]  x19
//   [1]  x20
//   [2]  x21
//   [3]  x22
//   [4]  x23
//   [5]  x24
//   [6]  x25
//   [7]  x26
//   [8]  x27
//   [9]  x28
//   [10] x29 (fp)
//   [11] x30 (lr)
//   [12] sp
//   [13] d8
//   [14] d9
//   [15] d10
//   [16] d11
//   [17] d12
//   [18] d13
//   [19] d14
//   [20] d15

.globl _with_fiber_switch
.p2align 2
_with_fiber_switch:
    // x0 = pointer to current fiber context (save here)
    // x1 = pointer to target fiber context (restore from here)

    // Save callee-saved registers to current context
    stp x19, x20, [x0, #0]
    stp x21, x22, [x0, #16]
    stp x23, x24, [x0, #32]
    stp x25, x26, [x0, #48]
    stp x27, x28, [x0, #64]
    stp x29, x30, [x0, #80]
    mov x2, sp
    str x2, [x0, #96]

    // Save callee-saved FP registers
    stp d8, d9, [x0, #104]
    stp d10, d11, [x0, #120]
    stp d12, d13, [x0, #136]
    stp d14, d15, [x0, #152]

    // Restore callee-saved registers from target context
    ldp x19, x20, [x1, #0]
    ldp x21, x22, [x1, #16]
    ldp x23, x24, [x1, #32]
    ldp x25, x26, [x1, #48]
    ldp x27, x28, [x1, #64]
    ldp x29, x30, [x1, #80]
    ldr x2, [x1, #96]
    mov sp, x2

    // Restore callee-saved FP registers
    ldp d8, d9, [x1, #104]
    ldp d10, d11, [x1, #120]
    ldp d12, d13, [x1, #136]
    ldp d14, d15, [x1, #152]

    ret
