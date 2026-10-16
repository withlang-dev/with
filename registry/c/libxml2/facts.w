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
    resource XmlNode wraps *mut _xmlNode
        drop xmlFreeNode    // tree.c 3409-3417, xmlFreeNode: "Free a node including all the children"; xmlFreeNodeList (3322-3327) frees "a node list", the whole sibling chain
    fn xmlReadFile
        nullable param 1    // parser.c 13440, xmlReadFile: "@param encoding  the document encoding (optional)"
    fn xmlReadMemory
        nullable param 2    // parser.c 13483, xmlReadMemory: "@param url  base URL (optional)"
        nullable param 3    // parser.c 13484, xmlReadMemory: "@param encoding  the document encoding (optional)"
    fn xmlGetProp
        text param 1    // tree.c 6122-6160, xmlGetPropNodeInternal: `name` is compared with xmlStrEqual and looked up in the DTD hash, never stored
        text return, owned, freed by xmlFree    // tree.c 6403-6407, xmlGetProp: "Entities are substituted. The returned value must be freed by the caller"; the value is xmlNodeGetContent's (6252-6262), freed by xmlFree
    fn xmlNodeGetContent
        text return, owned, freed by xmlFree    // tree.c 5242-5256, xmlNodeGetContent: "It's up to the caller to free the result with #xmlFree … @returns a new string or NULL"
