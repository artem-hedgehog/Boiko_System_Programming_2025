CC = gcc
ASM = fasm
TARGET = program64
OBJ = main.o queue.o

$(TARGET): $(OBJ)
	$(CC) -o $@ $^

main.o: main.c
	$(CC) -c -o $@ $<

queue.o: queue.asm
	$(ASM) $<

clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: clean