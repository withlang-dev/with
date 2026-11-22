// libxml2 2.15.4 (conan-center-index recipes/libxml2). The proof engine
// proves the tree walks (xmlDocGetRootElement, xmlFirstElementChild,
// xmlNextElementSibling return a part of their parameter) and the
// destroyers; what it cannot reach is below, each fact with its line.
//
// The allocator is a function pointer the program may set (xmlFree,
// xmlMalloc, xmlMemStrdup: globals.c), so a parameter that reaches one is
// not proven unretained, and a document built by the parser through its
// context is not proven fresh: the library's own documentation states both.
c facade libxml2:
    text utf8    // xmlstring.h 25-29, xmlChar: "This is a basic byte in an UTF-8 encoded string"; every xmlChar * the library hands back is UTF-8
    resource XmlDoc wraps *mut _xmlDoc
        from xmlReadFile    // parser.c 13425-13444, xmlReadFile: "Convenience function to parse an XML file … @returns the resulting document tree"; the filename is copied (parserInternals.c 1858, xmlNewInputInternal: input->filename = xmlMemStrdup(filename))
        from xmlReadMemory    // parser.c 13475-13488, xmlReadMemory: "@returns the resulting document tree"; the buffer is read during the call (XML_INPUT_BUF_STATIC is not set)
        drop xmlFreeDoc    // tree.c 917-923, xmlFreeDoc: "Free a document including all children and associated DTDs."
    resource XmlNode wraps *mut _xmlNode
        drop xmlFreeNode    // tree.c 3409-3417, xmlFreeNode: "Free a node including all the children"; xmlFreeNodeList (3322-3327) frees "a node list", the whole sibling chain
    fn xmlReadFile
        nullable param 1    // parser.c 13440, xmlReadFile: "@param encoding  the document encoding (optional)"
    fn xmlReadMemory
        nullable param 2    // parser.c 13483, xmlReadMemory: "@param url  base URL (optional)"
        nullable param 3    // parser.c 13484, xmlReadMemory: "@param encoding  the document encoding (optional)"
    fn xmlGetProp
        text param 1    // tree.c 6122-6160, xmlGetPropNodeInternal: `name` is compared with xmlStrEqual and looked up in the DTD hash, never stored
        lend    // tree.c 6394-6401, xmlGetProp: the node is `const`; it is looked up with xmlHasProp and its value copied by xmlGetPropNodeValueInternal (6252-6262) into the string returned; nothing is stored in the node or kept of it, and nothing of it is freed
        text return, owned, freed by xmlFree    // tree.c 6403-6407, xmlGetProp: "Entities are substituted. The returned value must be freed by the caller"; the value is xmlNodeGetContent's (6252-6262), freed by xmlFree. The hook: xmlmemory.h 102-105, "The variable holding the libxml free() implementation", XMLPUBVAR xmlFreeFunc xmlFree; globals.c 208, xmlFreeFunc xmlFree = free. Assigned only at xmlmemory.c 462 (xmlMemSetup) and 521 (xmlGcMemSetup), both raw. threads.c 504-517, xmlDestructor, reads it at process exit (`if (xmlFree == free)`) and does not write it
    fn xmlNodeGetContent
        lend    // tree.c 5243-5257, xmlNodeGetContent: "Returns the string value of a node", "@param cur  the node being read", "@returns a new string"; the node is `const` and only read
        text return, owned, freed by xmlFree    // tree.c 5242-5256, xmlNodeGetContent: "It's up to the caller to free the result with #xmlFree … @returns a new string or NULL". The hook xmlFree and its assignments: as cited on xmlGetProp above
    fn xmlDocGetRootElement
        returns borrow XmlNode from param 0    // tree.c 4664-4685, xmlDocGetRootElement: "Searches the document's children for the root element", "@returns the root element or NULL if no element was found"; the body returns a node of doc->children
    fn xmlFirstElementChild
        returns borrow XmlNode from param 0    // tree.c 3187-3218, xmlFirstElementChild: "Find the first child node which is an element", "@returns the first element or NULL if parent has no children"; the body returns a node of parent->children
    fn xmlNextElementSibling
        returns borrow XmlNode from param 0    // tree.c 3287-3320, xmlNextElementSibling: "Find the closest following sibling which is a element", "@returns the sibling or NULL if no sibling was found"; the body returns a node reached through node->next, in the tree `node` is part of
    fn xmlChildElementCount
        lend    // tree.c 3152-3185, xmlChildElementCount: "Count the number of child nodes which are elements"; the body reads parent->children and each node's type and next, and stores nothing
