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

import tagion.basic.Basic : doFront;
import tagion.tvm.TVM;
// import tagion.tvm.c.wasm_export;
// import tagion.tvm.c.wasm_runtime_common;

import std.algorithm.iteration : filter, each;
import std.path : extension;
import std.stdio;
import std.math;
import std.string : toStringz, fromStringz;

import core.sys.posix.dlfcn;
import core.stdc.stdio;

//#include <stdio.h>
//#include "bh_platform.h"
//#include "wasm_export.h"
//#include "math.h"
version(none)
extern(C) {
    import tagion.tvm.c.wasm_export;
    import tagion.tvm.c.wasm_runtime_common;

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

enum ext {
    wasm = ".wasm",
    dll = ".so",
}

extern(C) {
    void set_symbols(ref WamrSymbols wasm_symbols);
    void run(ref TVMEngine wasm_engine);
    void do_hello();
}

int main(string[] args) {
    import std.stdio;
    import std.file : fread=read, exists;

    immutable wasm_file = args
        .filter!((a) => (a.extension == ext.wasm))
        .doFront;
    immutable dll_file = args
        .filter!((a) => (a.extension == ext.dll))
        .doFront;

    if (!dll_file) {
        stderr.writefln("Shared object file missing");
        return 1;
    }

    if (!wasm_file) {
        stderr.writefln("WASM file missing");
        return 2;
    }

    if (!dll_file.exists) {
        stderr.writefln("%s does not exists", dll_file);
        return 3;
    }

    if (!wasm_file.exists) {
        stderr.writefln("%s does not exists", wasm_file);
        return 4;
    }

    immutable wasm_code = cast(immutable(ubyte[]))wasm_file.fread;

    writefln("wasm_code.length=%d", wasm_code.length);

    void* hndl = dlopen(dll_file.toStringz, RTLD_LAZY);
    printf("hndl=%p", hndl);
    scope(exit) {
        dlclose(hndl);
    }
    if (!hndl) {
        stderr.writefln("Unable to open %s", dll_file);
        return 5;
    }

    auto dll_do_hello= cast(typeof(&do_hello))dlsym(hndl, do_hello.mangleof.ptr);
    if (!dll_do_hello) {
        printf("%s\n", dlerror());
        return 6;
    }

    dll_do_hello();

    auto dll_set_symbols= cast(typeof(&set_symbols))dlsym(hndl, set_symbols.mangleof.ptr);
    if (!dll_set_symbols) {
        printf("%s\n", dlerror());
        return 7;
    }

    auto dll_run= cast(typeof(&run))dlsym(hndl, run.mangleof.ptr);
    if (!dll_run) {
        import core.stdc.stdio;
        printf("%s\n", dlerror());
        return 8;
    }

//     if (dll_file) {
//         writefln("dll_file=%s", dll_file);
//         void* hndl = dlopen(dll_file.ptr, RTLD_LAZY);
//         if (!hndl) assert(0);
//         pragma(msg, typeof(&fun));
//         auto p = cast(typeof(&fun))dlsym(hndl, fun.mangleof.ptr);
//         pragma(msg, typeof(p));
//         printf("p=%p\n", p);
//         // void function() f_p;
//         p();
// //        f_p=p;

//     }

//     if (wasm_file) {
//    const testapp_file=args[1];
//        immutable wasm_code = cast(immutable(ubyte[]))wasm_file.fread;
    WamrSymbols wasm_symbols;
    dll_set_symbols(wasm_symbols);
        //wasm_symbols("intToStr", &intToStr, "(i*~i)i");
        // wasm_symbols.declare!intToStr; //calculate_native(); //("calculate_native", &calculate_native, "");
        // wasm_symbols.declare!get_pow;
        // wasm_symbols.declare!calculate_native; //("calculate_native", &calculate_native, "");

        // writefln("paramSymbols =%s", WamrSymbols.paramSymbols!calculate_native());
        // writefln("paramSymbols =%s", WamrSymbols.paramSymbols!get_pow());
        // writefln("paramSymbols =%s", WamrSymbols.paramSymbols!intToStr());
    uint[] global_heap;
    global_heap.length=512 * 1024;

    auto wasm_engine=new TVMEngine(
        wasm_symbols,
        8092, // Stack size
        8092, // Heap size
        global_heap, // Global heap
        wasm_code,
        "env");

    dll_run(wasm_engine);

    /+
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
        +/
    writeln("Passed");

    return 0;
}
