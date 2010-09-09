parser: parser.c
	gcc -o parser parser.c `xml2-config --libs --cflags`