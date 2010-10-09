#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <libgen.h>
#include <libxml/tree.h>
#include <libxml/xmlreader.h>
#include <string.h>
#include <getopt.h>

static char *cmd_name;

void find_scrn_or_addr(xmlNode *a_node, FILE *fd);
void find_userinput(xmlNode *a_node, FILE *fd);
int  build_script(char *filename, FILE *fd);
void find_include(xmlNode *a_node, char *book_dir, char *build_dir);
void display_usage(void);

struct global_args_t {
	char *input_file_name;
	char *output_dir;
	int testing;
	int verbosity;
} global_args;

static const char *opt_string = "f:d:tvh?";

static const struct option long_opts[] = {
	{ "input-file", required_argument, NULL, 'f' },
	{ "output-dir", required_argument, NULL, 'd' },
	{ "include-testing", no_argument, NULL, 't' },
	{ "verbose", no_argument, NULL, 'v' },
	{ "help", no_argument, NULL, 'h' },
	{ NULL, no_argument, NULL, 0 }
};

void find_scrn_or_addr(xmlNode *a_node, FILE *fd)
{
	xmlNode *cur_node = NULL;
	xmlChar *content = NULL;
	xmlChar *attr = NULL;

	for (cur_node = a_node; cur_node; cur_node = cur_node->next) {
                if (cur_node->type == XML_ENTITY_REF_NODE)
                    return;
		if (cur_node->type == XML_ELEMENT_NODE) {
			if (!xmlStrcmp(cur_node->name, (const xmlChar *)"address")) {
				content = xmlNodeGetContent(cur_node);
				fprintf(fd, "unpack %s\n", content);
				xmlFree(content);
			} else if (!xmlStrcmp(cur_node->name, (const xmlChar *)"screen")) {
				attr = xmlGetProp(cur_node, (const xmlChar *)"role");
				if (attr && !xmlStrcmp(attr, (const xmlChar *)"nodump")) {
					xmlFree(attr);
					attr = NULL;
					continue;
				}
				find_userinput(cur_node->children, fd);
				xmlFree(attr);
				attr = NULL;
			}
		}
		find_scrn_or_addr(cur_node->children, fd);
	}
}

void find_userinput(xmlNode *a_node, FILE *fd)
{
	xmlNode *cur_node = NULL;
	xmlChar *content = NULL;
	xmlChar *remap = NULL;
	
	for (cur_node = a_node; cur_node; cur_node = cur_node->next) {
		if (cur_node->type == XML_ENTITY_REF_NODE)
			return;
		if (cur_node->type == XML_ELEMENT_NODE) {
			if (!xmlStrcmp(cur_node->name, (const xmlChar *)"userinput")) {
				remap = xmlGetProp(cur_node, (const xmlChar *)"remap");
				if (!xmlStrcmp(remap, (const xmlChar *)"test")) {
					if (global_args.testing > 0) {
						content = xmlNodeGetContent(cur_node);
						fprintf(fd, "%s\n", content);
					} else {
						fprintf(fd, "# tests was being skipped\n");
					}
				} else {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "%s\n", content);
				}
				xmlFree(content);
			}
		}
	}
}

int build_script(char *filename, FILE *fd)
{
	xmlDocPtr doc = NULL;
	xmlNode *root_element = NULL;

	doc = xmlReadFile(filename, NULL, XML_PARSE_DTDATTR | XML_PARSE_DTDLOAD);

	if (doc == NULL) {
		fprintf(stderr, "%s: Failed to parse %s\n", cmd_name, filename);
		exit(EXIT_FAILURE);;
	}

	root_element = xmlDocGetRootElement(doc);

	find_scrn_or_addr(root_element, fd);

	xmlFreeDoc(doc);
	xmlCleanupParser();

	return 0;
}

void find_include(xmlNode *a_node, char *book_dir, char *build_dir)
{
	xmlNode *cur_node = NULL;
	char *href = NULL;
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
				href = (char *)xmlGetProp(cur_node, (const xmlChar *)"href");
				if (global_args.verbosity > 0) {
					printf(">>> Parsing %s\n", href);
				}

				book_dir_len = strlen(book_dir);
				href_len = strlen(href);
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
				fprintf(fd, "#!/bin/bash\n\n");
				build_script(filename, fd);
				fclose(fd);
				chmod(build_file, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);
				
				free(filename);
				filename = NULL;
				xmlFree(href);
				href = NULL;
			}
		}
		find_include(cur_node->children, book_dir, build_dir);
	}
}

int
main (int argc, char **argv)
{
	xmlDocPtr doc = NULL;
	xmlNode *root_element = NULL;
	int opt = 0;
	int opt_index = 0;

	global_args.input_file_name = NULL;
	global_args.output_dir = NULL;
	global_args.verbosity = 0;
	global_args.testing = 0;

	cmd_name = basename(argv[0]);

	opt = getopt_long(argc, argv, opt_string, long_opts, &opt_index);
	while (opt != -1) {
		switch (opt) {
			case 'f':
				global_args.input_file_name = optarg;
				break;
			case 'd':
				global_args.output_dir = optarg;
				break;
			case 't':
				global_args.testing = 1;
				break;
			case 'v':
				global_args.verbosity++;
				break;
			case 'h':
			case '?':
				display_usage();
				break;
			default:
				break;
		}
		opt = getopt_long(argc, argv, opt_string, long_opts, &opt_index);
	}

	if (global_args.output_dir == NULL || global_args.input_file_name == NULL) {
		display_usage();
	}

	/* make directory of build files */
	if (mkdir(global_args.output_dir, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH) || (! EEXIST)) {
		fprintf(stderr, "%s: Can't create output directory %s\n",
			basename(argv[0]),
			global_args.output_dir);
		exit(EXIT_FAILURE);
	}

	LIBXML_TEST_VERSION

	doc = xmlReadFile(global_args.input_file_name, NULL, 0);
	if (doc == NULL) {
		fprintf(stderr, "%s: Failed to read index file...\n", basename(argv[0]));
		exit(EXIT_FAILURE);;
	}

	char *book_dir = dirname(global_args.input_file_name);

	root_element = xmlDocGetRootElement(doc);

	find_include(root_element, book_dir, global_args.output_dir);

	xmlFreeDoc(doc);
	xmlCleanupParser();

	exit(EXIT_SUCCESS);
}

void display_usage(void)
{
	printf(
"Usage: %s [OPTION]... INDEX_FILE DIST_DIR\n\n\
  -f, --input-file=FILE\n\
            input file\n\
  -d, --output-dir=DIR\n\
            output directory\n\
  -t, --include-testing\n\
            include testing phase\n\
  -v, --verbose\n\
            print a message for each parsed file\n\
  -h, -?, --help\n\
            display this help and exit\n", cmd_name);
	exit(EXIT_FAILURE);
}
