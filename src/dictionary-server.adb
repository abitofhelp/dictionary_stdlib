--  ===================================================================
--  Dictionary.Server — Body
--  ===================================================================

with Ada.Characters.Handling;
with Ada.Exceptions;
with Ada.Streams;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.Sockets;           use GNAT.Sockets;

with Dictionary.HTTP;
with Dictionary.Router;

package body Dictionary.Server is

   --  Maximum bytes to read from a single request.
   Max_Request_Size : constant := 8192;

   --  ---------------------------------------------------------------
   --  Convert Stream_Element_Array to String.
   --
   --  TCP sockets deal in bytes (Stream_Element_Array).  HTTP is a
   --  text protocol, so we convert each byte to its Character
   --  equivalent.  This works for ASCII payloads, which is all our
   --  API accepts.
   --  ---------------------------------------------------------------

   function To_String
     (Data : Ada.Streams.Stream_Element_Array;
      Last : Ada.Streams.Stream_Element_Offset) return String
   is
      use Ada.Streams;
      Result : String (1 .. Natural (Last - Data'First + 1));
   begin
      for I in Data'First .. Last loop
         Result (Natural (I - Data'First + 1)) :=
           Character'Val (Natural (Data (I)));
      end loop;
      return Result;
   end To_String;

   --  ---------------------------------------------------------------
   --  Convert String to Stream_Element_Array.
   --  ---------------------------------------------------------------

   function To_Elements
     (S : String) return Ada.Streams.Stream_Element_Array
   is
      use Ada.Streams;
      Result : Stream_Element_Array
        (1 .. Stream_Element_Offset (S'Length));
   begin
      for I in S'Range loop
         Result
           (Stream_Element_Offset (I - S'First + 1)) :=
              Stream_Element (Character'Pos (S (I)));
      end loop;
      return Result;
   end To_Elements;

   --  ---------------------------------------------------------------
   --  Read the full HTTP request from a socket.
   --
   --  TCP does not guarantee that a single Receive_Socket call
   --  returns the entire HTTP message.  We loop, accumulating data,
   --  until we see the end-of-headers marker (CRLFCRLF) and have
   --  received enough body bytes per Content-Length.
   --  ---------------------------------------------------------------

   function Read_Request
     (Client : Socket_Type) return String
   is
      use Ada.Streams;

      CRLFCRLF : constant String :=
        ASCII.CR & ASCII.LF & ASCII.CR & ASCII.LF;
      CL_Tag   : constant String := "content-length:";

      Buf      : Stream_Element_Array (1 .. 4096);
      Last     : Stream_Element_Offset;
      Received : Unbounded_String;
   begin
      --  Phase 1: accumulate bytes until we find the end-of-headers
      --  marker (CRLFCRLF) or exceed the buffer limit.
      loop
         Receive_Socket (Client, Buf, Last);
         exit when Last < Buf'First;  --  peer closed

         Append (Received, To_String (Buf, Last));
         exit when Length (Received) >= Max_Request_Size;

         --  Check whether we have the full header block yet.
         declare
            S : constant String :=
              Ada.Strings.Unbounded.To_String (Received);
         begin
            for I in S'First .. S'Last - 3 loop
               if S (I .. I + 3) = CRLFCRLF then
                  --  Headers complete.  Now ensure we have
                  --  the full body per Content-Length.
                  goto Headers_Done;
               end if;
            end loop;
         end;
      end loop;

      --  If we exit the loop without finding CRLFCRLF, return
      --  whatever we have and let the parser reject it.
      return Ada.Strings.Unbounded.To_String (Received);

      <<Headers_Done>>

      --  Phase 2: parse Content-Length from the accumulated
      --  headers and read any remaining body bytes.
      --
      --  TCP is a byte stream — the body may arrive in a
      --  later packet even though the headers are complete.
      --  We must not return until we have Content-Length bytes
      --  after the header-end marker.
      declare
         S          : constant String :=
           Ada.Strings.Unbounded.To_String (Received);
         Header_End : Natural := 0;
         CL_Value   : Natural := 0;
         Body_Start : Natural;
         Have       : Natural;
         Need       : Natural;
      begin
         --  Find CRLFCRLF position.
         for I in S'First .. S'Last - 3 loop
            if S (I .. I + 3) = CRLFCRLF then
               Header_End := I;
               exit;
            end if;
         end loop;

         --  Scan headers for Content-Length (case-insensitive).
         declare
            Hdr : constant String :=
              S (S'First .. Header_End - 1);
         begin
            for I in Hdr'First
              .. Hdr'Last - CL_Tag'Length + 1
            loop
               declare
                  Match : Boolean := True;
               begin
                  for J in CL_Tag'Range loop
                     if Ada.Characters.Handling.To_Lower
                          (Hdr (I + J - CL_Tag'First))
                        /= CL_Tag (J)
                     then
                        Match := False;
                        exit;
                     end if;
                  end loop;

                  if Match then
                     --  Parse the integer value after the tag.
                     --  Reject malformed values (e.g., "12xyz")
                     --  by resetting to 0 on trailing garbage,
                     --  consistent with HTTP.Parse_Natural.
                     declare
                        Got_Digit : Boolean := False;
                     begin
                        for K in I + CL_Tag'Length
                          .. Hdr'Last
                        loop
                           if Hdr (K) in '0' .. '9' then
                              CL_Value := CL_Value * 10
                                + (Character'Pos (Hdr (K))
                                   - Character'Pos ('0'));
                              Got_Digit := True;
                           elsif Hdr (K) = ' '
                             and then not Got_Digit
                           then
                              null;  --  leading space
                           else
                              if Got_Digit then
                                 CL_Value := 0;
                              end if;
                              exit;
                           end if;
                        end loop;
                     end;
                     exit;
                  end if;
               end;
            end loop;
         end;

         --  If no Content-Length, there is no body to wait for.
         if CL_Value = 0 then
            return S;
         end if;

         Body_Start := Header_End + 4;
         Have :=
           (if Body_Start > S'Last
            then 0
            else S'Last - Body_Start + 1);
         Need := CL_Value;

         --  If the body is already complete, return immediately.
         if Have >= Need then
            return S;
         end if;

         --  Continue reading until the body is complete.
         loop
            Receive_Socket (Client, Buf, Last);
            exit when Last < Buf'First;

            Append (Received, To_String (Buf, Last));
            Have := Have
              + Natural (Last - Buf'First + 1);

            exit when Have >= Need;
            exit when Length (Received) >= Max_Request_Size;
         end loop;

         return Ada.Strings.Unbounded.To_String (Received);
      end;
   end Read_Request;

   --  ---------------------------------------------------------------
   --  Connection_Task — handles one HTTP request then terminates.
   --
   --  A new task is dynamically allocated for each accepted
   --  connection.  The socket value is passed by copy through an
   --  entry call, so there is no dangling reference.
   --  ---------------------------------------------------------------

   task type Connection_Task is
      entry Handle (Client : Socket_Type);
   end Connection_Task;

   type Connection_Task_Access is access Connection_Task;

   task body Connection_Task is
      Socket : Socket_Type;
   begin
      --  Wait for the server to hand us a connected socket.
      accept Handle (Client : Socket_Type) do
         Socket := Client;
      end Handle;

      --  Process the request inside an exception handler so that
      --  a misbehaving client cannot crash the server.
      begin
         declare
            Raw      : constant String :=
              Read_Request (Socket);
            Req      : constant Dictionary.HTTP.Request :=
              Dictionary.HTTP.Parse_Request (Raw);
            Resp     : Dictionary.HTTP.Response;
            Resp_Str : Unbounded_String;
         begin
            if Req.Valid then
               Resp := Dictionary.Router.Handle_Request (Req);
            else
               Resp :=
                 (Status  => Dictionary.HTTP.Bad_Request_400,
                  Content =>
                    To_Unbounded_String
                      ("{""error"":""The HTTP request"
                       & " is malformed.""}"));
            end if;

            Resp_Str := To_Unbounded_String
              (Dictionary.HTTP.Format_Response (Resp));

            declare
               use Ada.Streams;
               Data : constant Stream_Element_Array :=
                 To_Elements
                   (Ada.Strings.Unbounded.To_String
                      (Resp_Str));
               Offset : Stream_Element_Offset :=
                 Data'First;
               Last   : Stream_Element_Offset;
            begin
               while Offset <= Data'Last loop
                  Send_Socket
                    (Socket, Data (Offset .. Data'Last),
                     Last);
                  exit when Last < Offset;
                  Offset := Last + 1;
               end loop;
            end;
         end;
      exception
         when E : others =>
            Ada.Text_IO.Put_Line
              (Ada.Text_IO.Standard_Error,
               "Connection error: "
               & Ada.Exceptions.Exception_Message (E));
      end;

      begin
         Close_Socket (Socket);
      exception
         when others =>
            null;  --  Ignore errors on close.
      end;
   end Connection_Task;

   --  ---------------------------------------------------------------
   --  Start — the main accept loop
   --  ---------------------------------------------------------------

   procedure Start
     (Port : GNAT.Sockets.Port_Type := Default_Port)
   is
      Server_Socket : Socket_Type;
      Client_Socket : Socket_Type;
      Client_Addr   : Sock_Addr_Type;
      Address       : Sock_Addr_Type;
   begin
      --  Create a TCP socket.
      Create_Socket
        (Server_Socket, Family_Inet, Socket_Stream);

      --  Allow address reuse (avoids "address already in use"
      --  after a restart).
      Set_Socket_Option
        (Server_Socket, Socket_Level,
         (Reuse_Address, True));

      --  Bind to all interfaces on the specified port.
      Address :=
        (Family => Family_Inet,
         Addr   => Any_Inet_Addr,
         Port   => Port);
      Bind_Socket (Server_Socket, Address);

      --  Start listening with a backlog of 5 connections.
      Listen_Socket (Server_Socket, 5);

      Ada.Text_IO.Put_Line
        ("Listening on port"
         & GNAT.Sockets.Port_Type'Image (Port)
         & " ...");

      --  Infinite accept loop.
      loop
         Accept_Socket
           (Server_Socket, Client_Socket, Client_Addr);

         --  Spawn a task for this connection.
         declare
            Worker : constant Connection_Task_Access :=
              new Connection_Task;
         begin
            Worker.Handle (Client_Socket);
         end;
      end loop;
   end Start;

end Dictionary.Server;
