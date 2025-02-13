COMPILER_FLAGS := -O3 -std=c++20 -s -w -Wreturn-type -fpermissive -Isdk/include
OUTPUT_FLAGS   := -o $(OUTPUT_FILE)

OBJ_DIR        := obj/
OBJ_FILES      := $(wildcard $(OBJ_DIR)*.o)

OSTYPE        := $(shell uname -s)

ifeq ($(OSTYPE), Linux)
	USE_COMPILER := gcc
	COMPILER_FLAGS += -fPIC -D__LINUX__
	LINKER_FLAGS := -shared -Lsdk/lib/x64_linux_gcc_64 -l:libida64.so -Wl,-rpath=sdk/lib/x64_linux_gcc_64
	ifeq ($(BUILD_FOR), 32)
		COMPILER_FLAGS += -Lsdk/lib/x64_linux_gcc_32
	else
		COMPILER_FLAGS += -Lsdk/lib/x64_linux_gcc_64 -D__EA64__
	endif
else ifeq ($(OSTYPE), Darwin)
	USE_COMPILER := clang++
	COMPILER_FLAGS += -D__MACOS__ -D__ARM__
	LINKER_FLAGS := -dynamiclib -Lsdk/lib/arm64_mac_clang_64 -lida -Wl,-rpath,sdk/lib/arm64_mac_clang_64
	ifeq ($(BUILD_FOR), 32)
		COMPILER_FLAGS += -Lsdk/lib/arm64_mac_clang_32
	else
		COMPILER_FLAGS += -Lsdk/lib/arm64_mac_clang_64 -D__EA64__
	endif
else
	USE_COMPILER := x86_64-w64-mingw32-g++
	COMPILER_FLAGS += -D__NT__
	LINKER_FLAGS := -static -Wl,-exclude-all-symbols,--kill-at -shared -l:ida.lib
	ifeq ($(BUILD_FOR), 32)
		COMPILER_FLAGS += -Lsdk/lib/x64_win_vc_32
	else
		COMPILER_FLAGS += -Lsdk/lib/x64_win_vc_64 -D__EA64__
	endif
endif

CPP_FILES      := $(wildcard ./sdk/include/*.cpp) $(wildcard ./src/*.cpp)

.PHONY: all make_objects make_output clean

all: make_objects make_output

make_objects: $(CPP_FILES)
	@mkdir -p $(OBJ_DIR)
	@count=0; \
	for file in $(CPP_FILES); do \
	  printf "[INFO] Compiling $$file\n"; \
	  $(USE_COMPILER) $$file -c -o $(OBJ_DIR)$$count.o $(COMPILER_FLAGS); \
	  count=$$((count + 1)); \
	done

make_output: $(OBJ_FILES)
	@printf "[INFO] Linking output: $(notdir $(OUTPUT_FILE))\n"
	@$(USE_COMPILER) $(OUTPUT_FLAGS) $(COMPILER_FLAGS) $(OBJ_FILES) $(LINKER_FLAGS)

clean:
	@printf "[INFO] Cleaning object files and output\n"
	@rm -rf $(OBJ_DIR) *.exe *.dll *.so *.dylib
