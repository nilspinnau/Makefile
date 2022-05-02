# about the software
NAME 				:= program_name
VERSION				:= 0.1.0

# general
CXX					?= g++
LD					:= $(CXX)
CXX_FLAGS 			:= -Wall -Wextra -std=c++17
BUILD				:= ./build
OBJ_DIR				:= $(BUILD)/objects
APP_DIR				:= $(BUILD)
# source code and .o files location
SRC					:= $(wildcard src/*.cpp) $(wildcard src/*/*.cpp)
OBJECTS 			:= $(SRC:%.cpp=$(OBJ_DIR)/%.o)
# test source code and its .o file location
TEST				:= $(wildcard test/*.cpp) $(wildcard test/*/*.cpp)
TEST_OBJECTS 		:= $(TEST:%.cpp=$(OBJ_DIR)/%.o)

# specifics for executables/libs
EXEC_TARGET			:= $(NAME)-$(VERSION)
TEST_TARGET			:= $(NAME)-test-$(VERSION)
STATIC_LIB_TARGET	:= lib$(NAME).$(VERSION).a
DYN_LIB_TARGET		:= lib$(NAME).so.$(VERSION)


EXEC_FLAGS			:= 

# specific flags, libs and includes for proper compilation and linking
CXX_FLAGS			+=
LD_FLAGS			+= 
LD_LIBS				+= -lpthread -lm -lstdc++ -L.
INCLUDE				:= -Iinclude/ -I/usr/local/include -I/usr/include

MODULES				:=
DEBUG				:=


.PHONY: all buildModules build clean debug release valgrind static dynamic exec

all: buildModules build exec

# compile source code the object files
$(OBJECTS): $(SRC)
	-@mkdir -p $(@D)
	$(CXX) $(CXX_FLAGS) $(INCLUDE) -c $< -o $@

# compile test source code the object files
$(TEST_OBJECTS): $(TEST)
	-@mkdir -p $(@D)
	$(CXX) $(CXX_FLAGS) $(INCLUDE) -c $< -o $@


# make a program
exec: $(OBJECTS)
	-@mkdir -p $(@D)
	$(LD) $(LD_FLAGS) -o $(APP_DIR)/$(EXEC_TARGET) $^ $(LD_LIBS)

# make static and dynamic library entries 
lib: CXX_FLAGS += -fPIC -g
lib: LD_FLAGS += -shared -Wl,-soname,$(DYN_LIB_TARGET) 
lib: $(OBJECTS)
	-@mkdir -p $(@D)
	$(CXX) -o $(APP_DIR)/$(DYN_LIB_TARGET) $^ $(LD_FLAGS)
	ar rcs $(APP_DIR)/$(STATIC_LIB_TARGET) $^


# compile the tests to a executable program
# immediatly run the tests?
test: CXX_FLAGS += -DDEBUG
test: INCLUDE += 
test: LD_LIBS += 
test: $(TEST_OBJECTS)
	$(LD) $(LD_FLAGS) -o $(APP_DIR)/$(TEST_TARGET) $^ $(LD_LIBS)
	$(APP_DIR)/$(TEST_TARGET)

buildModules:
	$(foreach module,$(MODULES), make $(DEBUG) -C lib/$(module)/;)

build: 
	@mkdir -p $(OBJ_DIR)

valgrind: all
	valgrind \
		--leak-check=full \
		--trace-children=yes \
		--show-leak-kinds=all \
		--track-origins=yes \
		--log-file=valgrind-out.txt \
		$(TARGET) $(EXEC_FLAGS)

debug: CXX_FLAGS += -g -v -DDEBUG 
debug: DEBUG := debug
debug: clean all

release: CXX_FLAGS += -02
release: clean all

clean:
	-@rm -rvf $(OBJ_DIR)
	-@rm -rvf $(BUILD)
	$(foreach module,$(MODULES), make clean -C lib/$(module)/;)