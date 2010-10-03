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

void find_userinput_tmp_sys(xmlNode *a_node, FILE *fd);
void find_userinput_sys(xmlNode *a_node, FILE *fd);

enum SYS_TYPE { TMP_SYS, SYS } sys_type;

void
find_addr_or_scrn_sys(xmlNode *a_node, FILE *fd)
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
				fprintf(fd, "unpack %s\n\n", content);
				xmlFree(content);
			} else if (!xmlStrcmp(cur_node->name, (const xmlChar *)"screen")) {
				attr = xmlGetProp(cur_node, (const xmlChar *)"role");
				if (attr && !xmlStrcmp(attr, (const xmlChar *)"nodump")) {
					xmlFree(attr);
					attr = NULL;
					continue;
				}
				find_userinput_sys(cur_node->children, fd);
				xmlFree(attr);
				attr = NULL;
			}
		}
		find_addr_or_scrn_sys(cur_node->children, fd);
	}
}

void
find_userinput_sys(xmlNode *a_node, FILE *fd)
{
	xmlNode *cur_node = NULL;
	xmlChar *content = NULL;
	xmlChar *attr = NULL;

	for (cur_node = a_node; cur_node; cur_node = cur_node->next) {
		if (cur_node->type == XML_ENTITY_REF_NODE)
			return;
		if (cur_node->type == XML_ELEMENT_NODE) {
			if (!xmlStrcmp(cur_node->name, (const xmlChar *)"userinput")) {
				attr = xmlGetProp(cur_node, (const xmlChar *)"remap");
				if (!xmlStrcmp(attr, (const xmlChar *)"pre")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "%s\n", content);
				} else if (!xmlStrcmp(attr, (const xmlChar *)"configure")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "%s\n", content);
				} else if (!xmlStrcmp(attr, (const xmlChar *)"make")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "%s\n", content);
				} else if (!xmlStrcmp(attr, (const xmlChar *)"install")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "%s\n", content);
				} else if (!xmlStrcmp(attr, (const xmlChar *)"locale-full")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "%s\n", content);
				} else {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "%s\n", content);
				}
				xmlFree(content);
				xmlFree(attr);
			}
		}
	}
}

void
find_scrn_or_adr_tmp_sys(xmlNode *a_node, FILE *fd)
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
				find_userinput_tmp_sys(cur_node->children, fd);
				xmlFree(attr);
				attr = NULL;
			}
		}
		find_scrn_or_adr_tmp_sys(cur_node->children, fd);
	}
}

void
find_userinput_tmp_sys(xmlNode *a_node, FILE *fd)
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
				if (!xmlStrcmp(remap, (const xmlChar *)"pre")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "\ntail -f \"$PRE_LOG\" &\n");
					fprintf(fd, "PID=`ps u | grep \"tail -f $PRE_LOG\" | grep -v \"grep\" | cut -d' ' -f2`\n");
					fprintf(fd, "exec  1>> \"$PRE_LOG\"\n");
					fprintf(fd, "exec  2>> \"$PRE_LOG\"\n");
					fprintf(fd, "%s\n", content);
					/*fprintf(fd, "echo \"kill $PID\"\n");*/
					fprintf(fd, "kill \"$PID\"\n");
					fprintf(fd, "exec 1>&7\n");
					fprintf(fd, "exec 8>&2\n");
				} else if (!xmlStrcmp(remap, (const xmlChar *)"configure")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "\ntail -f \"$CONF_LOG\" &\n");
					fprintf(fd, "PID=`ps u | grep \"tail -f $CONF_LOG\" | grep -v \"grep\" | cut -d' ' -f2`\n");
					fprintf(fd, "exec 1>> \"$CONF_LOG\"\n");
					fprintf(fd, "exec 2>> \"$CONF_LOG\"\n");
					fprintf(fd, "%s\n", content);
					/*fprintf(fd, "echo \"kill $PID\"\n");*/
					fprintf(fd, "kill \"$PID\"\n");
					fprintf(fd, "exec 1>&7\n");
					fprintf(fd, "exec 8>&2\n");
				} else if (!xmlStrcmp(remap, (const xmlChar *)"make")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "\ntail -f \"$MAKE_LOG\" &\n");
					fprintf(fd, "PID=`ps u | grep \"tail -f $MAKE_LOG\" | grep -v \"grep\" | cut -d' ' -f2`\n");
					fprintf(fd, "exec 1>> \"$MAKE_LOG\"\n");
					fprintf(fd, "exec 2>> \"$MAKE_LOG\"\n");
					fprintf(fd, "%s\n", content);
					/*fprintf(fd, "echo \"kill $PID\"\n");*/
					fprintf(fd, "kill \"$PID\"\n");
					fprintf(fd, "exec 1>&7\n");
					fprintf(fd, "exec 8>&2\n");
				} else if (!xmlStrcmp(remap, (const xmlChar *)"install")) {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "\ntail -f \"$INST_LOG\" &\n");
					fprintf(fd, "PID=`ps u | grep \"tail -f $INST_LOG\" | grep -v \"grep\" | cut -d' ' -f2`\n");
					fprintf(fd, "exec 1>> \"$INST_LOG\"\n");
					fprintf(fd, "exec 2>> \"$INST_LOG\"\n");
					fprintf(fd, "%s\n", content);
					/*fprintf(fd, "echo \"kill $PID\"\n");*/
					fprintf(fd, "kill \"$PID\"\n");
					fprintf(fd, "exec 1>&7\n");
					fprintf(fd, "exec 8>&2\n");
				} else if (!xmlStrcmp(remap, (const xmlChar *)"test")) {
					/*fprintf(fd, "\nexec 1>> \"$TEST_LOG\"\n");*/
					/*fprintf(fd, "exec 2>> \"$TEST_LOG\"\n");*/
					fprintf(fd, "#test skipped\n\n");
					/*fprintf(fd, "exec 1>&7\n");*/
					/*fprintf(fd, "exec 8>&2\n");*/
				} else {
					content = xmlNodeGetContent(cur_node);
					fprintf(fd, "\ntail -f \"$LOG\" &\n");
					fprintf(fd, "PID=`ps u | grep \"tail -f $LOG\" | grep -v \"grep\" | cut -d' ' -f2`\n");
					fprintf(fd, "exec 1>> \"$LOG\"\n");
					fprintf(fd, "exec 2>> \"$LOG\"\n");
					fprintf(fd, "%s\n", content);
					/*fprintf(fd, "echo \"kill $PID\"\n");*/
					fprintf(fd, "kill \"$PID\"\n");
					fprintf(fd, "exec 1>&7\n");
					fprintf(fd, "exec 8>&2\n");
				}
				xmlFree(content);
			}
		}
	}
}

int
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
	
	if (sys_type == TMP_SYS) {
		find_scrn_or_adr_tmp_sys(root_element, fd);
	} else {
		find_addr_or_scrn_sys(root_element, fd);
	}

	xmlFreeDoc(doc);
	xmlCleanupParser();

	return 0;
}

void
find_include(xmlNode *a_node, char *book_dir, char *build_dir)
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
				printf("\e[40m\e[1;37m --- \e[1;32mParsing \e[1;37m%s --- \e[m \n", href);

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
				fprintf(fd, "exec 7>&1\n");
				fprintf(fd, "exec 8>&2\n\n");
				build_script(filename, fd);
				fprintf(fd, "exec 1>&7\n");
				fprintf(fd, "exec 8>&2\n");
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
	
	if (argc != 4) {
		fprintf(stderr, "Usage: %s FILE DIST_DIR SYS_TYPE\n", argv[0]);
		return 1;
	}
	
	/* make directory of build files */
	if (mkdir(argv[2], S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH) || (! EEXIST)) {
		fprintf(stderr, "%s: Can't create directory %s\n", argv[0], argv[2]);
		return 1;
	}
	
	switch (*argv[3]) {
		case 't':
			sys_type = TMP_SYS;
			break;
		case 's':
			sys_type = SYS;
			break;
		default:
			fprintf(stderr, "Could not recognize SYS_TYPE!\n");
			return 1;
	}
	

	LIBXML_TEST_VERSION

	doc = xmlReadFile(argv[1], NULL, 0);
	if (doc == NULL) {
		fprintf(stderr, "%s: Failed to create reader...\n", argv[0]);
		return 1;
	}

	char *book_dir = dirname(argv[1]);

	root_element = xmlDocGetRootElement(doc);
	
	find_include(root_element, book_dir, argv[2]);

	xmlFreeDoc(doc);
	xmlCleanupParser();

	return 0;
}
