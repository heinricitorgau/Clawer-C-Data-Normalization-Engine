CC = gcc
CFLAGS = -Wall -Wextra -std=c11 -Iinclude
SRC_DIR = src
BUILD_DIR = build
TARGET = $(BUILD_DIR)/clawer_normalizer

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

.PHONY: all run clean rebuild

all: $(TARGET)

$(TARGET): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

run: $(TARGET)
	./$(TARGET)

clean:
	rm -rf $(BUILD_DIR)

rebuild: clean all