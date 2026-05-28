typedef struct BadObjectMacro {
    int x;
} BadObjectMacro;

#define BAD_OBJECT_MACRO (BadObjectMacro){ .x = ({ int y = 1; y; }) }
