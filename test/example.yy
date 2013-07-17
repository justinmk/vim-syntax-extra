/** @file tony.y
 * Tony programming language parser.
 * Based on http://idlebox.net/2007/flex-bison-cpp-example/
 *
 * Licensed under the GPLv3.
 */

%code requires
{
/*** C/C++ Declarations ***/

#include <typeinfo>

#include "QuadrupleDocument.h"
#include "SymbolTable.h"
#include "GarbageCollectable.h"
#include "SequencedStringTypeMap.h"
#include "ExpressionResult.h"
#include "ExpressionListResult.h"
#include "IfThenElseResult.h"
#include "IntegerType.h"
#include "BooleanType.h"
#include "CharacterType.h"
#include "ArrayType.h"
#include "ListType.h"
#include "AnyType.h"
#include "TupleType.h"
#include "VoidType.h"
#include "FunctionType.h"
}

/*** yacc/bison Declarations ***/

/* Require bison 2.3 or later */
%require "2.3"

/* add debug output code to emitted parser. disable this for release
 * versions. */
%debug

/* start symbol is "start" */
%start start

/* write out a header file containing the token defines */
%defines

/* use newer C++ skeleton file */
%skeleton "lalr1.cc"

/* namespace to enclose parser in */
%name-prefix="tony"

/* set the parser's class identifier */
%define "parser_class_name" "Parser"

/* keep track of the current position within the input */
%locations

%code
{
    #define quadsDocument driver.getQuadrupleDocument()
    #define symbolTable driver.getSymbolTable()
}

%initial-action
{
    // initialize the initial location object
    @$.begin.filename = @$.end.filename = &driver.streamname;
}

/* The driver is passed by reference to the parser. This
 * provides a simple but effective pure interface, not 
 * relying on global variables. */
%parse-param { class Driver& driver }

/* verbose error messages */
%error-verbose

%union
{
    ExpressionResult *result;
    ExpressionListResult *results;
    gcable::String *string;
    gcable::Vector<gcable::String *> *stringVector;
    gcable::Vector<int> *intVector;
    SequencedStringTypeMap *stringTypeMap;
    IfThenElseResult *ifthenelse;
    int integer;
    char character;
}

%token KW_AND "and"
%token KW_BOOL "bool"
%token KW_CHAR "char"
%token KW_DECL "decl"
%token KW_DEF "def"
%token KW_ELSE "else"
%token KW_ELSIF "elsif"
%token KW_END "end"
%token KW_EXIT "exit"
%token KW_FALSE "false"
%token KW_FOR "for"
%token KW_HEAD "head"
%token KW_IF "if"
%token KW_INT "int"
%token KW_LIST "list"
%token KW_MOD "mod"
%token KW_NEW "new"
%token KW_NIL "nil"
%token KW_ISNIL "nil?"
%token KW_NOT "not"
%token KW_OR "or"
%token KW_REF "ref"
%token KW_RETURN "return"
%token KW_SKIP "skip"
%token KW_TAIL "tail"
%token KW_TRUE "true"

%token OP_PLUS "+"
%token OP_MINUS "-"
%token OP_MULT "*"
%token OP_DIV "/"
%token OP_CONS "#"
%token OP_EQ "="
%token OP_DIF "<>"
%token OP_LESS "<"
%token OP_GREAT ">"
%token OP_LESSEQ "<="
%token OP_GREATEQ ">="

%token SEP_LPAR "("
%token SEP_RPAR ")"
%token SEP_LBR "["
%token SEP_RBR "]"
%token SEP_COM ","
%token SEP_SEMI ";"
%token SEP_COL ":"
%token SEP_ASS ":="

%token <string> IDENTIFIER
%token <integer> INT_CONST
%token <character> CHAR_CONST
%token <string> STRING_LITERAL

%token V_function_definition
%token V_def_or_decl_list_or_empty
%token V_def_or_decl_list
%token V_def_or_decl
%token V_header
%token V_formal_list_or_empty
%token V_formal_list
%token V_formal
%token V_type
%token V_function_declaration
%token V_variable_definition
%token V_id_list
%token V_statement
%token V_statement_list
%token V_simple
%token V_simple_list
%token V_call
%token V_expression_list_or_empty
%token V_expression_list
%token V_atom
%token V_expression

%token END 0

%left "or"
%left "and"
%nonassoc "not"
%nonassoc "=" "<>" "<" ">" "<=" ">="
%right "#"
%left "+" "-"
%left "*" "/" "mod"
%nonassoc UMINUS UPLUS

%type <result> call
%type <results> expression_list_or_empty
%type <results> expression_list
%type <result> atom
%type <result> type
%type <result> type_or_empty
%type <result> expression
%type <stringVector> id_list
%type <stringTypeMap> formal
%type <stringTypeMap> formal_list
%type <stringTypeMap> formal_list_or_empty
%type <integer> next_index_capturer
%type <ifthenelse> elsif_or_else_clause_list_or_empty
%type <intVector> jumper
%type <intVector> statement
%type <intVector> statement_list
%type <intVector> simple
%type <intVector> simple_list

%{

#include "Driver.h"
#include "Scanner.h"

/* this "connects" the bison parser in the driver to the flex scanner class
 * object. it defines the yylex() function call to pull the next token from the
 * current lexer object of the driver context. */
#undef yylex
#define yylex driver.lexer->lex

%}

%% /*** Grammar Rules ***/

name.opt : NAME
         | OTHER
         ;

start   : program {}
        | V_function_definition function_definition
        | V_def_or_decl_list_or_empty def_or_decl_list_or_empty
        | V_def_or_decl_list def_or_decl_list
        | V_def_or_decl def_or_decl
        | V_header header
        | V_formal_list_or_empty formal_list_or_empty
        | V_formal_list formal_list	
        | V_formal formal 
        | V_type type
        | V_function_declaration function_declaration
        | V_variable_definition variable_definition
        | V_id_list id_list 
        | V_statement statement
        | V_statement_list statement_list
        | V_simple simple
        | V_simple_list simple_list
        | V_call call
        | V_expression_list_or_empty expression_list_or_empty
        | V_expression_list expression_list
        | V_atom atom 
        | V_expression expression 
        ;

program	: begin_program function_definition  { symbolTable.popScope(); }
        ;

begin_program   : /* empty */   {
                                    symbolTable.put("puti", FunctionType(IntegerType(), VoidType()));
                                    symbolTable.put("putb", FunctionType(BooleanType(), VoidType()));
                                    symbolTable.put("putc", FunctionType(CharacterType(), VoidType()));
                                    symbolTable.put("puts", FunctionType(ArrayType(CharacterType()), VoidType()));
                                    
                                    symbolTable.put("geti", FunctionType(VoidType(), IntegerType()));
                                    symbolTable.put("getb", FunctionType(VoidType(), BooleanType()));
                                    symbolTable.put("getc", FunctionType(VoidType(), CharacterType()));

                                    TupleType getsParams;
                                    getsParams.pushBack(IntegerType());
                                    getsParams.pushBack(ArrayType(CharacterType()));
                                    symbolTable.put("gets", FunctionType(getsParams, VoidType()));
                                    
                                    symbolTable.put("abs", FunctionType(IntegerType(), IntegerType()));
                                    symbolTable.put("ord", FunctionType(CharacterType(), IntegerType()));
                                    symbolTable.put("chr", FunctionType(IntegerType(), CharacterType()));
                                    
                                    symbolTable.put("strlen", FunctionType(ArrayType(CharacterType()), IntegerType()));
                                    
                                    TupleType twoStrings;
                                    twoStrings.pushBack(ArrayType(CharacterType()));
                                    twoStrings.pushBack(ArrayType(CharacterType()));
                                    
                                    symbolTable.put("strcmp", FunctionType(twoStrings, IntegerType()));
                                    symbolTable.put("strcpy", FunctionType(twoStrings, VoidType()));
                                    symbolTable.put("strcat", FunctionType(twoStrings, VoidType()));
                                   
                                    TupleType consvParams;
                                    consvParams.pushBack(AnyType());
                                    consvParams.pushBack(ListType(AnyType()));
                                    symbolTable.put("_consv", FunctionType(consvParams, ListType(AnyType())));

                                    TupleType conspParams;
                                    conspParams.pushBack(AnyType(true));
                                    conspParams.pushBack(ListType(AnyType(true)));
                                    symbolTable.put("_consp", FunctionType(conspParams, ListType(AnyType(true))));
                                    
                                    symbolTable.put("_head", FunctionType(ListType(AnyType()), AnyType()));
                                    symbolTable.put("_tail", FunctionType(ListType(AnyType()), ListType(AnyType())));
                                    
                                    symbolTable.put("_newarrv", FunctionType(AnyType(), ArrayType(AnyType())));
                                    symbolTable.put("_newarrp", FunctionType(AnyType(true), ArrayType(AnyType(true))));
                                    
                                    symbolTable.pushScope();
                                }
                ;

function_definition	:	"def" header ":" def_or_decl_list_or_empty
                        begin_unit statement_list next_index_capturer "end"	{
                                                                                quadsDocument.backpatch($6, $7);
                                                                                const SymbolTable::StorageCell *cell = symbolTable.getTopFunctionCell();
                                                                                quadsDocument.emitQuadruple(new gcable::String(std::string("endu")), new Address(cell), NULL, NULL);
                                                                                symbolTable.popScope();
                                                                            }
                    ;
begin_unit : /* empty */ {
                             const SymbolTable::StorageCell *cell = symbolTable.getTopFunctionCell();
                             quadsDocument.emitQuadruple(new gcable::String(std::string("unit")), new Address(cell), NULL, NULL);
                         }
           ;

def_or_decl_list_or_empty	:	def_or_decl_list  {}
                            |	/* empty */ {}
                            ;

def_or_decl_list	:	def_or_decl {}
                    |	def_or_decl def_or_decl_list {}
                    ;

def_or_decl		:	function_definition {}
                |	function_declaration {}
                |	variable_definition
                ;

header	:	type_or_empty IDENTIFIER "(" formal_list_or_empty ")" 	{
                                                                        TupleType params;
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

formal_list_or_empty	:	formal_list
                        |	/* empty */ { $$ = new SequencedStringTypeMap(); }
                        ;

formal_list	:	formal
            |	formal_list ";" formal	{
                                            $$ = $1;			
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

formal	:	"ref" type id_list	{
                                    $$ = new SequencedStringTypeMap();
                                    for (int i=0; i<$3->size(); i++)
                                    {
                                        std::string key(*(*$3)[i]);
                                        Type *value = $2->getType()->clone();
                                        value->setReference(true);
                                        bool ret = $$->insert(StringTypePair(key, value)).second;
                                        if (ret == false)
                                        {
                                            error(@$, "Already defined formal parameter " + *(*$3)[i] + ".");
                                        }
                                    }
                                }
        |	type id_list	{
                                $$ = new SequencedStringTypeMap();
                                for (int i=0; i<$2->size(); i++)
                                {
                                    std::string key(*(*$2)[i]);
                                    Type *value = $1->getType()->clone();
                                    bool ret = $$->insert(StringTypePair(key, value)).second;
                                    if (ret == false)
                                    {
                                        error(@$, "Already defined formal parameter " + *(*$2)[i] + ".");
                                    }
                                }
                            }
        ;

type	:	"int" { $$ = new ExpressionResult(new IntegerType(), NULL); }
        |	"bool" { $$ = new ExpressionResult(new BooleanType(), NULL); }
        |	"char" { $$ = new ExpressionResult(new CharacterType(), NULL); }
        |	type "[" "]" { $$ = new ExpressionResult(new ArrayType(*$1->getType()), NULL); }
        |	"list" "[" type "]" { $$ = new ExpressionResult(new ListType(*$3->getType()), NULL); }
        ;

function_declaration	:	"decl" header	{
                                                symbolTable.popScope();
                                            }
                        ;

variable_definition	:	type id_list	{
                                            for (int i=0; i < $2->size(); i++)
                                            {
                                                if (!symbolTable.put(*(*$2)[i], *$1->getType()))
                                                {
                                                    error(@$, "Already defined variable " + *(*$2)[i] + ".");	
                                                }
                                            }
                                        }
                    ;

id_list	: IDENTIFIER { $$ = new gcable::Vector<gcable::String*>(); $$->push_back($1); }
        | id_list "," IDENTIFIER { $$ = $1; $$->push_back($3); }
        ;

statement   :    simple
            |    "exit" { 
                            $$ = NULL;
                            const Type &returnType = symbolTable.getTopFunction()->getReturnType();
                            if (returnType != VoidType())
                            {
                                error(@$, "Exit statement used in function with non-void return type." );
                            }
                            quadsDocument.emitQuadruple(new gcable::String(std::string("exit")), NULL, NULL, NULL);
                        } 
            |    "return" expression	{
                                            $$ = NULL; 
                                            const Type &returnType = symbolTable.getTopFunction()->getReturnType();

                                            if (returnType != *$2->getType())
                                            {
                                                error(@$, "Type mismatch in return statement. Expected " + returnType.toString() + " but found " + $2->getType()->toString() + ".");
                                            }
                                            else
                                            {
                                                Address *result;
                                                if (returnType == BooleanType())
                                                {
                                                    result = quadsDocument.conditionalToExpression($2);
                                                }
                                                else
                                                {
                                                    result = $2->getAddress();
                                                }

                                                quadsDocument.emitQuadruple(new gcable::String(std::string("ret")), result, NULL, NULL);
                                            }
                                        }
            |    "if" expression ":" next_index_capturer statement_list
                 elsif_or_else_clause_list_or_empty
                 "end"	{
                            if (*$2->getType() != BooleanType())
                            {
                                error(@$, "Non-boolean expression used in if clause.");
                                $$ = NULL;
                            }
                            else
                            {
                                quadsDocument.backpatch($2->getTrueList(), $4);
                                if ($6 == NULL)
                                {
                                    $$ = quadsDocument.merge($2->getFalseList(), $5);
                                }
                                else
                                {
                                    quadsDocument.backpatch($2->getFalseList(), $6->getBegin());
                                    $$ = quadsDocument.merge($6->getNextList(), $5);
                                }
                            }
                        }
            |    "for" simple_list ";" next_index_capturer expression ";" next_index_capturer simple_list ":" 
                 next_index_capturer statement_list
                 "end" next_index_capturer jumper
                 {   
                     if (*$5->getType() != BooleanType())
                     {
                         error(@$, "Non-boolean expression used in for clause.");
                         $$ = NULL;
                     }
                     else
                     {
                         quadsDocument.backpatch($2, $4);
                         quadsDocument.backpatch($5->getFalseList(), $13);
                         quadsDocument.backpatch($5->getTrueList(), $10);
                         quadsDocument.backpatch($11, $7);
                         quadsDocument.backpatch($8, $4);
                         $$ = $14;
                     }
                 }
            ;

elsif_or_else_clause_list_or_empty
                             :   jumper next_index_capturer
                                 "elsif" expression ":" 
                                 next_index_capturer 
                                 statement_list
                                 elsif_or_else_clause_list_or_empty
                                 {
                                     if (*$4->getType() != BooleanType())
                                     {
                                         error(@$, "Non-boolean expression used in elsif clause.");
                                         $$ = NULL;
                                     }
                                     else
                                     {
                                         quadsDocument.backpatch($4->getTrueList(), $6);
                                         if ($8 == NULL)
                                         {
                                             $$ = new IfThenElseResult($2, quadsDocument.merge($4->getFalseList(),
                                                                           quadsDocument.merge($7, $1)));
                                         }
                                         else
                                         {
                                             quadsDocument.backpatch($4->getFalseList(), $8->getBegin());
                                             $$ = new IfThenElseResult($2, quadsDocument.merge($7,
                                                                           quadsDocument.merge($8->getNextList(), $1)));
                                         }
                                     }
                                 }
                             |   "else" ":" jumper next_index_capturer statement_list
                                 {
                                     $$ = new IfThenElseResult($4,
                                                               quadsDocument.merge($5, $3));
                                 }
                             |   /* empty */ { $$ = NULL; }
                             ;

statement_list   :   statement { $$ = $1; }
                 |   statement next_index_capturer statement_list
                     {
                        quadsDocument.backpatch($1, $2);
                        $$ = $3;
                     }
                 ;

simple  :   "skip" jumper
            {
                $$ = $2;
            }
        |   atom ":=" expression
            {
                if (*$1->getType() != *$3->getType())
                {
                    error(@$, "Assignment applied to different types.");
                    $$ = NULL;
                }
                else
                {
                    if (*$1->getType() != BooleanType())
                    {
                        quadsDocument.emitQuadruple(new gcable::String(std::string(":=")), $3->getAddress(), NULL, $1->getAddress());
                        int index = quadsDocument.getNextQuadrupleIndex();
                        $$ = quadsDocument.makeList(index);
                        quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());
                    }
                    else
                    {
                        int trueIndex = quadsDocument.getNextQuadrupleIndex();
                        quadsDocument.emitQuadruple(new gcable::String(std::string(":=")), new Address(true), NULL, $1->getAddress());
                        int nextTrue = quadsDocument.getNextQuadrupleIndex();
                        quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());
                        int falseIndex = quadsDocument.getNextQuadrupleIndex();
                        quadsDocument.emitQuadruple(new gcable::String(std::string(":=")), new Address(false), NULL, $1->getAddress());
                        int nextFalse= quadsDocument.getNextQuadrupleIndex();
                        quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());
                        quadsDocument.backpatch($3->getTrueList(), trueIndex);
                        quadsDocument.backpatch($3->getFalseList(), falseIndex);
                        $$ = quadsDocument.merge(quadsDocument.makeList(nextTrue),
                                                 quadsDocument.makeList(nextFalse));
                    }
                }
            }
        |   call jumper
            {
                if (*$1->getType() != VoidType())
                {
                    error(@$, "Function with non-void return type used as statement.");
                    $$ = NULL;
                }
                else
                {
                    $$ = $2;
                }
            }
        ;

simple_list    :    simple { $$ = $1; }
               |    simple "," next_index_capturer simple_list
                    {
                        quadsDocument.backpatch($1, $3);
                        $$ = $4;
                    }
               ;

call    : IDENTIFIER "(" expression_list_or_empty ")"	{
                                                            const Type *type = symbolTable.get(*$1);
                                                            const SymbolTable::StorageCell *cell = symbolTable.getCell(*$1);

                                                            if (type == NULL)
                                                            {
                                                                error(@$, "Undefined function " + *$1 + ".");
                                                                $$ = new ExpressionResult(new AnyType(), NULL);
                                                            }
                                                            else
                                                            {
                                                                if (*type == FunctionType(*$3->getType(), AnyType()))
                                                                {
                                                                    const FunctionType *functionType = dynamic_cast<const FunctionType *>(type);
                                                                    if (typeid(functionType->getParametersType()) != typeid(TupleType))
                                                                    {
                                                                        if (!$3->getAddresses()->empty())
                                                                        {
                                                                            quadsDocument.emitQuadruple(functionType->getParametersType().isReference() ?
                                                                                                                        new gcable::String(std::string("param-by-ref")) :
                                                                                                                        new gcable::String(std::string("param-by-val")) ,
                                                                                                                        $3->getAddresses()->front(), NULL, NULL);
                                                                        }
                                                                    }
                                                                    else
                                                                    {
                                                                        const gcable::Vector<Type*> &params = dynamic_cast<const TupleType &>(functionType->getParametersType()).getElementTypes();
                                                                        for (int i=0; i<$3->getAddresses()->size(); i++)
                                                                        {
                                                                            quadsDocument.emitQuadruple(params[i]->isReference() ?
                                                                                                                    new gcable::String(std::string("param-by-ref")) :
                                                                                                                    new gcable::String(std::string("param-by-val")) ,
                                                                                                                    $3->getAddresses()->at(i), NULL, NULL);
                                                                        }
                                                                    }
            
                                                                    Address *address = new Address(cell);
                                                                    Address *temporary = quadsDocument.newTemporary(functionType->getReturnType());
                                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("call")), address, NULL, temporary);

                                                                    $$ = new ExpressionResult(functionType->getReturnType().clone(), temporary);
                                                                }
                                                                else
                                                                {
                                                                    error(@$, "Type mismatch in function call. Expected parameters of type " + dynamic_cast<const FunctionType *>(type)->getParametersType().toString() + " but found " + $3->getType()->toString() + ".");
                                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                                }
                                                            }
                                                        }
        ;

expression_list_or_empty    : expression_list { $$ = $1; }
                            | /* empty */ { $$ = new ExpressionListResult(new VoidType(), new gcable::Vector<Address *>()); }
                            ;

expression_list    : expression {
                                    Address *address;
                                    if (*$1->getType() == BooleanType())
                                    {
                                        address = quadsDocument.conditionalToExpression($1);
                                    }
                                    else
                                    {
                                        address = $1->getAddress();
                                    }

                                    $$ = new ExpressionListResult($1->getType(), address);
                                }
                   | expression "," expression_list	{
                                                        $3->getAddresses()->insert($3->getAddresses()->begin(), $1->getAddress());
                                                        
                                                        if (typeid(*$3->getType()) == typeid(TupleType))
                                                        {
                                                            ((TupleType *) $3->getType())->pushFront(*$1->getType());
                                                            $$ = $3;
                                                        }
                                                        else
                                                        {
                                                            TupleType *tuple = new TupleType;
                                                            tuple->pushBack(*$1->getType());
                                                            tuple->pushBack(*$3->getType());
                                                            $$ = new ExpressionListResult(tuple, $3->getAddresses());
                                                        }
                                                    }
                   ;

atom    : IDENTIFIER	{
                            const Type *type = symbolTable.get(*$1);
                            const SymbolTable::StorageCell *cell = symbolTable.getCell(*$1);
                            if (type != NULL)
                            {
                                $$ = new ExpressionResult(type->clone(), new Address(symbolTable.getCell(*$1)));
                            }
                            else
                            {
                                error(@$, "Undefined symbol " + *$1 + ".");
                                $$ = new ExpressionResult(new AnyType(), NULL);
                            }
                        }
        | STRING_LITERAL    {
                                $$ = new ExpressionResult(new ArrayType(CharacterType()), new Address($1));
                            }
        | atom "[" expression "]"	{
                                        if (*$1->getType() == ArrayType(AnyType()) && *$3->getType() == IntegerType())
                                        {
                                            Address *width = new Address(dynamic_cast<const ArrayType *>($1->getType())->getArrayElementsType().getWidth());
                                            Address *offset = quadsDocument.newTemporary(IntegerType());
                                            Address *reference = quadsDocument.newTemporary(dynamic_cast<const ArrayType *>($1->getType())->getArrayElementsType());
                                            Address *referent = quadsDocument.makeReferent(reference);
                                            quadsDocument.emitQuadruple(new gcable::String("*"), width, $3->getAddress(), offset);
                                            quadsDocument.emitQuadruple(new gcable::String("+"), offset, $1->getAddress(), reference);
                                            $$ = new ExpressionResult(dynamic_cast<const ArrayType *>($1->getType())->getArrayElementsType().clone(), referent);
                                        }
                                        else
                                        {
                                            error(@$, "Illegal application of [].");
                                            $$ = new ExpressionResult(new AnyType(), NULL);
                                        }
                                    }
        | call
        ;

next_index_capturer : { $$ = quadsDocument.getNextQuadrupleIndex(); }
                    ;

jumper :   {
               int index = quadsDocument.getNextQuadrupleIndex();
               $$ = quadsDocument.makeList(index);
               quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());
           }
       ;

expression    : atom {
                         if (*$1->getType() != BooleanType())
                         {
                             $$ = $1;
                         }
                         else
                         {
                            int trueIndex=quadsDocument.getNextQuadrupleIndex();
                            quadsDocument.emitQuadruple(new gcable::String(std::string("==")), $1->getAddress(), new Address(true), new Address());
                            int falseIndex=quadsDocument.getNextQuadrupleIndex();
                            quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());

                            $$ = new ExpressionResult($1->getType()->clone(), NULL, quadsDocument.makeList(falseIndex), quadsDocument.makeList(trueIndex));
                         } 
                     }
              | INT_CONST { $$ = new ExpressionResult(new IntegerType(), new Address($1)); }
              | CHAR_CONST { $$ = new ExpressionResult(new CharacterType(), new Address($1)); }
              | "(" expression ")" { $$ = $2; }
              | "+" expression %prec UPLUS 	{ 
                                                if (*$2->getType() == IntegerType())
                                                {
                                                    $$ = $2;
                                                }
                                                else
                                                {
                                                    error(@$, "Unary + applied to non-integer argument.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | "-" expression %prec UMINUS { 
                                                if (*$2->getType() == IntegerType())
                                                {
                                                    Address *temp = quadsDocument.newTemporary(IntegerType());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("minus")), $2->getAddress(), NULL, temp);
                                                    $$ = new ExpressionResult(new IntegerType(), temp);
                                                }
                                                else
                                                {
                                                    error(@$, "Unary - applied to non-integer argument.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "+" expression 	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType())
                                                {
                                                    Address *temp = quadsDocument.newTemporary(IntegerType());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("+")), $1->getAddress(), $3->getAddress(), temp);
                                                    $$ = new ExpressionResult(new IntegerType(), temp);
                                                }
                                                else
                                                {
                                                    error(@$, "Binary + applied to non-integer arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "-" expression	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType())
                                                {
                                                    Address *temp = quadsDocument.newTemporary(IntegerType());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("-")), $1->getAddress(), $3->getAddress(), temp);
                                                    $$ = new ExpressionResult(new IntegerType(), temp);
                                                }
                                                else
                                                {
                                                    error(@$, "Binary - applied to non-integer arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "*" expression 	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType())
                                                {
                                                    Address *temp = quadsDocument.newTemporary(IntegerType());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("*")), $1->getAddress(), $3->getAddress(), temp);
                                                    $$ = new ExpressionResult(new IntegerType(), temp);
                                                }
                                                else
                                                {
                                                    error(@$, "* applied to non-integer arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "/" expression 	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType())
                                                {
                                                    Address *temp = quadsDocument.newTemporary(IntegerType());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("/")), $1->getAddress(), $3->getAddress(), temp);
                                                    $$ = new ExpressionResult(new IntegerType(), temp);
                                                }
                                                else
                                                {
                                                    error(@$, "/ applied to non-integer arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "mod" expression { 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType())
                                                {
                                                    Address *temp = quadsDocument.newTemporary(IntegerType());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("mod")), $1->getAddress(), $3->getAddress(), temp);
                                                    $$ = new ExpressionResult(new IntegerType(), temp);
                                                }
                                                else
                                                {
                                                    error(@$, "mod applied to non-integer arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "=" expression 	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == CharacterType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == BooleanType() && *$3->getType() == BooleanType())
                                                {
                                                    int index = quadsDocument.getNextQuadrupleIndex();
                                                    $$ = new ExpressionResult(new BooleanType(), 
                                                                              NULL,
                                                                              quadsDocument.makeList(index+1),
                                                                              quadsDocument.makeList(index));
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("==")), $1->getAddress(), $3->getAddress(), new Address());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());
                                                }
                                                else
                                                {
                                                    error(@$, "= applied to different or non-basic type arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "<>" expression	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == CharacterType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == BooleanType() && *$3->getType() == BooleanType())
                                                {
                                                    int index = quadsDocument.getNextQuadrupleIndex();
                                                    $$ = new ExpressionResult(new BooleanType(), 
                                                                              NULL,
                                                                              quadsDocument.makeList(index+1),
                                                                              quadsDocument.makeList(index));
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("<>")), $1->getAddress(), $3->getAddress(), new Address());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());
                                                }
                                                else
                                                {
                                                    error(@$, "<> applied to different or non-basic type arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "<" expression	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == CharacterType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == BooleanType() && *$3->getType() == BooleanType())
                                                {
                                                    int index = quadsDocument.getNextQuadrupleIndex();
                                                    $$ = new ExpressionResult(new BooleanType(), 
                                                                              NULL,
                                                                              quadsDocument.makeList(index+1),
                                                                              quadsDocument.makeList(index));
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("<")), $1->getAddress(), $3->getAddress(), new Address());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());
                                                }
                                                else
                                                {
                                                    error(@$, "< applied to different or non-basic type arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression ">" expression	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == CharacterType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == BooleanType() && *$3->getType() == BooleanType())
                                                {
                                                    int index = quadsDocument.getNextQuadrupleIndex();
                                                    $$ = new ExpressionResult(new BooleanType(), 
                                                                              NULL,
                                                                              quadsDocument.makeList(index+1),
                                                                              quadsDocument.makeList(index));
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string(">")), $1->getAddress(), $3->getAddress(), new Address());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address());
                                                }
                                                else
                                                {
                                                    error(@$, "> applied to different or non-basic type arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "<=" expression 	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == CharacterType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == BooleanType() && *$3->getType() == BooleanType())
                                                {
                                                    int index = quadsDocument.getNextQuadrupleIndex();
                                                    $$ = new ExpressionResult(new BooleanType(), 
                                                                              NULL,
                                                                              quadsDocument.makeList(index+1),
                                                                              quadsDocument.makeList(index));
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("<=")), $1->getAddress(), $3->getAddress(), new Address());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address()); 
                                                }
                                                else
                                                {
                                                    error(@$, "<= applied to different or non-basic type arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression ">=" expression	{ 
                                                if (*$1->getType() == IntegerType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == CharacterType() && *$3->getType() == IntegerType()
                                                    ||
                                                    *$1->getType() == BooleanType() && *$3->getType() == BooleanType())
                                                {
                                                    int index = quadsDocument.getNextQuadrupleIndex();
                                                    $$ = new ExpressionResult(new BooleanType(), 
                                                                              NULL,
                                                                              quadsDocument.makeList(index+1),
                                                                              quadsDocument.makeList(index));
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string(">=")), $1->getAddress(), $3->getAddress(), new Address());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address()); 
                                                }
                                                else
                                                {
                                                    error(@$, ">= applied to different or non-basic type arguments.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | "true"  {
                            int index = quadsDocument.getNextQuadrupleIndex();
                            $$ = new ExpressionResult(new BooleanType(), NULL, NULL, quadsDocument.makeList(index));
                            quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address()); 
                        }
              | "false" {
                            int index = quadsDocument.getNextQuadrupleIndex();
                            $$ = new ExpressionResult(new BooleanType(), NULL, quadsDocument.makeList(index), NULL);
                            quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address()); 
                        }
              | "not" expression	{ 
                                        if (*$2->getType() == BooleanType())
                                        {
                                            $$ = new ExpressionResult(new BooleanType(), 
                                                                      NULL,
                                                                      $2->getTrueList(),
                                                                      $2->getFalseList());
                                        }
                                        else
                                        {
                                            error(@$, "not applied to non-boolean argument.");
                                            $$ = new ExpressionResult(new AnyType(), NULL);
                                        }
                                    }
              | expression "and" next_index_capturer expression	{ 
                                                                    if (*$1->getType() == BooleanType() && *$4->getType() == BooleanType())
                                                                    {
                                                                        quadsDocument.backpatch($1->getTrueList(), $3);
                                                                        $$ = new ExpressionResult(new BooleanType(), NULL,
                                                                                                  quadsDocument.merge($1->getFalseList(), $4->getFalseList()),
                                                                                                  $4->getTrueList());
                                                                    }
                                                                    else
                                                                    {
                                                                        error(@$, "and applied to non-boolean arguments.");
                                                                        $$ = new ExpressionResult(new AnyType(), NULL);
                                                                    }
                                                                }
              | expression "or" next_index_capturer expression	{ 
                                                                    if (*$1->getType() == BooleanType() && *$4->getType() == BooleanType())
                                                                    {
                                                                        quadsDocument.backpatch($1->getFalseList(), $3);
                                                                        $$ = new ExpressionResult(new BooleanType(), NULL,
                                                                                                  $4->getFalseList(),
                                                                                                  quadsDocument.merge($1->getTrueList(), $4->getTrueList()));
                                                                    }
                                                                    else
                                                                    {
                                                                        error(@$, "or applied to non-boolean arguments.");
                                                                        $$ = new ExpressionResult(new AnyType(), NULL);
                                                                    }
                                                                }
              | "new" type "[" expression "]"	{
                                                    if (*$4->getType() == IntegerType())
                                                    {
                                                        Address *size = quadsDocument.newTemporary(IntegerType());
                                                        quadsDocument.emitQuadruple(new gcable::String(std::string("*")), $4->getAddress(), new Address($2->getType()->getWidth()), size);
                                                        quadsDocument.emitQuadruple(new gcable::String(std::string("param-by-val")), size, NULL, NULL);
                                                        
                                                        Address *result = quadsDocument.newTemporary(ArrayType(*$2->getType()));
 
                                                        if (!$2->getType()->isPointer())
                                                        {
                                                            const SymbolTable::StorageCell *cell = symbolTable.getCell("_newarrv");
                                                            quadsDocument.emitQuadruple(new gcable::String(std::string("call")), new Address(cell), NULL, result);
                                                        }
                                                        else
                                                        {
                                                            const SymbolTable::StorageCell *cell = symbolTable.getCell("_newarrp");
                                                            quadsDocument.emitQuadruple(new gcable::String(std::string("call")), new Address(cell), NULL, result);
                                                        }

                                                        $$ = new ExpressionResult(new ArrayType(*$2->getType()), result);
                                                    }
                                                    else
                                                    {
                                                        error(@$, "new used with non-integer size.");
                                                        $$ = new ExpressionResult(new AnyType(), NULL);
                                                    }
                                                }
              | "nil" { $$ = new ExpressionResult(new ListType(AnyType()), Address::NIL); }
              | "nil?" "(" expression ")"	{
                                                if (*$3->getType() == ListType(AnyType()))
                                                {
                                                    int index = quadsDocument.getNextQuadrupleIndex();
                                                    $$ = new ExpressionResult(new BooleanType(), 
                                                                              NULL,
                                                                              quadsDocument.makeList(index+1),
                                                                              quadsDocument.makeList(index));
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("==")), $3->getAddress(), Address::NIL, new Address());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("goto")), NULL, NULL, new Address()); 
                                                }
                                                else
                                                {
                                                    error(@$, "Illegal application of nil?.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | expression "#" expression	{
                                                if (*$3->getType() == ListType(*$1->getType()))
                                                {
                                                    Address *address;
                                                    if (*$1->getType() == BooleanType())
                                                    {
                                                        address = quadsDocument.conditionalToExpression($1);
                                                    }
                                                    else
                                                    {
                                                        address = $1->getAddress();
                                                    }

                                                    if (*$1->getType() != IntegerType() && !$1->getType()->isPointer())
                                                    {
                                                        Address *temporary = quadsDocument.newTemporary(IntegerType());
                                                        quadsDocument.emitQuadruple(new gcable::String(std::string("widen")), address, NULL, temporary);
                                                        address = temporary;
                                                    }
                                                    
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("param-by-val")), address, NULL, NULL);
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("param-by-val")), $3->getAddress(), NULL, NULL);
                                                    
                                                    Address *temporary = quadsDocument.newTemporary(*$3->getType());
                                                    if (!$1->getType()->isPointer())
                                                    {
                                                        const SymbolTable::StorageCell *cell = symbolTable.getCell("_consv");
                                                        quadsDocument.emitQuadruple(new gcable::String(std::string("call")), new Address(cell), NULL, temporary);
                                                    }
                                                    else
                                                    {
                                                        const SymbolTable::StorageCell *cell = symbolTable.getCell("_consp");
                                                        quadsDocument.emitQuadruple(new gcable::String(std::string("call")), new Address(cell), NULL, temporary);
                                                    }

                                                    $$ = new ExpressionResult($3->getType(), temporary);
                                                }
                                                else
                                                {
                                                    error(@$, "Illegal application of #.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | "head" "(" expression ")"	{
                                                if (*$3->getType() == ListType(AnyType()))
                                                {
                                                    const SymbolTable::StorageCell *cell = symbolTable.getCell("_head");
                                                    Address *temporary = quadsDocument.newTemporary(dynamic_cast<const ListType *>($3->getType())->getListElementsType());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("param-by-val")), $3->getAddress(), NULL, NULL);
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("call")), new Address(cell), NULL, temporary);
                                                    $$ = new ExpressionResult(dynamic_cast<const ListType *>($3->getType())->getListElementsType().clone(), temporary);
                                                }
                                                else
                                                {
                                                    error(@$, "Illegal application of head.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              | "tail" "(" expression ")"	{
                                                if (*$3->getType() == ListType(AnyType()))
                                                {
                                                    const SymbolTable::StorageCell *cell = symbolTable.getCell("_tail");
                                                    Address *temporary = quadsDocument.newTemporary(*$3->getType());
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("param-by-val")), $3->getAddress(), NULL, NULL);
                                                    quadsDocument.emitQuadruple(new gcable::String(std::string("call")), new Address(cell), NULL, temporary);
                                                    $$ = new ExpressionResult($3->getType()->clone(), temporary);
                                                }
                                                else
                                                {
                                                    error(@$, "Illegal application of tail.");
                                                    $$ = new ExpressionResult(new AnyType(), NULL);
                                                }
                                            }
              ;

%% /*** Additional Code ***/

void tony::Parser::error(const Parser::location_type& l,
                const std::string& m)
{
    driver.error(l, m);
}
