# DEPS: pycparser - install via pip3

# Input) A C file with a single struct decl. We include a file, test.c where
# you can copy paste your struct or you can supply your own file as the only 
# allowed input.

# Output) Prints to terminal a formated print statement to print the contents
# of the given struct assuming some handle to the struct

import sys
from pycparser import parse_file, c_ast

STRUCT_PTR='dev'
NUM_PAD_SPACES=3

def struct_dump(filename, struct_ptr):
    ast = parse_file(filename, use_cpp=True)
    
    if len(ast.ext) > 1 or not isinstance(ast.ext[0], c_ast.Decl) or not isinstance(ast.ext[0].type, c_ast.Struct):
        print('ERROR passed C file shall contain only one struct decl')
        exit()

    # This gives us a node of type struct that is the base struct object we are parsing
    root_struct = ast.ext[0].type
    root_name = root_struct.name
    
    # These tuples will be the struct member name with the C format character
    # we wish to use when displaying this member
    name_type_tuples = []

    # Now assumuming we dont have some struct within a struct BS we can just
    # iterate over the decls array to print out each object
    max_str_len = 0
    for d in root_struct.decls:
        if not isinstance(d, c_ast.Decl):
            print('ERROR member of struct not of type Decl')
            exit()

        tuple_name = d.name
        if len(tuple_name) > max_str_len:
            max_str_len = len(tuple_name)

        # For now assume everything is a freaking %lx
        tuple_type = '%lx'

        name_type_tuples.append([tuple_name, tuple_type])

    print()
    out_str = f"printf(\"{root_name}:\\n\");"
    print(out_str)

    for t in name_type_tuples:
        tuple_name = t[0]
        tuple_name = tuple_name + ((NUM_PAD_SPACES + max_str_len - len(tuple_name))*' ')
        t[0] = tuple_name
        out_str = f"printf(\"   {t[0]}0x{t[1]}\\n\");"
        print(out_str)

if __name__ == "__main__":
    if len(sys.argv) == 1:
        struct_dump('test.c', STRUCT_PTR)
    elif len(sys.argv) == 2:
        struct_dump(sys.argv[1], STRUCT_PTR)
    else:
        print("ERROR: Usage python3 struct_dump <file=test.c>")