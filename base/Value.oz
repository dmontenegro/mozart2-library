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
   Value Wait WaitOr IsFree IsKinded IsDet Min Max CondSelect HasFeature
   `.` `==` `=` `\\=` `<` `=<` `>=` `>`
   `condSelect` `hasFeature` `wait`
in


%%
%% Global
%%
Wait       = {`Builtin` 'Wait'       1}
WaitOr     = {`Builtin` 'WaitOr'     2}
IsFree     = {`Builtin` 'IsFree'     2}
IsKinded   = {`Builtin` 'IsKinded'   2}
IsDet      = {`Builtin` 'IsDet'      2}
Max        = {`Builtin` 'Max'        3}
Min        = {`Builtin` 'Min'        3}
CondSelect = {`Builtin` 'CondSelect' 4}
HasFeature = {`Builtin` 'HasFeature' 3}


%%
%% Compiler Support
%%
`.`          = {`Builtin` '.'   3}
`==`         = {`Builtin` '=='  3}
`=`          = {`Builtin` '='   2}
`\\=`        = {`Builtin` '\\=' 3}
`<`          = {`Builtin` '<'   3}
`=<`         = {`Builtin` '=<'  3}
`>=`         = {`Builtin` '>='  3}
`>`          = {`Builtin` '>'   3}
`condSelect` = CondSelect
`hasFeature` = HasFeature
`wait`       = Wait


%%
%% Module
%%

Value = value(wait:       Wait
              waitOr:     WaitOr

              '=<':       `=<`
              '<':        `<`
              '>=':       `>=`
              '>':        `>`
              '==':       `==`
              '=':        `=`
              '\\=':      `\\=`
              max:        Max
              min:        Min

              '.':        `.`
              hasFeature: HasFeature
              condSelect: CondSelect

              isFree:     IsFree
              isKinded:   IsKinded
              isDet:      IsDet
              status:     {`Builtin` 'Value.status' 2})