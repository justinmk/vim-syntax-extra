%start start

%type <intVector> statement

%% /*** Grammar Rules ***/

/* To demonstrate that this is not marked as a keyword */
A	: 'a'  { int a = 3%type; }
    ;

/* Should this be marked as an error or is it C/C++ syntax issue? */
B	: 'b'  { int b = %start; }
    ;

%% 
