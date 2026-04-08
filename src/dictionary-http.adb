--  ===================================================================
--  Dictionary.HTTP — Body
--  ===================================================================

with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Dictionary.HTTP is

   CRLF : constant String := ASCII.CR & ASCII.LF;

   --  ---------------------------------------------------------------
   --  Internal: find a substring starting at a given position.
   --  Returns 0 when not found.
   --  ---------------------------------------------------------------

   function Index_Of
     (Source : String;
      Target : String;
      From   : Positive) return Natural
   is
   begin
      if From + Target'Length - 1 > Source'Last then
         return 0;
      end if;

      for I in From .. Source'Last - Target'Length + 1 loop
         if Source (I .. I + Target'Length - 1) = Target then
            return I;
         end if;
      end loop;

      return 0;
   end Index_Of;

   --  ---------------------------------------------------------------
   --  Internal: parse a natural number from a string.
   --  Returns 0 on any parse failure.
   --  ---------------------------------------------------------------

   function Parse_Natural (S : String) return Natural is
      Result    : Natural := 0;
      Got_Digit : Boolean := False;
   begin
      for C of S loop
         if C in '0' .. '9' then
            Result := Result * 10
              + (Character'Pos (C) - Character'Pos ('0'));
            Got_Digit := True;
         elsif C = ' ' and then not Got_Digit then
            --  Leading spaces before digits are acceptable.
            null;
         else
            --  Any non-digit after the first digit (e.g.,
            --  "12xyz") or non-space before any digit means
            --  the value is malformed.  Return 0 so the
            --  request is treated as having no body.
            if Got_Digit then
               return 0;
            else
               return 0;
            end if;
         end if;
      end loop;
      return Result;
   end Parse_Natural;

   --  ---------------------------------------------------------------
   --  Internal: case-insensitive prefix match.
   --  ---------------------------------------------------------------

   function Starts_With_CI
     (Line   : String;
      Prefix : String) return Boolean
   is
      use Ada.Characters.Handling;
   begin
      if Line'Length < Prefix'Length then
         return False;
      end if;

      for I in 0 .. Prefix'Length - 1 loop
         if To_Lower (Line (Line'First + I))
           /= To_Lower (Prefix (Prefix'First + I))
         then
            return False;
         end if;
      end loop;

      return True;
   end Starts_With_CI;

   --  ---------------------------------------------------------------
   --  Method_From_String
   --  ---------------------------------------------------------------

   function Method_From_String (S : String) return HTTP_Method is
   begin
      if S = "GET" then
         return GET;
      elsif S = "POST" then
         return POST;
      elsif S = "PUT" then
         return PUT;
      elsif S = "DELETE" then
         return DELETE;
      else
         return Method_Unknown;
      end if;
   end Method_From_String;

   --  ---------------------------------------------------------------
   --  Status helpers
   --  ---------------------------------------------------------------

   function Status_To_Code (S : Status_Code) return String is
   begin
      case S is
         when OK_200              => return "200";
         when Created_201         => return "201";
         when No_Content_204      => return "204";
         when Bad_Request_400     => return "400";
         when Not_Found_404       => return "404";
         when Method_Not_Allowed_405 => return "405";
         when Conflict_409        => return "409";
         when Internal_Error_500  => return "500";
      end case;
   end Status_To_Code;

   function Status_To_Reason (S : Status_Code) return String is
   begin
      case S is
         when OK_200              => return "OK";
         when Created_201         => return "Created";
         when No_Content_204      => return "No Content";
         when Bad_Request_400     => return "Bad Request";
         when Not_Found_404       => return "Not Found";
         when Method_Not_Allowed_405 => return "Method Not Allowed";
         when Conflict_409        => return "Conflict";
         when Internal_Error_500  =>
            return "Internal Server Error";
      end case;
   end Status_To_Reason;

   --  ---------------------------------------------------------------
   --  Get_Path / Get_Body  (accessor helpers)
   --  ---------------------------------------------------------------

   function Get_Path (R : Request) return String is
   begin
      return R.Path (1 .. R.Path_Length);
   end Get_Path;

   function Get_Body (R : Request) return String is
   begin
      return R.Body_Text (1 .. R.Body_Length);
   end Get_Body;

   --  ---------------------------------------------------------------
   --  Parse_Request
   --  ---------------------------------------------------------------
   --  Anatomy of an HTTP/1.1 request:
   --
   --    METHOD SP PATH SP HTTP/1.1 CR LF
   --    Header-Name: Header-Value CR LF
   --    ...
   --    CR LF                  <-- blank line = end of headers
   --    <body bytes>           <-- optional, sized by Content-Length
   --  ---------------------------------------------------------------

   function Parse_Request (Raw : String) return Request is
      R             : Request;
      Line_End      : Natural;
      Line_Start    : Positive;
      Space1        : Natural;
      Space2        : Natural;
      Header_End    : Natural;
      CL_Prefix     : constant String := "content-length:";
   begin
      --  Phase 1: find end of first line (request line).
      Line_End := Index_Of (Raw, CRLF, Raw'First);
      if Line_End = 0 then
         return R;  --  Valid remains False
      end if;

      --  Phase 2: parse the request line  "METHOD PATH HTTP/1.x"
      declare
         Req_Line : constant String :=
           Raw (Raw'First .. Line_End - 1);
      begin
         --  Find first space (after method).
         Space1 := Ada.Strings.Fixed.Index (Req_Line, " ");
         if Space1 = 0 then
            return R;
         end if;

         --  Find second space (after path).
         Space2 := Ada.Strings.Fixed.Index
           (Req_Line (Space1 + 1 .. Req_Line'Last), " ");
         if Space2 = 0 then
            return R;
         end if;

         R.Method := Method_From_String
           (Req_Line (Req_Line'First .. Space1 - 1));

         declare
            Path_Str : constant String :=
              Req_Line (Space1 + 1 .. Space2 - 1);
         begin
            if Path_Str'Length > Max_Path_Length then
               return R;
            end if;
            R.Path_Length := Path_Str'Length;
            R.Path (1 .. R.Path_Length) := Path_Str;
         end;
      end;

      --  Phase 3: scan headers for Content-Length.
      Line_Start := Line_End + 2;  --  skip past CRLF
      loop
         Line_End := Index_Of (Raw, CRLF, Line_Start);
         exit when Line_End = 0;
         exit when Line_End = Line_Start;  --  blank line

         declare
            Header_Line : constant String :=
              Raw (Line_Start .. Line_End - 1);
         begin
            if Starts_With_CI (Header_Line, CL_Prefix) then
               R.Content_Length := Parse_Natural
                 (Header_Line
                    (Header_Line'First + CL_Prefix'Length
                     .. Header_Line'Last));
            end if;
         end;

         Line_Start := Line_End + 2;
      end loop;

      --  Phase 4: locate end of headers (blank line = CRLFCRLF).
      Header_End := Index_Of (Raw, CRLF & CRLF, Raw'First);
      if Header_End = 0 then
         --  Headers incomplete, but we can still try to proceed
         --  if we have a request line.
         R.Valid := R.Method /= Method_Unknown;
         return R;
      end if;

      --  Phase 5: extract body.
      declare
         Body_Start : constant Positive := Header_End + 4;
         Available  : constant Natural  :=
           (if Body_Start > Raw'Last
            then 0
            else Raw'Last - Body_Start + 1);
         To_Copy    : constant Natural  :=
           Natural'Min
             (Natural'Min (R.Content_Length, Available),
              Max_Body_Size);
      begin
         R.Body_Length := To_Copy;
         if To_Copy > 0 then
            R.Body_Text (1 .. To_Copy) :=
              Raw (Body_Start .. Body_Start + To_Copy - 1);
         end if;
      end;

      R.Valid := R.Method /= Method_Unknown;
      return R;
   end Parse_Request;

   --  ---------------------------------------------------------------
   --  Format_Response
   --  ---------------------------------------------------------------
   --  Builds a complete HTTP/1.1 response:
   --
   --    HTTP/1.1 <code> <reason> CR LF
   --    Content-Type: application/json CR LF
   --    Content-Length: <n> CR LF
   --    Connection: close CR LF
   --    CR LF
   --    <body>
   --  ---------------------------------------------------------------

   function Format_Response (Resp : Response) return String is
      Payload : constant String := To_String (Resp.Content);
      Len_Img  : constant String :=
        Ada.Strings.Fixed.Trim
          (Natural'Image (Payload'Length),
           Ada.Strings.Left);
      Result   : Unbounded_String;
   begin
      --  Status line
      Append (Result,
        "HTTP/1.1 " & Status_To_Code (Resp.Status)
        & " " & Status_To_Reason (Resp.Status) & CRLF);

      --  Headers
      Append (Result,
        "Content-Type: application/json" & CRLF);
      Append (Result,
        "Content-Length: " & Len_Img & CRLF);
      Append (Result,
        "Connection: close" & CRLF);

      --  Blank line (end of headers)
      Append (Result, CRLF);

      --  Body
      Append (Result, Payload);

      return To_String (Result);
   end Format_Response;

end Dictionary.HTTP;
