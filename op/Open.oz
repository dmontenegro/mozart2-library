%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
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


local
   ReadSize    = 1024
   ReadSizeAll = 4096
   KillTime    = 500

   %%
   %% Attributes and Methods common to all open classes
   %%
   InitLocks   = {NewName}
   CloseDescs  = {NewName}
   ReadLock    = {NewName}
   WriteLock   = {NewName}
   ReadDesc    = {NewName}
   WriteDesc   = {NewName}
   Buff        = {NewName}
   Last        = {NewName}
   AtEnd       = {NewName}
   TimeOut     = {NewName}
   Missing     = {NewName}

   %%
   %% Exception handling
   %%
   proc {RaiseClosed S M}
      {`Raise` {Exception.system open(alreadyClosed S M)}}
   end

   %%
   %% The common base-class providing for descriptor manipulation
   %%
   fun {DoWrite D V M}
      case {OS.write D V}
      of suspend(N S V) then {Wait S} {DoWrite D V N+M}
      elseof N then N+M
      end
   end

   class DescClass from BaseObject
      feat
         !ReadLock
         !WriteLock
      attr
         !ReadDesc:    false  % Not yet initialized (true = closed, int ...)
         !WriteDesc:   false  % Not yet initialized (true = closed, int ...)
         !Buff:        nil    % The buffer is empty
         !Last:        [0]    % The last char read is initialized to nul
         !AtEnd:       false  % Reading is not at end!

      meth !InitLocks(M)
         %% Initialize locks
         try
            self.ReadLock  = {NewLock}
            self.WriteLock = {NewLock}
         catch failure(debug:_) then
            {`Raise` {Exception.system open(alreadyInitialized self M)}}
         end
      end

      meth dOpen(RD WD)
         {Type.ask.int RD} {Type.ask.int WD}
         DescClass, InitLocks(dOpen(RD WD))
         ReadDesc  <- RD
         WriteDesc <- WD
      end

      meth getDesc(?RD ?WD)
         lock self.ReadLock then
            lock self.WriteLock then
               RD = @ReadDesc
               WD = @WriteDesc
            end
         end
      end

      meth !CloseDescs
         RD=@ReadDesc WD=@WriteDesc
      in
         case {IsInt RD} then
            {OS.deSelect RD} {OS.close RD}
            case RD==WD then skip else
               {OS.deSelect WD} {OS.close WD}
            end
            ReadDesc  <- true
            WriteDesc <- true
         else skip
         end
      end

      meth close
         lock self.ReadLock then
            lock self.WriteLock then
               DescClass, CloseDescs
            end
         end
      end
   end


   %%%
   %%% The File Object
   %%%

   local
      fun {DoReadAll Desc ?Xs Xt N}
         Xr
      in
         case {OS.read Desc ReadSizeAll Xs Xr}
         of 0 then Xr=Xt N
         elseof M then {DoReadAll Desc Xr Xt N+M}
         end
      end

      fun {DoWrite Desc V N}
         case {OS.write Desc V}
         of suspend(M S V) then {Wait S} {DoWrite Desc V M+N}
         elseof M then M+N
         end
      end

      local
         %% Some records for mapping various descriptions to OS sepcification
         ModeMap=map(owner:  access(read:    ['S_IRUSR']
                                    write:   ['S_IWUSR']
                                    execute: ['S_IXUSR'])
                     group:  access(read:    ['S_IRGRP']
                                    write:   ['S_IWGRP']
                                    execute: ['S_IXGRP'])
                     others: access(read:    ['S_IROTH']
                                    write:   ['S_IWOTH']
                                    execute: ['S_IXOTH'])
                     all:    access(read:    ['S_IRUSR' 'S_IRGRP' 'S_IROTH']
                                    write:   ['S_IWUSR' 'S_IWGRP' 'S_IWOTH']
                                    execute: ['S_IXUSR' 'S_IXGRP' 'S_IXOTH']))
      in
         fun {ModeToOS Mode}
            {Record.foldLInd Mode
             fun {$ Cat In What}
                {FoldL What
                 fun {$ In Access}
                    case In==false then false
                    elsecase
                       {HasFeature ModeMap Cat} andthen
                       {HasFeature ModeMap.Cat Access}
                    then {Append ModeMap.Cat.Access In}
                    else false
                    end
                 end In}
             end nil}
         end
      end

      local
         FlagMap = map(append:   'O_APPEND'
                       'create': 'O_CREAT'
                       truncate: 'O_TRUNC'
                       exclude:  'O_EXCL'   )
      in
         fun {FlagsToOS FlagS}
            {FoldL FlagS
             fun {$ In Flag}
                case In==false then false
                elsecase Flag==read orelse Flag==write then In
                elsecase {HasFeature FlagMap Flag} then FlagMap.Flag|In
                else false
                end
             end
             [case {Member read FlagS} andthen {Member write FlagS} then
                 'O_RDWR'
              elsecase {Member write FlagS} then 'O_WRONLY'
              else 'O_RDONLY'
              end]}
         end
      end

   in

      class File
         from DescClass

         meth init(name:  Name
                   flags: FlagS <= [read]
                   mode:  Mode  <= mode(owner:[write] all:[read])) = M
            DescClass, InitLocks(M)
            %% Handle read&write flags
            case {FlagsToOS FlagS}
            of false then {`Raise` {Exception.system
                                  open(illegalFlags self M)}}
            elseof OSFlagS then
               %% Handle access modes
               case {ModeToOS Mode}
               of false then {`Raise` {Exception.system
                                     open(illegalMode self M)}}
               elseof OSModeS then
                  %% Handle special filenames
                  D = case Name
                      of 'stdin'  then {OS.fileDesc 'STDIN_FILENO'}
                      [] 'stdout' then {OS.fileDesc 'STDOUT_FILENO'}
                      [] 'stderr' then {OS.fileDesc 'STDERR_FILENO'}
                      else {OS.open Name OSFlagS OSModeS}
                      end
               in
                  ReadDesc  <- D
                  WriteDesc <- D
               end
            end
         end

         meth read(size:Size <=ReadSize
                   list:?Is  tail:It<=nil len:?N<=_)
            lock self.ReadLock then
               lock self.WriteLock then D=@ReadDesc in
                  case {IsInt D} then
                     N = case Size of all then {DoReadAll D ?Is It 0}
                         else {OS.read D Size ?Is It}
                         end
                  else {RaiseClosed self read(size:Size list:Is tail:It len:N)}
                  end
               end
            end
         end

         meth write(vs:V len:I<=_)
            lock self.ReadLock then
               lock self.WriteLock then D=@WriteDesc in
                  case {IsInt D} then I={DoWrite D V 0}
                  else {RaiseClosed self write(vs:V len:I)}
                  end
               end
            end
         end

         meth seek(whence:W<='set' offset:O<=0)
            lock self.ReadLock then
               lock self.WriteLock then D=@WriteDesc in
                  case {IsInt D} then
                     {OS.lSeek D O case W
                                     of 'set'     then 'SEEK_SET'
                                     [] 'current' then 'SEEK_CUR'
                                     [] 'end'     then 'SEEK_END'
                                     end _}
                  else {RaiseClosed self seek(whence:W offset:O)}
                  end
               end
            end
         end

         meth tell(offset:?O)
            lock self.ReadLock then
               lock self.WriteLock then D=@WriteDesc in
                  case {IsInt D} then O={OS.lSeek D 0 'SEEK_CUR'}
                  else {RaiseClosed self tell(offset:O)}
                  end
               end
            end
         end

      end

   end


   %%%
   %%% Sockets and Pipes
   %%%

   class SockAndPipe from DescClass

      meth read(size: Size <= ReadSize
                len:  Len  <= _
                list: List
                tail: Tail <= nil)
         lock self.ReadLock then D=@ReadDesc in
            case {IsInt D} then
               Len={OS.read D Size List Tail}
            else {RaiseClosed self
                  read(size:Size len:Len list:List tail:Tail)}
            end
         end
      end

      meth write(vs:V len:I<=_)
         lock self.WriteLock then D=@WriteDesc in
            case {IsInt D} then I={DoWrite D V 0}
            else {RaiseClosed self write(vs:V len:I)}
            end
         end
      end

      meth flush(how:How<=[receive send])
         R = {Member receive How}
         S = {Member send    How}
      in
         case R andthen S then
            lock self.ReadLock then
               lock self.WriteLock then skip end
            end
         elsecase R then
            lock self.ReadLock then skip end
         elsecase S then
            lock self.WriteLock then skip end
         else skip
         end
      end
   end


   local
      fun {DoSend D V M}
         case {OS.send D V nil}
         of suspend(N S V) then {Wait S} {DoSend D V N+M}
         elseof N then N+M
         end
      end

      fun {DoSendTo Desc V Host Port M}
         case {OS.sendTo Desc V nil Host Port}
         of suspend(N S V) then {Wait S} {DoSendTo Desc V Host Port N+M}
         elseof N then N+M
         end
      end
   in

      class Socket from SockAndPipe
         %% Implementation of socket
         feat !TimeOut

         meth init(type:T <=stream protocol:P <= nil time:Time <=~1) = M
            {Type.ask.int Time}
            DescClass, InitLocks(M)
            D = {OS.socket 'PF_INET' case T
                                       of 'stream'   then 'SOCK_STREAM'
                                       [] 'datagram' then 'SOCK_DGRAM'
                                       end P}
         in
            self.TimeOut = Time
            ReadDesc  <- D
            WriteDesc <- D
         end

         meth server(port:P<=_ host:H<=_ ...) = M
            Socket, init
            case {HasFeature M takePort} then
               Socket, bind(port:P takePort:M.takePort)
            else
               Socket, bind(port:P)
            end
            Socket, listen(backLog:1)
            Socket, accept(host:H)
         end

         meth client(host:H<='localhost' port:P)
            Socket, init
            Socket, connect(host:H port:P)
         end

         meth listen(backLog:Log<=5)
            lock self.ReadLock then
               lock self.WriteLock then D=@ReadDesc in
                  case {IsInt D} then {OS.listen D Log}
                  else {RaiseClosed self listen(backLog:Log)}
                  end
               end
            end
         end

         meth bind(port:P <= _ ...) = M
            lock self.ReadLock then
               lock self.WriteLock then D=@ReadDesc in
                  case {IsInt D} then
                     P = case {HasFeature M takePort} then
                            {OS.bind D M.takePort}
                            M.takePort
                         else %% Generate port
                            {OS.bind D 0}
                            {OS.getSockName D}
                         end
                  else {RaiseClosed self M}
                  end
               end
            end
         end

         meth accept(host:H <=_ port:P <=_ ...) = M
            lock self.ReadLock then
               lock self.WriteLock then D=@ReadDesc in
                  case {IsInt D} then
                     TimeAcc = case self.TimeOut of ~1 then _
                               elseof TO then {Alarm TO}
                               end
                     WaitAcc = thread
                                  {OS.acceptSelect D}
                                  unit
                               end
                  in
                     {WaitOr TimeAcc WaitAcc}
                     case {IsDet WaitAcc} then
                        AD={OS.accept D H P}
                     in
                        case {HasFeature M accepted} then
                           %% Create new Socket Object
                           M.accepted = {New M.acceptClass dOpen(AD AD)}
                        else
                           DescClass, CloseDescs
                           ReadDesc  <- AD
                           WriteDesc <- AD
                        end
                     else P=false H=false
                     end
                  else {RaiseClosed self M}
                  end
               end
            end
         end

         meth connect(host:H<='localhost' port:P)
            lock self.ReadLock then
               lock self.WriteLock then D=@ReadDesc in
                  case {IsInt D} then {OS.connect D H P}
                  else {RaiseClosed self connect(host:H port:P)}
                  end
               end
            end
         end

         meth send(vs:V len:I<=_ port:P<=Missing host:H<='localhost')
            lock self.WriteLock then D=@WriteDesc in
               case {IsInt D} then
                  I = case P\=Missing then {DoSendTo D V H P 0}
                      else {DoSend D V 0}
                      end
               else {RaiseClosed self send(vs:V len:I port:P host:H)}
               end
            end
         end

         meth receive(list:List  tail:Tail <= nil  len:Len<=_
                      size:Size<=ReadSize
                      host:Host<=_ port:Port<=_ )
            lock self.ReadLock then D=@ReadDesc in
               case {IsInt D} then
                  Len={OS.receiveFrom D Size nil List Tail Host Port}
               else {RaiseClosed self
                     receive(list:List tail:Tail len:Len
                             size:Size host:Host port:Port)}
               end
            end
         end

                 %% methods for closing a connection
         meth shutDown(how:How<=[receive send])
            R = {Member receive How}
            S = {Member send    How}
         in
            case R andthen S then
               lock self.ReadLock then
                  lock self.WriteLock then
                     RD=@ReadDesc WD=@WriteDesc
                  in
                     case {IsInt RD} andthen {IsInt WD} then
                        case RD==WD then {OS.shutDown WD 2}
                        else
                           {OS.shutDown RD 0}
                           {OS.shutDown WD 1}
                        end
                     else {RaiseClosed self shutDown(how:How)}
                     end
                  end
               end
            elsecase R then
               lock self.ReadLock then D=@ReadDesc in
                  case {IsInt D} then {OS.shutDown D 0}
                  else {RaiseClosed self shutDown(how:How)}
                  end
               end
            elsecase S then
               lock self.WriteLock then D=@WriteDesc in
                  case {IsInt D} then {OS.shutDown D 1}
                  else {RaiseClosed self shutDown(how:How)}
                  end
               end
            else skip
            end
         end
      end

   end


   %%%
   %%% Object for reading and writing of lines of text
   %%%

   local
      fun {DoReadLine Is Desc ?UnusedIs ?AtEnd}
         case Is
         of I|Ir then
            case I of &\n then UnusedIs=Ir AtEnd=false nil
            else I|{DoReadLine Ir Desc ?UnusedIs ?AtEnd}
            end
         [] nil then Is in
            case {OS.read Desc ReadSize Is nil}
            of 0 then UnusedIs=nil AtEnd=true nil
            else {DoReadLine Is Desc ?UnusedIs ?AtEnd}
            end
         end
      end

      fun {DoReadOne Is Desc ?UnusedIs ?AtEnd}
         case Is
         of I|Ir then UnusedIs=Ir AtEnd=false I
         [] nil then Is in
            case {OS.read Desc ReadSize Is nil}
            of 0 then UnusedIs=nil AtEnd=true false
            else {DoReadOne Is Desc ?UnusedIs ?AtEnd}
            end
         end
      end

   in

      class Text from DescClass

         meth getC(?I)
            lock self.ReadLock then
               YetEnd  = @AtEnd  NextEnd
               YetBuff = @Buff   NextBuff
               YetLast = @Last   NextLast
            in
               AtEnd <- NextEnd
               Buff  <- NextBuff
               Last  <- NextLast
               case YetEnd then
                  I=false
                  NextEnd=true NextBuff=nil NextLast=YetLast
               else
                  I={DoReadOne YetBuff @ReadDesc NextBuff NextEnd}
                  NextLast=I
               end
            end
         end

         meth putC(I)
            {self write(vs:[I])}
         end

         meth getS($)
            lock self.ReadLock then
               YetEnd  = @AtEnd  NextEnd
               YetBuff = @Buff   NextBuff
               GetDesc = @ReadDesc
            in
               AtEnd <- NextEnd
               Buff  <- NextBuff
               case YetEnd then
                  NextEnd=true NextBuff=nil
                  false
               else
                  It={DoReadLine YetBuff GetDesc NextBuff NextEnd}
               in
                  case NextEnd then
                     case It of nil then false else It end
                  else It
                  end
               end
            end
         end

         meth putS(Is)
            {self write(vs:Is#'\n')}
         end

         meth unGetC
            lock self.ReadLock then
               Buff  <- @Last|@Buff
               Last  <- [0]
               AtEnd <- false
            end
         end

         meth atEnd($)
            lock self.ReadLock then
               @Buff==nil andthen @AtEnd
            end
         end
      end
   end

   %%%
   %%% The pipe object
   %%%


   class Pipe from SockAndPipe
      feat PID

      meth init(cmd:Cmd args:ArgS<=nil pid:Pid<=_) = M
         DescClass, InitLocks(M)
         RD#WD = {OS.pipe Cmd ArgS ?Pid}
      in
         self.PID = Pid
         ReadDesc  <- RD
         WriteDesc <- WD
      end

      meth close
         lock self.ReadLock then
            lock self.WriteLock then
               {OS.system 'kill '#self.PID#' 2> /dev/null' _}
               %% Ignore errors, since process may be killed anyway
               {Delay KillTime}
               {OS.wait _ _}
               {OS.wait _ _}
               DescClass, close
            end
         end
      end
   end

in

   Open = open(file:   File
               text:   Text
               socket: Socket
               pipe:   Pipe)

end