%code
{
    #define quadsDocument driver.getQuadrupleDocument()
    #define symbolTable driver.getSymbolTable()
}

%% /*** Grammar Rules ***/

type	:	"int" { $$ = new ExpressionResult(new IntegerType(), NULL); }
        |	"bool" { $$ = new ExpressionResult(new BooleanType(), NULL); }
        |	'char' { $$ = new ExpressionResult(new CharacterType(), NULL); }
        |	type "[" "]" { $$ = new ExpressionResult(new ArrayType(*$1->getType()), NULL); }
        |	'list' "[" type "]" { $$ = new ExpressionResult(new ListType(*$3->getType()), NULL); }
        ;
        
%% /*** Additional Code ***/

void tony::Parser::error(const Parser::location_type& l,
                const std::string& m)
{
    driver.error(l, m);
}
