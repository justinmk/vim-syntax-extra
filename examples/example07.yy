%initial-action
{
    // initialize the initial location object
    @$.begin.filename = @$.end.filename = &driver.streamname;
}

%% /*** Grammar Rules ***/ 

formal_list	:	formal
            |	formal_list ";" formal	{
i                                           $$ = $1;			
                                            for (SequencedStringTypeMapIterator it=$3->get<Sequence>().begin(); it!=$3->get<Sequence>().end(); it++)
                                            {
                                                std::string key = it->key;
                                                Type *value = it->value;
                                                bool ret = $$->insert(StringTypePair(key, value)).second;
                                                if (ret == false)
                                                {
                                                    error(@$, "Already defined formal parameter " + key + ".");
                                                }
                                            }
                                        }
            ;

%% /*** Additional Code ***/
