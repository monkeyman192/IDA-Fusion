# Example script for how to call the IDA-Fusion plugin from python.
# The plugin must be placed in one of the usual plugin directories for this
# script to find it.

import ctypes
import os.path as op
import sys

import idaapi

plugin_dirs: list[str] = idaapi.get_ida_subdirs("plugins")

if sys.platform == "win32":
    PLUGIN_NAME = "fusion64.dll"
elif sys.platform == "darwin":
    PLUGIN_NAME = "fusion64.dynlib"
else:
    PLUGIN_NAME = "fusion64.so"

dll = None

for dir_ in plugin_dirs:
    plugin_path = op.join(dir_, PLUGIN_NAME)
    try:
        dll = ctypes.CDLL(plugin_path)
    except FileNotFoundError:
        continue

if not dll:
    print(
        "Cannot find IDA-Fusion dll. Please ensure it's at least in one of the "
        f"following locations: {plugin_dirs}"
    )
    sys.exit(1)

dll.plugin_run_ex.restype = ctypes.c_void_p
dll.plugin_run_ex.argtypes = [ctypes.c_uint64, ctypes.c_uint32]

dll.free_signature.restype = None
dll.free_signature.argtypes = [ctypes.c_void_p]


def get_signature(addr):
    iaddr = ctypes.c_uint64(addr)
    res = dll.plugin_run_ex(iaddr, ctypes.c_uint32(1))
    val = ctypes.cast(res, ctypes.c_char_p)
    sig = val.value
    # IMPORTANT: This function MUST be called before exiting once the program to avoid a memory leak.
    dll.free_signature(res)
    return sig


if __name__ == "__main__":
    # Call the function with the address you want.
    sig = get_signature(0xDEADBEEF)
