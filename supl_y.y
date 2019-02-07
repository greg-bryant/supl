%{

  // type update for current c compiler
  int yylex();
  void yyerror(const char *s);

  // function prototypes
  void add_file(unsigned char *);
  void serials_print(void);
  void traverse_and_print(void);
  void write_file_buffer(unsigned char *, unsigned char *);
  unsigned char *strip_filename(unsigned char *);

  // seems unecessary
  typedef unsigned char *charptr;

  // the source file (example.supl for now
  // should be an argument TODO)
  char source[10000000];
  int source_index = 0;

  // the output directory
  char directory_name[100];

  // storage for terminals (temporary until tree)
  #define LIMIT_ON_TERMINALS 1000

  // number of files declarable
  #define FILE_LIMIT 100

  // number of nodes a node can have
  // (anything bigger would be unreadable, no?)
  #define NODE_LIMIT 20

  #define LONG_STRING 100000

  // filenames in the supl source
  // build a dynamic list of strings for that
  unsigned char *file_list[FILE_LIMIT];
  FILE *fd_list[FILE_LIMIT];
  int file_index = 0; // for adding files to array

  #define FILE_BUFFER 100000
  unsigned char *file_buffers[FILE_LIMIT];

  // this is a reference to the file_list / fd_list
  unsigned char *terminals[LIMIT_ON_TERMINALS];
  int terminals_index = 0; // for adding terminals to array

  // a 'node' is a production (or parent) or child
  struct node {
    unsigned char *name;
    struct node *nodes[NODE_LIMIT]; // needs a malloc(sizeof tree)
    int number_of_nodes; // if 0 nodes, and has_text, it's a terminal
    unsigned char *responsible_file; // indexes file_list and fd_list
    int has_text; // default 0 TODO. 1 if text
    unsigned char *text; // if 0 and there's not has_text, ignore it.
    unsigned char *token;
    int step_number;
    int is_stripped;
    int not_a_quote;
    unsigned char *return_text; // to accomodate intermediate target_step traversal. 
  };
  typedef struct node node;

  // the root
  node *root = 0;

  #define YYSTYPE node

  //  function prototypes that use node
  node *get_nt_node(unsigned char *, node *);
  void tree_traverse(node *); 

  // not sure I'll use these
  unsigned char *current_p;
  node *current_p_node;

  //unsigned char *current_file;
  unsigned char *current_nt;
  node *current_nt_node;

  unsigned char *current_t;
  node *current_t_node;

  // the default step
  #define STEP_LIMIT 1000
  int target_step = STEP_LIMIT;

  // during parsing
  int current_step = 0; // real steps start at 1
%}

%start supl
%token NAME 
%token SEQUENCE STEP PRODUCTION NONTERMINAL TERMINAL
%token STRING TEMPLATE
%token QUOTE
%%

supl: statements
             {
		 traverse_and_print();
             }
             ;

statements: statement
             | statements statement
             ;

statement: STEP STRING STRING
            {
	       // this was to prevent $3 from being mistaken for a file. We ignore it instead.
	       // .step step_number 'fun step name'
               //if (!strcmp((const char *)$1.token,(const char *)".step")) {
                 // copy the step number (int the string at $2) into current_step
                 current_step = atoi((const char *)$2.token);
                 // then copy current_step into each p, nt, and t
                 // BUT NO FILE. UNDO the one done in string_list.
		 //}
	    }
statement: dot_keyword string_list quote_list
             {
	       //printf("\n %s : %s",$1.token,$2.token);
	       // .p ------------------------------------------------------------------------
               if (!strcmp((const char *)$1.token,(const char *)".p")) {
                 // start (the label) and root (the node)
                 if (!root) {
		   // we need this .p to be 'start'
                   if (!strcmp((const char *)$2.token,(const char *)"'start'")) { 
		     root = (node *) malloc(sizeof(node));
		     current_p = $2.token;
		     current_p_node = root;
                     current_p_node->return_text = (unsigned char *)malloc(LONG_STRING);
		     current_p_node->name = $2.token;
		     current_p_node->step_number = current_step;
		     
		     if ($2.responsible_file) {
		       current_p_node->responsible_file = $2.responsible_file;
		     }
                   } else {
                     // supl error
		     printf("sorry: the first production must be 'start'\n\n");
                     exit(1);
                   }
		 } else {
		   // if not 'start', find the '.nt' or '.t' that used this '.p'
		   //printf("\nAbout to get_nt_node!!!");		   
		   node *return_node = get_nt_node($2.token,root);
		   //printf("\nRETURNED!!!");
		   if (!return_node) {
		     // supl error
		     printf("sorry: no .nt use found for production %s'\n",$2.token);
		     printf("an identifier must be used before it is defined\n");
		     printf("that's the nature of deductive directed graphs\n");
		     exit(1);
		   }
		   //printf("\nRETURNED 2!!!");
		   current_p_node = return_node;
		   //printf("\nRETURNED 2.1 ");
		   current_p = $2.token; // I've already alloc'd lval
		   //printf("\nRETURNED 2.2 ");
		   if ($2.responsible_file) {
		     //printf("\nRETURNED 2.3 ");
		     current_p_node->responsible_file = $2.responsible_file;
		     //printf("\nRETURNED 2.4 ");
		   }
		   //printf("\nRETURNED 2.5 ");
		   //printf("\nRETURNED 2.6 \n");
		   //printf("\nRETURNED 2.7 \n");

		   //printf("\nRETURNED 3 \n");
		 }
	       }
	       // -------------------------------------------------------------------------
	       //
	       // .nt ---------------------------------------------------------------------
	       //printf("\nRETURNED 4 \n");
               if (!strcmp((const char *)$1.token,(const char *)".nt")) {
		 // I know it's strange, but in a deductive tree declaration
		 // like a context-free grammar, the definition happens after
		 // the use.
                 current_nt = $2.token;
                 current_nt_node = (node *) malloc(sizeof(node));
                 current_nt_node->return_text = (unsigned char *)malloc(LONG_STRING);
		 current_nt_node->name = $2.token;
		 current_nt_node->step_number = current_step;
		 if (!$3.not_a_quote) {
		   current_nt_node->text = $3.text;
		 }


		 if ($2.responsible_file) {
		   //printf("\nresponsible file found %s\n",$2.responsible_file);
		   current_nt_node->responsible_file = $2.responsible_file;
		 } else {
		   current_nt_node->responsible_file = current_p_node->responsible_file;
		 }

		 // now add this to the current .p
		 current_p_node->nodes[current_p_node->number_of_nodes] = current_nt_node;
		 current_p_node->number_of_nodes++;
	       }
	       //printf("\nRETURNED 5 \n");

	       // -------------------------------------------------------------------------
	       //
	       // .t ---------------------------------------------------------------
               if (!strcmp((const char *)$1.token,(const char *)".t")) {

                 current_t = $2.token;
                 current_t_node = (node *) malloc(sizeof(node));
		 current_t_node->name = $2.token;
		 if (!$3.not_a_quote) {
		   current_t_node->text = $3.text;
		 }
                 current_t_node->return_text = (unsigned char *)malloc(LONG_STRING);

		 if ($2.responsible_file) {
		   current_t_node->responsible_file = $2.responsible_file;
		 } else {
		   current_t_node->responsible_file = current_p_node->responsible_file;
		 }
		 current_t_node->step_number = current_step;


		 // now add this to the current .p
		 current_p_node->nodes[current_p_node->number_of_nodes] = current_t_node;
		 current_p_node->number_of_nodes++;

	       }
	       // -------------------------------------------------------------------------
	     
            }
            ;

dot_keyword: SEQUENCE | PRODUCTION | NONTERMINAL | TERMINAL
             ;

string_list: STRING STRING
             {
	       unsigned char *new_file;
	       new_file = strip_filename($2.token);

	       // NO NO NO NOT FOR .STEPS! ONLY FOR anything else. FIX TODO.
	       add_file(new_file);
	       $$.responsible_file = new_file;
               $$.token = $1.token;
             } 
             | STRING
             {
               $$ = $1; 
             }
             ;
quote_list:  /* nothing */ 
             {
	       // malloc a node, set the 'not_a_quote' flag. Return.
	       node *empty_quote;
	       empty_quote = (node *) malloc(sizeof(node));
	       empty_quote->not_a_quote = 1;
	       $$ = *empty_quote;
             }
            | QUOTE
            {
	      // unset the 'not_a_quote' flag. return node from lex.
	      $1.not_a_quote = 0;
	      $$ = $1;
            }
	    ;

%%

#include "supl_l.c"
void yyerror()
{
  printf("Problem with supl file.\n");
  printf("Syntax error on line %d:  %s.  Exiting\n",yylineno,yytext);
}

void add_file(unsigned char *filename)
{
  file_list[file_index]= filename;
  file_buffers[file_index] = (unsigned char *)malloc(FILE_BUFFER);
  file_index++;
}

/* pull the quotes off this string */
unsigned char *strip_filename(unsigned char *filename) {
  unsigned char *stripped;
  int copy_len = 0;

  copy_len = strlen((const char *)filename)-2;
  stripped = (unsigned char *)strncpy(malloc(copy_len+1),(const char *)&filename[1],copy_len);
  stripped[copy_len] = '\0';

  return stripped;
}

// I have a production. I need to traverse the tree and find the 
// node that matches it. 0 if none found, which would be an error
// in that context.
node *get_nt_node(unsigned char *p_name, node *start_node) {

  int i;
  node *return_node = 0;

  //printf("\n ---- >get_nt_node");
  for (i=0; i<start_node->number_of_nodes; i++) {
    //printf("\n  loop: get_nt_node. i: %d, start_node->number_of_nodes: %d",
    //          i,start_node->number_of_nodes);
       // compare 'name' to 'p_name'
       if (!strcmp((const char *)start_node->nodes[i]->name,(const char *)p_name)) {
          // found it? return it!
          return_node = start_node->nodes[i];
	  //    printf("\n <------ returning 1");
          return return_node;
       } else {
	 // otherwise traverse its nodes
         return_node =  get_nt_node(p_name,start_node->nodes[i]); 
         if (return_node) {
           // found it!
           //printf("\n <------ returning 2");
	   return return_node;
	 }
       }
  }
  // nothing found ... return 0
  //printf("\n <------ returning 3");
  return return_node;
}


// recurse / traverse the tree. build the files. print the files.
void traverse_and_print(void) 
{
  printf("\n about to traverse \n");
  tree_traverse(root);
  printf("\n about to print \n");
  serials_print();
}

// build the serial file structures through a recursive
// depth-first left-right traversal of the node tree
// from root. return_text is our workspace.
void tree_traverse(node *t_node) 
{
  //printf("\n---> tree_traverse %s\n",(char *)t_node->return_text);
  // root's return_text pointer is NULL! FIX!! TODO!

  // new traversal
  //strcpy((char *)t_node->return_text,"");
  t_node->return_text[0] = '\0';
  //printf("\n      tree_traverse 2\n");

  // first, if we're past the target_step, return nothing
  // don't care about the children
  // we'll need to do this in both recursive routines
  //printf("t_node->step_number: %d, target_step: %d\n",t_node->step_number,target_step);
  if (t_node->step_number > target_step) {
    //printf("\n <-- RETURN tree_traverse 1\n");

    return;
  }

  //printf("\n      tree_traverse 3, t_node %d, %d\n",
  // (int)t_node,t_node->number_of_nodes);

  // call the children
  int i;
  for (i=0;i<t_node->number_of_nodes;i++) {
    //printf("\n loop: tree_traverse %d\n",i);

    tree_traverse(t_node->nodes[i]);

    if (strlen((const char *)t_node->nodes[i]->return_text)) {
      strcat((char *)t_node->return_text,(char *)t_node->nodes[i]->return_text);
    }
  }

  //printf("\n      tree_traverse 4\n");
  //printf("\n  t_node->return_text: %s, t_node->text %s\n",
  //	   t_node->return_text,t_node->text);
  
  // if there was no step-appropriate child text, 
  if (!strlen((const char *)t_node->return_text)) { 
    // and you have text
    if (t_node->text) {
      // write it out
      write_file_buffer(t_node->text,t_node->responsible_file);
      // return it
      strcat((char *)t_node->return_text,(char *)t_node->text);      
    } 
  } 

  //printf("\n      tree_traverse 5\n");

  // the step-leaf children write out their own text. 
  // we return_text so their parents don't
 

  /*
  // is there text here?
  // yes, write it into the buffer for this file, return
  if (t_node->text) {
    // the STEP you're on is very important here.
    //if (t_node->step_number <= target_step) {
      // write into result_text, not the buffer. result_text
      write_file_buffer(t_node->text,t_node->responsible_file);
    //}
  } else {
    // no, call tree_traverse on the child nodes, return when they return
    int i;
    for (i=0;i<t_node->number_of_nodes;i++) {
      tree_traverse(t_node->nodes[i]);
    }
  }
  */
  //printf("\n <-- return tree_traverse 2\n");

}

// file_buffers
void write_file_buffer(unsigned char *text, unsigned char *filename)
{

  int i;
  for (i=0;i<file_index;i++) {
    if (!strcmp((const char *)file_list[i],(const char *)filename)) {
      break;
    }
  }
  if (i == file_index) {
    printf("error: filename %s not found in file index\n",filename);
    exit(1);
  }
  strcat((char *)file_buffers[i],(const char *)text);
}

void serials_print(void)
{
  int i = 0;
  int j = 0;
  FILE *fp;
  char path[100];

  printf("generating %d files\n",file_index);
  // 21!! FAR too many. FIX TODO

  for (i=0;i<file_index;i++) {
    printf("\n serials print loop: %d \n",i);
    sprintf(path,"./%s/%s",directory_name,file_list[i]);

    fp = fopen(path,"w");
    if (!fp) {
      printf("fopen failed, did you make the folder? errno = %d\n", errno);
    } else {
      printf("fopen succeeded\n");
    }
    printf("\nFile: %s\n",path);
    //printf("\n serials print buffer %d ... \n",
    //   (int)strlen((const char *)file_buffers[i]));
    //printf("\n the buffer: \n  ... %s ... \n",
    //   (const char *)file_buffers[i]);

    fprintf(fp,"%s",(const char *)file_buffers[i]);
    printf("\n about to close \n");
    fclose(fp);
  }
}

  /* A different kind of "TODO": development questions that need answering!
     ... kind of like me asking specific 'how are you going to do x,y,z?' questions.

     So, where:
     a) do I write the first non-terminal?
        the '.P' or 'production' (or 'parent'?) labeled 'start'
        (done) you need to make the llval a node struct 
        (done) make the 'start' node the root this file's action for the 'dot_keyword' production.
        (done) and if there's no start node as the first production, it's an error. 
               done in the same action
     b) do I write the nodes of an nt?
        (done) when a p is read, find the original nt that it referes to (get_nt__node).
        (done) and use that node as the current_p_node
        (done) create the nt node and add it to the current_p_node.
     c) How are the files determined?
        (done) at p (through declaration or search), nt/t (declaration or inheritance)
     d) do I record the terminal names and strings?
        (done) yes, they're in the nodes
     e) do I traverse all this and print the files?
        (done) absolutely: depth-first, left-right.
     f) do the files get written?
        (done) currently written out on standard io.
	(done) did tests and eliminated debug printfs
        (done) wrote out files
     g) does the "step" parameter get written?
     * the default is all the way through the sequence
     (done) only the number in .step matters. return as string parameter.
     (done) add a 'step_number' to the node structure
     (done) make sure quote gets stored for nt as well as t. yes. in any node's 'text'.
     * make sure that the earlier texts get replaced by the later texts. We WERE assuming
       leaves only!
     X or you might be able to use the same .t at different steps?
     *  maybe it's best to save t for the really terminating terminal.
         there's nothing wrong with a series of .nt's with quotes in a straight line.
         and we might find some interesting differentiation.
     * add command line parameter for step
     * generate results based on parameter.
     * it seems like you also need a 'generate all' parameter, which
       generates all end-to-end code in 1/ 2/ directories etc. for testing
     * do 'steps' help with inventorying & meaning & intention, hence with testing? 
     * maybe tests would make more sense matched with steps than with objects?
  */

  /*
    the TODO I didn't finish using, annotated:
    x. Add to the example. You need multiple files with multiple terminals.
       yes, but this changed with the .file directive changed.
    x. removed pmore and expanded the identifiers.
       yes, pmore was a confusing namespace gadget. i'm more sensitive than i was 10 years ago.
    x. left the 'template' keyword. modify lex, add a state, and use the quote mechanism.
    x. changed my mind. getting rid of template.
    x. I need to not reconize tokens
    X. while in << >> quotes (where you need to save everything as text)
    X. while in 'comment areas' (you can throw everything away) 
    1. you'll have to make sure the "file" declarations are complete ... that is,
       you can always trace a ".t" back to a ".file" ...
       and issue an error if that's not true. So, the struct needs to have the
       "responsible file".
       true .. but now we put files on any directive line. it's clearer.
    2. Get multiple files and multiple terminals to work.
       done
    3. Add sequences and steps.
       done, but they're placebos.
    4. Consruct sequence / step / non-terminal / terminal "tree".
       done
    5. traverse the tree and print the files 
       (eventually, just generate them to step X from the command line). nice idea. TODO
    6. issue a warning for duplicate 'p' strings  'nt' strings. I'm not sure 't' mattters,
       since it's always a template under a P, whereas P and NT names are global. 
       Good idea. TODO
    7. is there a simpler solution than P, NT, T? Like, node and leaf?
       .p start 
       .nt node1 
       .nt node2
       .t leaf1
  */
 
  /*
-->> GOOD IDEA: you could also allow nt's to have temporary 
definitions that get replaced at the .t, so the step could have
"printf" kinds of stubs. Could happen at each intermediate stage. 
No identifying connecting pieces is necessary, because, if they're
important, you can always make a new stub .nt. 
Kind of automatically makes a demonstration animation. TODO

   */

/* this is a high-level description of 
   program unfolding through rewriting rules.

   The point, from a cognitive psychological research point of view,
   is that we need to identify WHAT concepts are used in programming,
   both on reading a program, considering meeting a goal, evaluating
   a solution, making a transition, etc...
   ... so we need to watch the concepts in use, before we can further 
   test the meaning that they provide to people who program. We can't
   make reasonable assumptions about these, since they are so complex,
   really at the edge of what you can accomplish within the natural 
   sciences.

   Through generation, we're trying to avoid "logical fanout" in code.
   That's when code is patched and refactored endlessly without consideration
   of the overall structure of the application, which is most easily
   understood and seen as the unfolding structure of the application.
*/
