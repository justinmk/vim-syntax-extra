%code requires
{
#include <typeinfo>
}

%code
{
    #define quadsDocument driver.getQuadrupleDocument()
    #define symbolTable driver.getSymbolTable()
}

%code provides
{
    #define quadsDocument driver.getQuadrupleDocument()
    #define symbolTable driver.getSymbolTable()
}

%code top
{
}

%initial-action
{
    // initialize the initial location object
    @$.begin.filename = @$.end.filename = &driver.streamname;
}

%{

#include "Driver.h"
#include "Scanner.h"

%}

%% /*** Grammar Rules ***/
%% /*** Additional Code ***/
