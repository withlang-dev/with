// behav_global_race_local_shadows_unseen_global fixture: a private `var`
// the program never mutates, whose name a local in the root module takes.
var counter: i32 = 7
pub fn peek_counter(): counter
