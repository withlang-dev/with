typedef unsigned int uint32_t;

struct CB {
    uint32_t *parsed_pattern;
    uint32_t *groupinfo;
};

int issue144_array_decay_compare(void) {
    struct CB cb;
    uint32_t stack_groupinfo[256];
    uint32_t stack_parsed_pattern[1024];

    cb.groupinfo = stack_groupinfo;
    cb.parsed_pattern = stack_parsed_pattern;

    return (cb.parsed_pattern != stack_parsed_pattern) ||
           (cb.groupinfo != stack_groupinfo);
}

int issue144_array_decay_compare_reversed(void) {
    uint32_t mirror_array[4];
    uint32_t *mirror_ptr = mirror_array;

    return mirror_array != mirror_ptr;
}

int issue144_array_decay_compare_arrays(void) {
    uint32_t lhs_array[4];
    uint32_t rhs_array[4];

    return lhs_array != rhs_array;
}
