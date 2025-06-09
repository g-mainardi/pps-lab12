% map(+L, +Mapper, -Lo)
% where Mapper = mapper(I, O, UNARY_OP)
% e.g.: Mapper = mapper(X, Y, Y is X +1)
map([], _, []).
map([H|T], M, [H2|T2]):-
	map(T, M, T2), copy_term(M, mapper(H, H2, OP)), call(OP).

% filter(+L, +Predicate, -Lo)
% where Predicate = predicate(I, UNARY_PREDICATE)
% e.g.: Predicate = predicate(X, X > 10)
filter([], _, []).
filter([H|T], P, [H|FT]):- 
	filter(T, P, FT), copy_term(P, predicate(H, OP)), call(OP), !.
filter([_|T], P, FT):- filter(T, P, FT).

% reduce(+L, +Reducer, -Val)
% where Reducer = reducer(E1, E2, O, BINARY_OP)
% e.g.: Reducer = reducer(X, Y, A, A is X+Y)
reduce([H|T], R, V):-
	reduce(T, R, VT), copy_term(R, reducer(H, VT, V, OP)), call(OP), !.
reduce([H], _, H).

% foldleft(+L, +Init, +BinaryOp, -Final)
% where BinaryOp = op(E1, E2, O, BINARY_OP)
% e.g.: BinaryOp = op(X, Y, A, A is X+Y)    => sum
% e.g.: BinaryOp = op(X, _, A, A is X+1)    => size
foldleft([], Acc, _, Acc).
foldleft([H|T], Acc, BOp, F):- 
	 copy_term(BOp, op(Acc, H, NAcc, OP)), call(OP), foldleft(T, NAcc, BOp, F). 
	  
% foldright(+L, +Init, +BinaryOp, -Final)
% where BinaryOp = op(E1, E2, O, BINARY_OP)
foldright([], Acc, _, Acc).
foldright([H|T], I, BOp, F):- 
	foldright(T, I, BOp, Acc),
	copy_term(BOp, op(H, Acc, F, OP)), call(OP). 

% mapV2(+L, +Mapper, -Lo)
mapV2(L, M, Lo) :-
    copy_term(M, mapper(E1, E2, OP)),
    Bop = (OP, V = [E2|Acc]), 					 % calls map and folding only on need
    foldright(L, [], op(E1, Acc, V, BOp), Lo).

% filterV2(+L, +Predicate, -Lo)
filterV2(L, P, Lo) :-
    copy_term(P, predicate(E, OP)),
    Bop = (OP, V = [E|Acc]; V = Acc),   % calls filter and folding only on need
    foldright(L, [], op(E, Acc, V, Bop), Lo), !.

% reduce(+L, +Reducer, -Val)
reduceV2([H|T], R, V):- 
	copy_term(R, reducer(Acc, E, V, OP)), foldleft(T, H, op(Acc, E, V, OP), V).
