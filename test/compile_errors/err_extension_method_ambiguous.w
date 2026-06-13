//! expect-error: ambiguous extension method 'tag'

use extension_coherence.base
use extension_coherence.slug
use extension_coherence.url

fn main:
    let t = Target { value: 1 }
    let _ = t.tag()
