// impl Drop for Type
type Resource = { id: i32 }

impl Drop for Resource
    fn drop(self: &Resource):
        println("dropped")

fn main -> i32:
    let r = Resource { id: 42 }
    println(r.id)
