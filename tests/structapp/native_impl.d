module native_impl;

import std.stdio;
import std.math;
import std.string : toStringz, fromStringz;

extern(C) {
    import tagion.tvm.c.wasm_export;
    import tagion.tvm.c.wasm_runtime_common;

    version(none) {
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
}

extern(C) {
    import tagion.tvm.TVM;

    void set_symbols(ref WamrSymbols wasm_symbols) {
        // wasm_symbols.declare!intToStr;
        // wasm_symbols.declare!get_pow;
        // wasm_symbols.declare!calculate_native;
    }

    static struct S {
        int x;
        char c;
        long y;
        float f;
        double d;
    }

    void run(ref TVMEngine wasm_engine) {
                //
        // Calling Wasm functions from D
        //

        {
            import std.conv : to;
            auto test=wasm_engine.lookup("test");
            S s;
            s.x=42;

            const ret_val=wasm_engine.call!int(test, s);
            writefln("ret_val=%s", ret_val);
//            assert(ret_val.to!string == "102010");
        }

        version(none)
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

        version(none)
        {
            auto calculate=wasm_engine.lookup("calculate");
            auto ret=wasm_engine.call!int(calculate, 3);
            assert(ret == 120);
        }
    }

    void do_hello() {
        writefln("Module %s", native_impl.stringof);
    }
}
