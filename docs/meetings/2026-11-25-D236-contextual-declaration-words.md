# D236 — §29.11's words for the ten contextual declaration words and the unreserved `spawn` (delegated)

**Laws:** 1 (what the program has already determined is not written again: the word's position determines whether it is a keyword).

**Date:** 2026-11-25. **Status:** delegated (D98): the choice is Eric's ruling of the same day (D235, #3132: the ten become contextual, `spawn` is dropped, `type` stays reserved); the normative words and the positional rule for each word are the agent's, on a prediction of 75%. Eric vetoes by revert.

**Context.** A C field or function named `union`, `module`, `where` and the like was imported with a trailing underscore, and no With binding, field or method could use the word (`List.extend` could not be declared). #3132's audit showed each of the ten is read by the parser in one position only.

**Decision.** Each word is a keyword only where its construct can begin: `gen` before `fn` or a word that modifies one; `where` and `dyn` before a name; `extend` before a name, or before type parameters and a name; `global` before a name or `var`; `module` at the start of a line before a name; `opaque`, `union` and `ephemeral` in a `type` or `enum` declaration after the type's name, its type parameters or its `=`; `c_import` between `use` and `(`. Elsewhere each is an identifier. `spawn` is not reserved.

**Why it is safe to decide by position.** Two names side by side are never an expression, so no program in which the word was a keyword reads differently, and a program that used it as a name was refused before.

**Implementation.** One pass after tokenizing (`lexer_contextual_words`): the parser sees a keyword token only where the word is one. Test: `behav_3132_declaration_words_are_names`.

**Not decided here.** Importing a C field named `type` under its own name in field position (Eric's note on #3132) is separate work.
