SHELL=/bin/bash

# compiler and linker flags
CXX = g++
LD = g++
OPTIM = -O3
CXXFLAGS = -std=c++17 -s -Wall
DEPFLAGS = -MT $@ -MMD -MP -MF
GCOVFLAGS = -fprofile-arcs -ftest-coverage -fno-inline -fno-inline-small-functions -fno-default-inline
LDFLAGS = 
TEST_LDFLAGS = -lgtest -lgtest_main -lpthread

# library settings
LIB_TARGET_BASE = libcppenvsample.so
LIB_VER = 0.0.1
INCLUDE_DIR = cpp_env_sample

# targets
MAIN_TARGET = cpp_env_sample
LIB_TARGET = $(LIB_TARGET_BASE).$(LIB_VER)
TEST_TARGET = test_cpp_env_sample
GCOV_TARGET = gcov
LCOV_TARGET = lcov

# sources
SRCDIR = src
OBJDIR = build
DEPDIR = $(OBJDIR)
SRCS = $(wildcard $(SRCDIR)/*.cc)
OBJS = $(subst $(SRCDIR)/,$(OBJDIR)/,$(SRCS:.cc=.o))

# includes
INCLUDES = -I./include
TEST_INCLUDES = -I/usr/local/include

# main
MAINDIR = main
MAIN_SRCS = $(MAINDIR)/main.cc
MAIN_OBJS = $(subst $(MAINDIR)/,$(OBJDIR)/,$(MAIN_SRCS:.cc=.o))
DEPS = $(OBJS:.o=.d) $(MAIN_OBJS:.o=.d)

# lib
LIB_OBJDIR = build/lib
LIB_DEPDIR = $(LIB_OBJDIR)
LIB_OBJS = $(subst $(SRCDIR)/,$(LIB_OBJDIR)/,$(SRCS:.cc=.o))
LIB_DEPS = $(LIB_OBJS:.o=.d)

# test
TEST_SRCDIR = test
TEST_OBJDIR = build/test
TEST_DEPDIR = $(TEST_OBJDIR)
TEST_SRCS = $(wildcard $(TEST_SRCDIR)/*.cc)
TEST_TARGET_OBJS = $(subst $(SRCDIR)/,$(TEST_OBJDIR)/,$(SRCS:.cc=.o))
TEST_TEST_OBJS = $(subst $(TEST_SRCDIR)/,$(TEST_OBJDIR)/,$(TEST_SRCS:.cc=.o))
TEST_DEPS = $(TEST_TARGET_OBJS:.o=.d) $(TEST_TEST_OBJS:.o=.d)

# gcov
GCOV_OBJDIR = build/gcov
GCOV_DEPDIR = $(GCOV_OBJDIR)
GCOV_TARGET_OBJS = $(subst $(SRCDIR)/,$(GCOV_OBJDIR)/,$(SRCS:.cc=.o))
GCOV_TEST_OBJS = $(subst $(TEST_SRCDIR)/,$(GCOV_OBJDIR)/,$(TEST_SRCS:.cc=.o))
GCOV_DEPS = $(GCOV_TARGET_OBJS:.o=.d) $(GCOV_TEST_OBJS:.o=.d)

# lcov
LCOVDIR = lcov
COVERAGE = coverage.info

# doxygen
DOXYGEN = doxygen
DOCDIR = doxygen
INDEXPATH = $(DOCDIR)/html/index.html

.PHONY: all build install uninstall lib test gcov lcov docs clean 

build: $(MAIN_TARGET)

lib: $(LIB_TARGET)

install:
	@install -d /usr/local/include/$(INCLUDE_DIR) > /dev/null 2>&1
	@install include/$(INCLUDE_DIR)/* /usr/local/include/$(INCLUDE_DIR)/
	@install $(LIB_OBJDIR)/$(LIB_TARGET) /usr/local/lib/
	@ln -sf /usr/local/lib/$(LIB_TARGET) /usr/local/lib/$(LIB_TARGET_BASE)

uninstall:
	@rm -rf /usr/local/include/$(INCLUDE_DIR)
	@rm -f /usr/local/lib/$(LIB_TARGET)
	@rm -f /usr/local/lib/$(LIB_TARGET_BASE)

test: $(TEST_TARGET)

$(LCOV_TARGET): $(GCOV_TARGET)
	lcov --capture --directory . --output-file $(COVERAGE)
	lcov --remove $(COVERAGE) **include/c++/** --output-file $(COVERAGE)
	lcov --remove $(COVERAGE) **bits** --output-file $(COVERAGE)
	lcov --remove $(COVERAGE) **gtest*.h --output-file $(COVERAGE)
	lcov --remove $(COVERAGE) **gtest*.cc --output-file $(COVERAGE)
	genhtml $(COVERAGE) --output-directory $(LCOVDIR)
	@rm -f *.gcno
	@rm -f *.gcda
	@rm -f $(COVERAGE)
	@echo -n -e ""
	@echo $(LCOVDIR)/index.html

docs:
	$(DOXYGEN)
	@echo $(INDEXPATH)

all: build lib test lcov docs

$(TEST_TARGET): LDFLAGS += $(TEST_LDFLAGS)
$(GCOV_TARGET): LDFLAGS += $(TEST_LDFLAGS)

$(MAIN_TARGET): $(MAIN_OBJS) $(OBJS)
	$(LD) -o $@ $^ $(LDFLAGS)

$(TEST_TARGET): $(TEST_TEST_OBJS) $(TEST_TARGET_OBJS)
	$(LD) -o $@ $^ $(LDFLAGS) 

$(GCOV_TARGET): $(GCOV_TEST_OBJS) $(GCOV_TARGET_OBJS)
	$(LD) $(GCOVFLAGS) -o $(TEST_TARGET) $^ $(LDFLAGS) 
	./$(TEST_TARGET)

$(LIB_TARGET): $(LIB_OBJS)
	$(LD) -shared -o $(LIB_OBJDIR)/$@ $^ $(LDFLAGS)

$(MAIN_TARGET): DEPFLAGS += $(DEPDIR)/$*.d
$(TEST_TARGET): DEPFLAGS += $(TEST_DEPDIR)/$*.d
$(LIB_TARGET): DEPFLAGS += $(LIB_DEPDIR)/$*.d
$(GCOV_TARGET): DEPFLAGS += $(GCOV_DEPDIR)/$*.d

CXXFLAGS += $(DEPFLAGS)

$(GCOV_TARGET): CXXFLAGS += $(GCOVFLAGS)

$(TEST_TARGET): INCLUDES += $(TEST_INCLUDES)
$(GCOV_TARGET): INCLUDES += $(TEST_INCLUDES)

$(OBJS): $(OBJDIR)/%.o: $(SRCDIR)/%.cc $(OBJDIR)/%.d
	@mkdir -p $(dir $(OBJS))
	$(CXX) $(CXXFLAGS) $(OPTIM) $(INCLUDES) -c $< -o $@

$(MAIN_OBJS): $(OBJDIR)/%.o: $(MAINDIR)/%.cc $(OBJDIR)/%.d
	@mkdir -p $(dir $(OBJS))
	$(CXX) $(CXXFLAGS) $(OPTIM) $(INCLUDES) -c $< -o $@

$(DEPS):

$(LIB_OBJS): $(LIB_OBJDIR)/%.o: $(SRCDIR)/%.cc $(LIB_OBJDIR)/%.d
	@mkdir -p $(dir $(LIB_OBJS))
	$(CXX) $(CXXFLAGS) -fPIC $(OPTIM) $(INCLUDES) -c $< -o $@

$(LIB_DEPS):

$(TEST_TEST_OBJS): $(TEST_OBJDIR)/%.o: $(TEST_SRCDIR)/%.cc $(TEST_OBJDIR)/%.d
	@mkdir -p $(dir $(TEST_TARGET_OBJS))
	$(CXX) $(CXXFLAGS) $(OPTIM) $(INCLUDES) -c $< -o $@

$(TEST_TARGET_OBJS): $(TEST_OBJDIR)/%.o: $(SRCDIR)/%.cc $(TEST_OBJDIR)/%.d
	@mkdir -p $(dir $(TEST_TARGET_OBJS))
	$(CXX) $(CXXFLAGS) $(OPTIM) $(INCLUDES) -c $< -o $@

$(TEST_DEPS):

$(GCOV_TEST_OBJS): $(GCOV_OBJDIR)/%.o: $(TEST_SRCDIR)/%.cc $(GCOV_OBJDIR)/%.d
	@mkdir -p $(dir $(GCOV_TARGET_OBJS))
	$(CXX) $(CXXFLAGS) $(OPTIM) $(INCLUDES) -c $< -o $@

$(GCOV_TARGET_OBJS): $(GCOV_OBJDIR)/%.o: $(SRCDIR)/%.cc $(GCOV_OBJDIR)/%.d
	@mkdir -p $(dir $(GCOV_TARGET_OBJS))
	$(CXX) $(CXXFLAGS) $(OPTIM) $(INCLUDES) -c $< -o $@

$(GCOV_DEPS):

clean:
	@rm -f $(MAIN_TARGET)
	@rm -f $(TEST_TARGET)
	@rm -rf $(OBJDIR)
	@rm -rf $(LCOVDIR)
	@rm -rf $(DOCDIR)

-include $(DEPS) $(TEST_DEPS) $(GCOV_DEPS)
