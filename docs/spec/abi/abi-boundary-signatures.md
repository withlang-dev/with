# 16.3e ABI Boundary Signatures Are C-Representable

A signature at an ABI boundary — an `extern` declaration, a
`@[c_export]` function, or a `c_import`-generated binding — may use
only C-representable types. A With-managed type (`str`, `List`, `Box`,
closures, or any type containing one) in such a signature, owned or
borrowed, is a compile error; the diagnostic names the §16.3c modeled
coercion for the call-site direction and the explicit
pointer-and-length spelling for the raw direction. (D30. Call sites
remain ergonomic per §16.3c: a `str` argument auto-coerces to a modeled
`*const c_char` parameter; the prohibition governs signatures, never
call sites.)
