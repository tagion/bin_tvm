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

import std.algorithm.iteration : filter, each;
import std.path : extension;
import std.stdio;
import std.math;
import std.string : toStringz, fromStringz;

import core.sys.posix.dlfcn;
import core.stdc.stdio;


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

    void* hndl = dlopen(dll_file.toStringz, RTLD_LAZY);
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

    WamrSymbols wasm_symbols;
    dll_set_symbols(wasm_symbols);
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

    writeln("Passed");

    return 0;
}
