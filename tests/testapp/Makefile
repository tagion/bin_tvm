REPOROOT?=${shell git rev-parse --show-toplevel}
DC?=dmd

BIN?=bin
LIB:=$(BIN)/libtestapp.so
DFILES:=native_impl.d
OBJS:=${addprefix $(BIN)/,${DFILES:.d=.o}}

DCFLAGS+=-I${REPOROOT}/../lib_tvm

all: $(BIN) $(LIB)
	$(MAKE) -C betterc

$(LIB): $(OBJS)
	$(DC) -of$@ $< -shared -defaultlib=libphobos2.so

$(OBJS): $(DFILES)
	$(DC) $(DCFLAGS) -c $(DFILES) -fPIC -od=$(BIN)

$(BIN):
	mkdir -p $(BIN)

info:
	@echo "DFILES=$(DFILES)"
	@echo "OBJS  =$(OBJS)"


clean:
	rm -fR $(BIN)
	$(MAKE) -C betterc clean
