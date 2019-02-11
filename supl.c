#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <sys/types.h>
#include <sys/stat.h>

#include "supl_y.c"

int main (int argc, char *argv[])
{

  /*
  int test_1 = 0;
  int test_2 = 0;
  int test_3 = 0;
  */
  struct stat info;
  char pathname[100];
  int status = 0;

  extern char source[10000000];
  extern int source_index;
  extern char directory_name[100];


  FILE *file_fd;
  char file_name[100];
  char buf[50000];
  int i;

  //printf("starting ...\n");

  // source file (optional, default "example.supl")
  if (argc > 1) {
    strcpy (file_name,argv[1]);
  } else {
    strcpy (file_name,"example.supl");
  }

  // output directory (optional. Default "supl_output". Creates it.)
  if (argc > 2) {
    strcpy (directory_name,argv[2]);
  } else {
    strcpy (directory_name,"supl_output");
  }

  sprintf(pathname,"./%s",directory_name);
  status = stat( pathname, &info );
  if( status ) {
    // make the directory (rwx user)
    status = mkdir(pathname, S_IRWXU);
    if (status) {
      printf("could not create directory\n exiting ...\n");
      exit(1);
    }
  }
  /*
  printf("0 = %s\n",argv[0]);
  printf("1 = %s\n",argv[1]);
  printf("2 = %s\n",argv[2]);
  printf("3 = %s\n",argv[3]);
  */

  // step (optional, default STEP_LIMIT)
  if (argc > 3) {
    target_step = atoi(argv[3]);
  }

  //printf("target step = %d\n",target_step);

  if ((file_fd = fopen (file_name,"r")) == NULL) {
    printf ( "ERROR : Could not open file.\n");
    exit(1);
  }

  source[0] = '\0';
  fseek (file_fd,0,0);
  while (fgets(buf,1000,file_fd)) strcat(source,buf);
  fclose (file_fd);

  /*
  result: YES all the linefeeds are in the source array.
  test_2 = strlen(source);
  printf("source length %d\n",test_2);
  test_3 = 0;
  for (test_1 = 0; test_1 < test_2; test_1++) {
    if (source[test_1] == '\n') test_3++;
  }
  printf("counted linefeeds %d\n",test_3);
  */

  yyparse();

  exit(0);
}

