
%% /*** Grammar Rules ***/ 

header	:	type IDENTIFIER "(" formals ")" 	{
                                                    for (SequencedStringTypeMapIterator it=$4->get<Sequence>().begin(); it!=$4->get<Sequence>().end(); it++)
                                                    {
                                                        params.pushBack(*it->value);
                                                    }
                                                    symbolTable.put(*$2, FunctionType(params, *$1->getType()));
                                                    symbolTable.pushScope(*$2, FunctionType(params, *$1->getType()));
                                                    for (SequencedStringTypeMapIterator it=$4->get<Sequence>().begin(); it!=$4->get<Sequence>().end(); it++)
                                                    {
                                                        symbolTable.put(it->key, *it->value);
                                                    }
                                                }
        ;

type_or_empty : type
              | /* empty */ { $$ = new ExpressionResult(new VoidType(), NULL); }
              ;

%% /*** Additional Code ***/
