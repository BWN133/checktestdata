%{
    #define _SKIP_YYFLEXLEXER_
    #include "scanner.h"
    #include "parser.h"

	#include <string>
%}

%option yyclass="Scanner" outfile="yylex.cc"
%option c++ 8bit warn noyywrap yylineno

	/* start condition for strings */
	std::string str_buf;

%x string

%%

SPACE    { return Parser::CMD_SPACE; }
NEWLINE  { return Parser::CMD_NEWLINE; }
EOF      { return Parser::CMD_EOF; }
INT      { return Parser::CMD_INT; }
STRING   { return Parser::CMD_STRING; }
REGEX    { return Parser::CMD_REGEX; }
REP      { return Parser::CMD_REP; }
END      { return Parser::CMD_END; }

[a-z][a-z0-9]* {
	return Parser::VARIABLE;
}

0|-?[1-9][0-9]* {
	return Parser::INTEGER;
}

 /* String parsing -- adapted from the flex manual page */

\"	{
    /* start of string */
    str_buf.clear();
    BEGIN(string);
}

<string>{
\"	{
    /* end of string */
    BEGIN(INITIAL);
	yytext = strdup(str_buf.c_str());
    return Parser::STRING;
}

\n	{
    /* error: unterminated string constant */
}

\\[0-7]{1,3} {
    /* octal escape sequence */
    int result;

    (void) sscanf(yytext+1,"%o",&result);

    /* should check for bounds of escape sequence: result < 256 */
    str_buf += (char) result;
}

\\[0-9]+ {
    /* error: bad escape sequence */
}

\\n         str_buf += '\n';
\\t         str_buf += '\t';
\\r         str_buf += '\r';
\\b         str_buf += '\b';
\\f         str_buf += '\f';
\\(.|\n)	str_buf += yytext[1];
[^\\\n\"]+	str_buf += yytext;

} /* end of string parsing */

[ \t\r\n]+ {
	/* ignore whitespace and newlines */
}

^#.*\n {
	/* ignore comment lines starting with '#' */
}

. {
	return yytext[0];
}

%%