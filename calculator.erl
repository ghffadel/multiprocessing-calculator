% Definição do nome do módulo
- module (calculator).

% Importando funções necessárias
- import(string, [split/3, strip/3]).

% Exportando as funções utilizadas
- export([addition/3, division/3, loop/0, multiplication/3, subtraction/3]).

% Lê o input e remove o caractere de fim de linha
read_input () ->
    strip(io:get_line("Insert the expression: "), right, $\n).

% Transforma a string da expressão em tokens
tokenize_expression (Expression) ->
    {ok, Tokens, _} = erl_scan:string(Expression ++ "."),
    {ok, [ExpressionsList]} = erl_parse:parse_exprs(Tokens),
    ExpressionsList.

% Funções que definem o percurso em pós-ordem pela árvore de tokens
post_order_traversal ({op, _, Operation, LeftSide, RightSide}) ->
    io_lib:format("~s ~s ~s", [post_order_traversal(LeftSide), post_order_traversal(RightSide), atom_to_list(Operation)]);

post_order_traversal({integer, _, Number}) ->
    io_lib:format("~b", [Number]).

% Transforma a string da expressão em uma lista
parse_expression (Expression) ->
    Tree = tokenize_expression(Expression),
    lists:flatten(post_order_traversal(Tree)).

% Função de adição
addition (From, A, B) ->
    io:format("~p + ~p = ~p\n", [A, B, A + B]),
    Result = A + B,
    From ! {self(), Result}.

% Função de subtração
subtraction (From, A, B) ->
    io:format("~p - ~p = ~p\n", [A, B, A - B]),
    Result = A - B,
    From ! {self(), Result}.

% Função de multiplicação
multiplication (From, A, B) ->
    io:format("~p * ~p = ~p\n", [A, B, A * B]),
    Result = A * B,
    From ! {self(), Result}.

% Função de divisão
division (From, A, B) ->
    io:format("~p / ~p = ~p\n", [A, B, A / B]),
    Result = A / B,
    From ! {self(), Result}.

% Realizará o calculo a partir da notação posfixa com utilização de pilha
evaluate (Element) ->
    if
        Element == "+" ->
            Stack = get("Stack"),
            A = lists:last(Stack),
            RemainingA = lists:droplast(Stack),
            B = lists:last(RemainingA),
            RemainingB = lists:droplast(RemainingA),
            % Criação do processo de adição
            Pid = spawn(calculator, addition, [self(), B, A]),
            receive
                {Pid, Result} ->
                    Result
            end,
            put("Stack", RemainingB ++ [Result]);

        Element == "-" ->
            Stack = get("Stack"),
            A = lists:last(Stack),
            RemainingA = lists:droplast(Stack),
            B = lists:last(RemainingA),
            RemainingB = lists:droplast(RemainingA),
            % Criação do processo de subtração
            Pid = spawn(calculator, subtraction, [self(), B, A]),
            receive
                {Pid, Result} ->
                    Result
            end,
            put("Stack", RemainingB ++ [Result]);

        Element == "*" ->
            Stack = get("Stack"),
            A = lists:last(Stack),
            RemainingA = lists:droplast(Stack),
            B = lists:last(RemainingA),
            RemainingB = lists:droplast(RemainingA),
            % Criação do processo de multiplicação
            Pid = spawn(calculator, multiplication, [self(), B, A]),
            receive
                {Pid, Result} ->
                    Result
            end,
            put("Stack", RemainingB ++ [Result]);

        Element == "/" ->
            Stack = get("Stack"),
            A = lists:last(Stack),
            RemainingA = lists:droplast(Stack),
            B = lists:last(RemainingA),
            RemainingB = lists:droplast(RemainingA),
            % Criação do processo de divisão
            Pid = spawn(calculator, division, [self(), B, A]),
            receive
                {Pid, Result} ->
                    Result
            end,
            put("Stack", RemainingB ++ [Result]);

        true ->
            {Number, _} = string:to_integer(Element),
            put("Stack", get("Stack") ++ [Number])
    
    end.

% Percorrerá todo o vetor da expressão de maneira recursiva
evaluate_recursion ([]) -> ok;

evaluate_recursion([Head | Tail]) ->
    evaluate(Head),
    evaluate_recursion(Tail).

% Função principal que executará em loop
loop () ->
    % Inicialização da pilha
    put("Stack", []),
    Expression = parse_expression(read_input()),
    SplittedExpression = split(Expression, " ", all),
    evaluate_recursion(SplittedExpression),
    Stack = get("Stack"),
    FinalResult = lists:last(Stack),
    io:format("Final result: ~p\n\n", [FinalResult]),
    loop().