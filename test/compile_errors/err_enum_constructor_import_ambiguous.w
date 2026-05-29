//! expect-check-fail: ambiguous enum constructor import 'Same'

enum ImportLeft { Same | OtherLeft }
enum ImportRight { Same | OtherRight }

use ImportLeft.{Same}
use ImportRight.{Same}

fn bad_ambiguous_import:
    let _x = Same
