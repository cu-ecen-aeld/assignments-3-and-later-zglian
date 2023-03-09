#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#define LOG_FACILITY LOG_USER

int main(int argc, char *argv[]) {
  if (argc != 3) {
    fprintf(stderr, "Usage: %s <writefile> <writestr>\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  const char *writefile = argv[1];
  const char *writestr = argv[2];

  FILE *fp = fopen(writefile, "w");
  if (!fp) {
    syslog(LOG_ERR, "Failed to create file %s: %m", writefile);
    perror("Error");
    exit(EXIT_FAILURE);
  }

  fprintf(fp, "%s", writestr);
  fclose(fp);

  syslog(LOG_DEBUG, "Writing '%s' to '%s'", writestr, writefile);

  exit(EXIT_SUCCESS);
}
