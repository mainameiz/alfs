#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <libgen.h>
#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/xmlreader.h>
	#include <libxml/debugXML.h>
#include <string.h>

const char *build_dir = "builds";
xmlChar *cur_file = NULL;

static void
find_userinput(xmlNode *a_node, FILE *fd)
{
	xmlNode *cur_node = NULL;
	xmlChar *content = NULL;
	xmlChar *remap = NULL;

	for (cur_node = a_node; cur_node; cur_node = cur_node->next) {
                if (cur_node->type == XML_ENTITY_REF_NODE)
                    return;
		if (cur_node->type == XML_ELEMENT_NODE) {
                        if (!xmlStrcmp(cur_node->name, (const xmlChar *)"productname")) {
				content = xmlNodeGetContent(cur_node);
				//fprintf(fd, "get %s\n", content);
				fprintf(fd, "unpack %s\n\n", content);
				xmlFree(content);
			} else if (!xmlStrcmp(cur_node->name, (const xmlChar *)"userinput")) {
				remap = xmlGetProp(cur_node, "remap");
				if (!xmlStrcmp(remap, (const xmlChar *)"pre")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "#pre\n");
					fprintf(fd, "%s\n", content, cur_file);
					fprintf(fd, "#endpre\n\n");
				} else if (!xmlStrcmp(remap, (const xmlChar *)"configure")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "#conf\n");
					fprintf(fd, "%s\n", content, cur_file);
					fprintf(fd, "#endconf\n\n");
				} else if (!xmlStrcmp(remap, (const xmlChar *)"make")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "#make\n");
					fprintf(fd, "%s\n", content, cur_file);
					fprintf(fd, "#endmake\n\n");
				} else if (!xmlStrcmp(remap, (const xmlChar *)"install")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "#install\n");
					fprintf(fd, "%s\n", content, cur_file);
					fprintf(fd, "#endinstall\n\n");
				}
				xmlFree(content);
			}
		}
		find_userinput(cur_node->children, fd);
	}
}

static int
build_script(char *filename, FILE *fd)
{
	xmlDocPtr doc = NULL;
	xmlNode *root_element = NULL;

	doc = xmlReadFile(filename, NULL, XML_PARSE_DTDATTR | XML_PARSE_DTDLOAD);
	
	if (doc == NULL) {
		fprintf(stderr, "#Failed to parse %s\n", filename);
		return 1;
	}

	root_element = xmlDocGetRootElement(doc);

	find_userinput(root_element, fd);

	xmlFreeDoc(doc);
	xmlCleanupParser();

	return 0;
}

static void
find_include(xmlNode *a_node, xmlChar *book_dir)
{
	xmlNode *cur_node = NULL;
	xmlChar *href = NULL;
	FILE *fd = NULL;
	int file_len = 0;
	int book_dir_len = 0;
	int href_len = 0;
	int build_dir_len = 0;
	char *filename = NULL;
	char *build_file = NULL;
	char file_prefix[3];
	unsigned short prefix = 0;

	for (cur_node = a_node; cur_node; cur_node = cur_node->next) {
		if (cur_node->type == XML_ELEMENT_NODE) {
			if (!xmlStrcmp(cur_node->name, (const xmlChar *)"include")) {
				href = xmlGetProp(cur_node, "href");
				cur_file = href;
				printf("Parsing %s ...\n", href);

				book_dir_len = xmlStrlen(book_dir);
				href_len = xmlStrlen(href);
				file_len = book_dir_len + href_len + 2;
				filename = (char *)malloc(sizeof(char) * file_len);
				strcpy(filename, book_dir);
				strcat(filename, "/");
				strcat(filename, href);
				
				build_dir_len = strlen(build_dir);
				build_file = (char *)malloc(sizeof(char) * (build_dir_len + href_len + 8));
				if (prefix > 99) {
					fprintf(stderr, "file prefix is not valid!");
					exit(1);
				}
				sprintf(file_prefix, "%.2d", prefix);
				prefix++;
				strcpy(build_file, build_dir);
				strcat(build_file, "/");
				strcat(build_file, file_prefix);
				strcat(build_file, "-");
				strcat(build_file, href);
				strcat(build_file, ".sh");
				
				fd = fopen(build_file, "w");
				fprintf(fd, "#!/bin/sh\n\n");
				build_script(filename, fd);
				fclose(fd);
				chmod(build_file, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);
				
				free(filename);
				filename = NULL;
				xmlFree(href);
				href = NULL;
			}
		}
		find_include(cur_node->children, book_dir);
	}
}

int
main (int argc, char **argv)
{
	xmlTextReaderPtr reader = NULL;
	int ret = 0;
	xmlDocPtr doc = NULL;
	xmlNode *root_element = NULL;
	const xmlChar *URL = NULL;

	if (argc != 2) {
		fprintf(stderr, "Usage: %s FILE\n", argv[0]);
		return 1;
	}
	
	mkdir(build_dir, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);

	LIBXML_TEST_VERSION

	doc = xmlReadFile(argv[1], NULL, 0);
	if (doc == NULL) {
		fprintf(stderr, "Failed to create reader...\n");
		return 1;
	}

	char *book_dir = dirname(argv[1]);

	root_element = xmlDocGetRootElement(doc);
	
	find_include(root_element, (xmlChar *)book_dir);

	xmlFreeDoc(doc);
	xmlCleanupParser();

	return 0;
}
