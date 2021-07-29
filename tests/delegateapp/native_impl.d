module native_impl;

import std.stdio;
//import std.math;
//import std.string : toStringz, fromStringz;

extern(C) {
    import tagion.tvm.c.wasm_export;
    import tagion.tvm.c.wasm_runtime_common;

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
        int set(int x) {
            this.x = x;
            return this.x * 2;
        }
    }

    void run(ref TVMEngine wasm_engine) {
                //
        // Calling Wasm functions from D
        //
        S s;
        s.x=42;

        {
            auto s_set_x=wasm_engine.lookup("_D11delegateapp9get_s_setFPSQBa1SZDFiZi");
            auto s_p = wasm_engine.alloc!(S*);
            scope(exit) {
                wasm_engine.free(s_p);
            }
            const ret_val=wasm_engine.call!int(s_set_x, s_p, 17);
            assert(ret_val == 17);
            assert(ret_val == s_p.x);
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
