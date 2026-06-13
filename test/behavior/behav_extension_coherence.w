//! expect-stdout: ok

use extension_coherence.base
use extension_coherence.slug
use extension_coherence.url

fn main:
    let t = Target { value: 7 }
    assert(t.label() == "base")
    assert(slug.tag(t) == "slug")
    assert(url.tag(t) == "url")
    print("ok")
