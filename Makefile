all:
	./build_env.sh -f

parser: parser.c
	gcc -Wall -ansi -o parser parser.c `xml2-config --libs --cflags`
	
clean:
	rm -rf parser

.PHONY: all, clean