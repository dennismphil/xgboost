CC = emcc
CXX = em++

ifndef RABIT
	RABIT = xgboost/rabit
endif

ifndef DMLC_CORE
	DMLC_CORE = xgboost/dmlc-core
endif

CFLAGS = -O3 -Wall -fPIC --memory-init-file 0 -std=c++11
CFLAGS += -I$(DMLC_CORE)/include -I$(RABIT)/include -Ixgboost/include
BUILD_DIR=dist
EXPORTED_FUNCTIONS="['_create_model', '_set_param', '_train_full_model', '_predict_one', '_free_memory_model', '_save_model', '_get_file_content', '_load_model', '_prediction_size']"

UNAME=$(shell uname)
ifeq ($(UNAME), Darwin)
	COMPILED_FILES = xgboost/lib/libxgboost.dylib
else
	COMPILED_FILES = xgboost/lib/libxgboost.so
endif

all: replace build

replace:
	cp replace-files/dmlc-core/base.h ./xgboost/dmlc-core/include/dmlc/base.h;
	cp replace-files/rabit/base.h ./xgboost/rabit/include/dmlc/base.h;
	cp replace-files/xgboost/c_api.h ./xgboost/include/xgboost/c_api.h;

build:
	cd xgboost; make -j4 config=../make/minimum.mk; cd ..;
	mkdir -p $(BUILD_DIR)/wasm;
	$(CXX) $(CFLAGS) js-interfaces.cpp $(COMPILED_FILES) -o $(BUILD_DIR)/wasm/xgboost.js --pre-js src/wasmPreJS.js -s WASM=1 -s "BINARYEN_METHOD='native-wasm'" -s ALLOW_MEMORY_GROWTH=1 -s EXPORTED_FUNCTIONS=$(EXPORTED_FUNCTIONS)
	# mkdir -p $(BUILD_DIR)/asm;
	# $(CXX) $(CFLAGS) js-interfaces.cpp $(COMPILED_FILES) -o $(BUILD_DIR)/asm/xgboost.js --pre-js src/asmPreJS.js -s EXPORTED_FUNCTIONS=$(EXPORTED_FUNCTIONS) #-s ALLOW_MEMORY_GROWTH=1

clean:
	cd xgboost; make clean_all; cd ..; rm -rf dist;
