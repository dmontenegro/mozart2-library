%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


declare
   Cell IsCell NewCell Exchange Assign Access
in

%%
%% Global
%%
IsCell   = {`Builtin` 'IsCell'   2}
NewCell  = {`Builtin` 'NewCell'  2}
Exchange = {`Builtin` 'Exchange' 3}
Assign   = {`Builtin` 'Assign'   2}
Access   = {`Builtin` 'Access'   2}

%%
%% Module
%%
Cell = cell(is:       IsCell
            new:      NewCell
            exchange: Exchange
            assign:   Assign
            access:   Access)