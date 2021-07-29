REPOROOT?=${shell git rev-parse --show-toplevel}
#DC:=$(REPOROOT)/../tagion_betterc/ldc2-1.20.1-linux-x86_64/bin/ldc2
DC?=ldc2
LD:=/opt/wasi-sdk/bin/wasm-ld
#LD:=$(REPOROOT)/../tools/wasi-sdk/bin/wasm-ld

SRC:=.
BIN:=bin
MAIN:=delegateapp
DFILES:=$(MAIN).d

# LDWFLAGS+=--export=test_ptr
# LDWFLAGS+=--export=get_x
# LDWFLAGS+=--export=get_y
# LDWFLAGS+=--export=get_c
# LDWFLAGS+=--export=get_f
# LDWFLAGS+=--export=get_d
LDWFLAGS+=--export=set_x
#LDWFLAGS+=--export=get_set_x
#LDWFLAGS+=--export=get_mangle
LDWFLAGS+=--export=_D11delegateapp1S3setMFiZi
LDWFLAGS+=--export=_D11delegateapp9get_s_setFPSQBa1SZDFiZi
#_D11delegateapp9get_set_xFPSQBa1SZDFiZi
#_D11delegateapp9get_set_xFPSQBa1SZDFiZi
# LDWFLAGS+=--export=set_y
# LDWFLAGS+=--export=set_c
# LDWFLAGS+=--export=set_f
# LDWFLAGS+=--export=set_d

# LDWFLAGS+=--export=float_to_string
# LDWFLAGS+=--export=calculate
WASMFLAGS+=-O
