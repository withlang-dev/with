#ifndef BEHAV_C_IMPORT_NESTED_RECORDS_H
#define BEHAV_C_IMPORT_NESTED_RECORDS_H

/* #1396: the record shapes winnt.h/wtypes.h/wingdi.h reach once their
   untagged file-scope records import. */

/* A member record with no name held through an array or a pointer is named
   Parent_field, like one held directly (winnt.h's SCOPE_TABLE_AMD64). */
typedef struct nr_scope {
    unsigned int Count;
    struct { unsigned int Begin; unsigned int End; } ScopeRecord[1];
} nr_scope;

typedef struct nr_hold {
    struct { unsigned char tag; struct { int x; } *next; } inner;
    struct { short s; } grid[2][3];
    int n;
} nr_hold;

/* A tag declared inside a record is a file-scope type in C, and an enum's
   constants are file-scope constants (wtypes.h's __MIDL_IWinTypes_0009). */
typedef struct nr_handle {
    long ctx;
    union nr_handle_u { long in_proc; long remote; } u;
    enum { NR_KIND_A = 3, NR_KIND_B } kind;
} nr_handle;

/* Layouts With cannot spell import opaque: bitfields (a leading underscore
   is a tag like any other; winbase.h's _DCB), bitfields in a member record,
   and a field under its natural alignment (wingdi.h's #pragma pack(2)
   BITMAPFILEHEADER). */
typedef struct _nr_bits { unsigned int len; unsigned int on: 1; unsigned int off: 1; } nr_bits;
typedef struct nr_inner_bits { int n; struct { unsigned int flag: 1; } s; } nr_inner_bits;
#pragma pack(push, 2)
typedef struct nr_packed2 { unsigned short type; unsigned int size; } nr_packed2;
#pragma pack(pop)

#endif
