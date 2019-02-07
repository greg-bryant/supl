%{
/* supl_l.l 
  tokenizer for the smoothly unfolding project language
*/

int quote_on = 0;
int comment_on = 1;

unsigned char quote_buffer[10000];
int quote_index = 0;

#if 0
#define my_DEBUG_1 1
#endif

int my_getc();
int qcas(char);

#undef output
#undef input
#define output(c)
#define YY_INPUT(buf,result,max_size) \
         { \
         int c = my_getc(); \
         result = (c == EOF) ? YY_NULL : (buf[0] = c, 1); \
         }
#if 0
#define input() (\
		 (\
		  (\
		   yytchar=\
		   yysptr>yysbuf?\
		   U(*--yysptr)\
		   :my_getc()\
		   ) == 10?\
		     (yylineno++,yytchar)\
		     :yytchar\
		     ) == (unsigned char)EOF?\
		       0\
		       :yytchar\
)
#endif

/* The following passes up the strings as the value for the token */
#define LMV yylval.token=(charptr)strcpy(malloc(strlen(yytext)+1),yytext)

%}
%option yylineno
%%
^"."[sS][eE][qQ][uU][eE][nN][cC][eE]    {
                             comment_on = 0;
                             LMV; 
                             //printf("SEQUENCE\n");
                             return SEQUENCE; 
                           }
^"."[sS][tT][eE][pP]       {
                             comment_on = 0;
                             LMV; 
                             //printf("STEP\n");
                             return STEP; 
                           }
^"."[pP]                   {
                             comment_on = 0;
                             LMV; 
                             //printf("PRODUCTION\n");
                             return PRODUCTION; 
                           }
^"."[nN][tT]               {
                             comment_on = 0;
                             LMV; 
                             //printf("NONTERMINAL\n");
                             return NONTERMINAL; 
                           }
^"."[tT]                   {
                             comment_on = 0;
                             LMV; 
                             //printf("TERMINAL\n");
                             return TERMINAL; 
                           }
^"<<<"                     {
                             comment_on = 0;
                             quote_on = 1;
                             // start quote (template)
                             //printf("<<\n");
                             /* everything from here forward to the close
                                quote needs to be written onto "quote_store"
                                which gets moved onto the stack and returned to yacc
                                as quote */
                           }
^">>>"                     {
                             comment_on = 1;
                             // end quote (template)
                             //printf(">>\n");
                             quote_on = 0;
                             quote_buffer[quote_index] = '\0';
                             quote_index = 0;
                             // terminal_file[terminals_index] = file_list[file_index-1];
                             int qb = strlen((const char *)quote_buffer);

                             //printf("quote_buffer length: %d\n",qb);
                             //printf("quote_buffer : %s\n",quote_buffer);
                             //printf("terminals index: %d\n",terminals_index);
                             
                             // just temporary. needs to be done during traversal. TODO
                             // terminal_file[terminals_index] = 0;

                             terminals[terminals_index++] =
                                  (charptr) strcpy(malloc(qb+1),(const char *)quote_buffer);
                            
                             /*
                             printf("--> %d \n--> %s <---\n ",
				    terminals_index - 1,
				    terminals[terminals_index - 1]);
                             */
                             // Instead of a token, add it to the curren .t
                             // or put it in the 
                             // TODO
                             yylval.text = terminals[terminals_index - 1];
                             return QUOTE;
                           }
"'"[^\n']+"'"              {
                             /* I need to make sure that this (and everything else)
                                gets written to the quote store when in that state.
                                Alternatively, I can strip out and store the quotes
                                and replace them with a label like <<<< quote_store_1 >>>>
                              */

                             if (quote_on) {
                               int qi = 0;
                               int ql = 0;
                               ql = strlen(yytext);
                               for (qi = 0; qi < ql; qi++) {
                                 qcas(yytext[qi]);
                               }
                             } else {
                               if (comment_on == 0) {
                                LMV; 
                                //printf("STRING\n");
                                return STRING; 
                               }
                             }
                           }
":"                        {
                             qcas(yytext[0]);
                             //printf("COLON\n");
                             //printf( "colon %s", yytext );
                             //just dump it for now
                           }
\n                         {
                             if (comment_on == 0) comment_on = 1;
                             qcas(yytext[0]);
                           }
[0-9]+                     {
                             // if not in a quote
                             if (!qcas(yytext[0])) {
                               // and not in a comment
                               if (!comment_on) {
                                // this is a number parameter
                                LMV;
                                yylval.is_stripped = 1;                                
                                return STRING; 
                               }
                             } 
                           } 
.                          {
                             qcas(yytext[0]);
                           }
%%
yywrap() {
  //quote_buffer[quote_index] = '\0';
  //printf("quotes: %d %s\n",quote_index,quote_buffer);
  return 1;
}


int my_getc()
{
  int c;

  c = source[source_index];

  if (c == 0)
    c = EOF;
  else
    source_index++;

  return c;
}

/* quote check and store */
int qcas(char x)
{
   if (quote_on) {
     quote_buffer[quote_index++] = x;
     return 1;
   } else {
     return 0;
   }
}
