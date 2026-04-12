CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -Iinclude
SRC_DIR = src
BUILD_DIR = build

SRCS = \
	$(SRC_DIR)/main.c \
	$(SRC_DIR)/normalizer.c \
	$(SRC_DIR)/csv_reader.c \
	$(SRC_DIR)/csv_writer.c \
	$(SRC_DIR)/name_normalizer.c \
	$(SRC_DIR)/country_normalizer.c \
	$(SRC_DIR)/rank_parser.c \
	$(SRC_DIR)/score_parser.c \
	$(SRC_DIR)/requirement_parser.c \
	$(SRC_DIR)/utils.c

OBJS = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
TARGET = $(BUILD_DIR)/clawer_normalizer

TEST_TARGET      = $(BUILD_DIR)/test_normalizer
TEST_SRC         = src/tests/test_normalizer.c
TEST_OBJS        = $(filter-out $(BUILD_DIR)/main.o,$(OBJS)) $(BUILD_DIR)/test_normalizer.o

TEST_EXTREME_TARGET = $(BUILD_DIR)/test_extreme
TEST_EXTREME_SRC    = src/tests/test_extreme.c
TEST_EXTREME_OBJS   = $(filter-out $(BUILD_DIR)/main.o,$(OBJS)) $(BUILD_DIR)/test_extreme.o

TEST_SCALE_TARGET = $(BUILD_DIR)/test_scale
TEST_SCALE_SRC    = src/tests/test_scale.c
TEST_SCALE_OBJS   = $(filter-out $(BUILD_DIR)/main.o,$(OBJS)) $(BUILD_DIR)/test_scale.o

.PHONY: all run test test_extreme test_scale clean rebuild

all: $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET)

$(TEST_TARGET): $(TEST_OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(TEST_OBJS) -o $(TEST_TARGET)

$(TEST_EXTREME_TARGET): $(TEST_EXTREME_OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(TEST_EXTREME_OBJS) -o $(TEST_EXTREME_TARGET)

$(TEST_SCALE_TARGET): $(TEST_SCALE_OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(TEST_SCALE_OBJS) -o $(TEST_SCALE_TARGET)

$(BUILD_DIR)/test_normalizer.o: $(TEST_SRC)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(TEST_SRC) -o $(BUILD_DIR)/test_normalizer.o

$(BUILD_DIR)/test_extreme.o: $(TEST_EXTREME_SRC)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(TEST_EXTREME_SRC) -o $(BUILD_DIR)/test_extreme.o

$(BUILD_DIR)/test_scale.o: $(TEST_SCALE_SRC)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(TEST_SCALE_SRC) -o $(BUILD_DIR)/test_scale.o

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

run: $(TARGET)
	./$(TARGET)

test: $(TEST_TARGET)
	./$(TEST_TARGET)

test_extreme: $(TEST_EXTREME_TARGET)
	./$(TEST_EXTREME_TARGET)

test_scale: $(TEST_SCALE_TARGET)
	./$(TEST_SCALE_TARGET)

clean:
	rm -rf $(BUILD_DIR)

rebuild: clean all
