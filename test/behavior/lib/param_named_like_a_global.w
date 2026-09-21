// Imported by behav_param_shadows_another_modules_global.w, which declares a
// private top-level `let ptr`. Every parameter here is named `ptr`.
pub type Holder { v: i32 }
pub fn Holder.make(ptr: i32) -> Holder: Holder { v: ptr }
pub fn plain(ptr: i32) -> i32: ptr + 1

extend Holder:
    pub fn add(ptr: i32) -> i32: self.v + ptr

pub fn local_too -> i32:
    let ptr = 40
    ptr + 2
