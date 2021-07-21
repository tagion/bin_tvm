/*
 * Copyright (C) 2019 Intel Corporation.  All rights reserved.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */

extern(C):

// int intToStr(int x, char* str, int str_len, int digit);
// int get_pow(int x, int y);
// int calculate_native(int n, int func1, int func2);

struct S {
    int x;
    char c;
    long y;
    float f;
    double d;

}

int get_x(S s) {
    return s.x;
}

char get_c(S s) {
    return s.c;
}

long get_y(S s) {
    return s.y;
}

float get_f(S s) {
    return s.f;
}

double get_d(S s) {
    return s.d;
}

int test_ptr(S* s) {
    return s.x;
}

void set_x(S* s, int x) {
    s.x = x;
}

void set_y(S* s, long y) {
    s.y = y;
}

void set_c(S* s, char c) {
    s.c = c;
}

void set_f(S* s, float f) {
    s.f = f;
}

void set_d(S* s, double d) {
    s.d = d;
}

void _start() {}
