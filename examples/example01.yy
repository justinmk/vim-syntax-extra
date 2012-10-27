
/* Needs to set the g:yacc_uses_cpp variable manually? */
%parse-param { class Driver& driver }

%union
{
    char character;
}

%{
%}

%% /*** Grammar Rules ***/

start   : program {}
        ;

                                   
%% /*** Additional Code ***/
