/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int nested_flag = 0;
bool string_too_long;
bool string_has_null;
bool string_overflow();

%}

%option noyywrap
%x COMMENT STRING

/*
 * Define names for regular expressions here.
 */

DARROW          =>
LEQUAL          <=
ASSIGN          <-

a               [aA]
b               [bB]
c               [cC]
d               [dD]
e               [eE]
f               [fF]
g               [gG]
h               [hH]
i               [iI]
j               [jJ]
k               [kK]
l               [lL]
m               [mM]
n               [nN]
o               [oO]
p               [pP]
q               [qQ]
r               [rR]
s               [sS]
t               [tT]
u               [uU]
v               [vV]
w               [wW]
x               [xX]
y               [yY]
z               [zZ]

INTEGER         [0-9]+
CHARACTER       [-(){}<=;,+*/~:@\.]
SPACE           [ \n\f\r\t\v]
TYPE            [A-Z][a-zA-Z0-9_]*
OBJECT          [a-z][a-zA-Z0-9_]*

%%

 /*
  *  Comments
  */
--.*    {}


 /*
  *  Nested comments
  */
"(*"                { nested_flag++; BEGIN(COMMENT); }
<COMMENT>"(*"       { nested_flag++; }
<COMMENT>"*)"       { 
                      nested_flag--;
                      if (!nested_flag)
                        BEGIN(INITIAL);
                    }
<COMMENT>.          {}
<COMMENT>[\n]       { curr_lineno++; }
<COMMENT><<EOF>>    { 
                      BEGIN(INITIAL);
                      cool_yylval.error_msg = "EOF in comment";
                      return (ERROR);
                    }
"*)"                { cool_yylval.error_msg = "Unmatched *)"; return (ERROR); }                    


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{LEQUAL}		{ return (LE); }
{ASSIGN}		{ return (ASSIGN); }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{c}{l}{a}{s}{s}             { return (CLASS); }
{e}{l}{s}{e}                { return (ELSE); }
{i}{f}                      { return (IF); }
{f}{i}                      { return (FI); }
{i}{n}                      { return (IN); }
{i}{n}{h}{e}{r}{i}{t}{s}    { return (INHERITS); }
{i}{s}{v}{o}{i}{d}          { return (ISVOID); }
{l}{e}{t}                   { return (LET); }
{l}{o}{o}{p}                { return (LOOP); }
{p}{o}{o}{l}                { return (POOL); }
{t}{h}{e}{n}                { return (THEN); }
{w}{h}{i}{l}{e}             { return (WHILE); }
{c}{a}{s}{e}                { return (CASE); }
{e}{s}{a}{c}                { return (ESAC); }
{n}{e}{w}                   { return (NEW); }
{o}{f}                      { return (OF); }
{n}{o}{t}                   { return (NOT); }
t{r}{u}{e}                  { cool_yylval.boolean = true; return (BOOL_CONST); }
f{a}{l}{s}{e}               { cool_yylval.boolean = false; return (BOOL_CONST); }


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\"                  {
                      string_buf_ptr = string_buf;
                      string_too_long = false;
                      string_has_null = false;
                      BEGIN(STRING);  
                    }
<STRING>\"          { 
                      BEGIN(INITIAL);

                      if (string_has_null) {
                        cool_yylval.error_msg = "String contains null character";
                        return (ERROR);
                      }
                      
                      if (string_too_long) {
                        cool_yylval.error_msg = "String constant too long";
                        return (ERROR);
                      }
                      
                      *string_buf_ptr = '\0'; 
                      cool_yylval.symbol = stringtable.add_string(string_buf); 
                      return (STR_CONST);
                    }
<STRING>\\.         { 
                      if (yytext[1] == '\0') {                                /* "\\\0" -> '\0'(null, illegal) */
                        string_has_null = true;
                      } else if (!string_too_long) {
                        if (string_overflow()) {
                          string_too_long = true;
                        } else {
                          switch (yytext[1]) {
                            case 'b': *string_buf_ptr = '\b'; break;
                            case 't': *string_buf_ptr = '\t'; break;
                            case 'n': *string_buf_ptr = '\n'; break;          /* "\\n" -> '\n'(character) */
                            case 'f': *string_buf_ptr = '\f'; break;
                            default:  *string_buf_ptr = yytext[1]; break;     /* "\\0" -> '0'(character) */
                          }
                          string_buf_ptr++;
                        }
                      }
                    }
<STRING>\\\n        {                                                         /* "\\\n" -> '\n'(nextline, legal) */
                      curr_lineno++;
                      if (!string_too_long) {
                        if (string_overflow())
                          string_too_long = true;
                        else
                          *string_buf_ptr++ = '\n';
                      }
                    }
<STRING>\n          {                                                         /* "\n" -> '\n'(nextline, illegal) */
                      curr_lineno++;
                      BEGIN(INITIAL);
                      cool_yylval.error_msg = "Unterminated string constant";
                      return (ERROR);
                    }
<STRING>.           { 
                      if (yytext[0] == '\0') {
                        string_has_null = true;
                      } else if (!string_too_long) {
                        if (string_overflow())
                          string_too_long = true;
                        else
                          *string_buf_ptr++ = yytext[0];
                      }
                    }
<STRING><<EOF>>     {
                      BEGIN(INITIAL);
                      cool_yylval.error_msg = "EOF in string constant";
                      return (ERROR);
                    }


 /*
  *  Integer constants
  */
{INTEGER}      { cool_yylval.symbol = inttable.add_string(yytext); return (INT_CONST); }


 /*
  *  Single character tokens
  */
{CHARACTER}    { return yytext[0]; }


 /*
  *  White space characters
  */
{SPACE}        { if (yytext[0] == '\n') curr_lineno++; }


 /*
  *  Type Identifier
  */
{TYPE}         { cool_yylval.symbol = stringtable.add_string(yytext); return (TYPEID); }


 /*
  *  Object Identifier
  */
{OBJECT}       { cool_yylval.symbol = stringtable.add_string(yytext); return (OBJECTID); }


 /*
  *  Illegal character
  */
.              { cool_yylval.error_msg = yytext; return (ERROR); }


%%

bool string_overflow() {
  return string_buf_ptr - string_buf + 1 >= MAX_STR_CONST;
}