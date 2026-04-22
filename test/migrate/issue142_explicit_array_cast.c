typedef unsigned int uint32_t;
typedef unsigned char uint8_t;

uint8_t issue142_explicit_array_cast(void) {
    uint32_t workspace[4];
    uint8_t *bytes = (uint8_t *)workspace;
    bytes[0] = 7;
    return bytes[0];
}
