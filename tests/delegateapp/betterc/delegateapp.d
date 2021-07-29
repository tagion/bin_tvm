/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

struct S {
    int x;
    int set(int x) {
        this.x = x;
        return this.x * 2;
    }
    // char c;
    // long y;
    // float f;
    // double d;

}
//S s;
int delegate(int) get_s_set(S* s) {
    return &s.set;
}

extern(C):

// int intToStr(int x, char* str, int str_len, int digit);
// int get_pow(int x, int y);
// int calculate_native(int n, int func1, int func2);


int set_x(S* s, int x) {
    return s.set(x);
//    return s.x;
}

pragma(msg, "Mangle ", S.set.mangleof);
pragma(msg, "Mangle ", get_s_set.mangleof);
// char* get_mangle() {
//     return cast(char*)S.set.mangleof.ptr;
// }
// char get_c(S s) {
//     return s.c;
// }

// long get_y(S s) {
//     return s.y;
// }

// float get_f(S s) {
//     return s.f;
// }

// double get_d(S s) {
//     return s.d;
// }

// int test_ptr(S* s) {
//     return s.x;
// }

// int set_x(S* s, int x) {
//     s.x = x;
//     return s.x;
// }

// long set_y(S* s, long y) {
//     s.y = y;
//     return s.y;
// }

// char set_c(S* s, char c) {
//     s.c = c;
//     return s.c;
// }

// float set_f(S* s, float f) {
//     s.f = f;
//     return s.f;
// }

// double set_d(S* s, double d) {
//     s.d = d;
//     return s.d;
// }

void _start() {}
