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
   Chunk NewChunk IsChunk
in


%%
%% Global
%%
NewChunk = {`Builtin` 'NewChunk' 2}
IsChunk  = {`Builtin` 'IsChunk'  2}


%%
%% Module
%%
local
   proc {ChunkSelectFeature C F ?X}
      case {IsChunk C} then X=C.F
      else {`RaiseError` kernel(type 'ChunkSelectFeature' [C F] 1 chunk '')}
      end
   end
   proc {ChunkHasFeature C F ?X}
      case {IsChunk C} then X={HasFeature C F}
      else {`RaiseError` kernel(type 'ChunkHasFeature' [C F] 1 chunk '')}
      end
   end
in
   Chunk = chunk(is:            IsChunk
                 new:           NewChunk
                 hasFeature:    ChunkHasFeature
                 selectFeature: ChunkSelectFeature)
end