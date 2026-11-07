// #2977: a library module whose async fn awaits, which the importing
// program never calls. Its body is checked; its `sleep(d)` is an async
// function call; neither makes the importer's program concurrent.
use std.time

pub async fn pause(d: Duration): sleep(d).await

pub fn plain(): 1
