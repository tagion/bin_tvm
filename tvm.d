module tvm;

import tagion.utils.JSONCommon;

/++
 Options for the network
+/
struct Options {
    int x;
    mixin JSONCommon;
    mixin JSONConfig;
}

import std.stdio;
import std.math;
import std.string : toStringz, fromStringz;


//#include <stdio.h>
//#include "bh_platform.h"
//#include "wasm_export.h"
//#include "math.h"

extern(C) {
import tagion.tvm.c.wasm_export;
import tagion.tvm.c.wasm_runtime_common;

// extern bool
// wasm_runtime_call_indirect(wasm_exec_env_t exec_env,
//                            uint element_indices,
//                            uint argc, uint[] argv);

// The first parameter is not exec_env because it is invoked by native funtions
void reverse(char* str, int len) {
    int i = 0, j = len - 1;
    char temp;
    while (i < j) {
        temp = str[i];
        str[i] = str[j];
        str[j] = temp;
        i++;
        j--;
    }
}

// The first parameter exec_env must be defined using type wasm_exec_env_t
// which is the calling convention for exporting native API by WAMR.
//
// Converts a given integer x to string str[].
// digit is the number of digits required in the output.
// If digit is more than the number of digits in x,
// then 0s are added at the beginning.
int intToStr(wasm_exec_env_t exec_env, int x, char* str, int str_len, int digit) {
    int i = 0;

    writefln("calling into native function: %s", __FUNCTION__);

    while (x) {
        // native is responsible for checking the str_len overflow
        if (i >= str_len) {
            return -1;
        }
        str[i++] = (x % 10) + '0';
        x = x / 10;
    }

    // If number of digits required is more, then
    // add 0s at the beginning
    while (i < digit) {
        if (i >= str_len) {
            return -1;
        }
        str[i++] = '0';
    }

    reverse(str, i);

    if (i >= str_len)
        return -1;
    str[i] = '\0';
    return i;
}

int get_pow(wasm_exec_env_t exec_env, int x, int y) {
    writefln("calling into native function: %s\n", __FUNCTION__);
    return cast(int)pow(x, y);
}

int
calculate_native(wasm_exec_env_t exec_env, int n, int func1, int func2) {
    writefln("calling into native function: %s, n=%d, func1=%d, func2=%d",
           __FUNCTION__, n, func1, func2);

    uint[] argv = [ n ];
    if (!wasm_runtime_call_indirect(exec_env, func1, 1, argv.ptr)) {
        writeln("call func1 failed");
        return 0xDEAD;
    }

    uint n1 = argv[0];
    writefln("call func1 and return n1=%d", n1);

    if (!wasm_runtime_call_indirect(exec_env, func2, 1, argv.ptr)) {
        writeln("call func2 failed");
        return 0xDEAD;
    }

    uint n2 = argv[0];
    writefln("call func2 and return n2=%d", n2);
    return n1 + n2;
}
}

int main(string[] args) {
    import tagion.tvm.TVM;
//    auto net_opts = getopt(args, std.getopt.config.passThrough, "net-mode", &(local_options.net_mode));
//    import src.native_impl;
    import std.stdio;
    import std.file : fread=read, exists;
    const testapp_file=args[1];
    immutable wasm_code = cast(immutable(ubyte[]))testapp_file.fread();
    WamrSymbols wasm_symbols;
    wasm_symbols("intToStr", &intToStr, "(i*~i)i");
    wasm_symbols("get_pow", &get_pow, "(ii)i");
    wasm_symbols("calculate_native", &calculate_native, "(iii)i");

    uint[] global_heap;
    global_heap.length=512 * 1024;

    auto wasm_engine=new TVMEngine(
        wasm_symbols,
        8092, // Stack size
        8092, // Heap size
        global_heap, // Global heap
        wasm_code,
        "env");

    //
    // Calling Wasm functions from D
    //
    float ret_val;

    {
        import std.conv : to;
        auto generate_float=wasm_engine.lookup("generate_float");
        ret_val=wasm_engine.call!float(generate_float, 10, 0.000101, 300.002f);
        assert(ret_val.to!string == "102010");
    }

    {
        auto float_to_string=wasm_engine.lookup("float_to_string");
        char* native_buffer;
        auto wasm_buffer=wasm_engine.malloc(100, native_buffer);
        scope(exit) {
            wasm_engine.free(wasm_buffer);
        }
        wasm_engine.call!void(float_to_string, ret_val, wasm_buffer, 100, 3);
        assert(fromStringz(native_buffer) == "102009.921");
    }

    {
        auto calculate=wasm_engine.lookup("calculate");
        auto ret=wasm_engine.call!int(calculate, 3);
        assert(ret == 120);
    }

    writeln("Passed");

    return 0;
}
