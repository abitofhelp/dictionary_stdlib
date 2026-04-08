--  ===================================================================
--  Dictionary.HTTP — HTTP/1.1 Request Parsing & Response Formatting
--  ===================================================================
--
--  This package turns raw bytes received from a TCP socket into a
--  typed Request record, and turns a typed Response record back into
--  the bytes that form an HTTP/1.1 response.
--
--  What you learn here:
--    * HTTP/1.1 is a line-oriented text protocol over TCP.
--    * A request has: request line, headers, blank line, optional body
--    * A response has: status line, headers, blank line, optional body
--    * TCP is a byte stream — HTTP must frame its own messages
--      (via Content-Length).
--
--  Scope limitations (intentional for a teaching project):
--    * Only the methods we need: GET, POST, PUT, DELETE.
--    * Only Content-Length framing (no chunked transfer encoding).
--    * Connection: close on every response (no keep-alive).
--    * No URI decoding (percent-encoding).
--
--  Ada 2022 features used:
--    * Static_Predicate on enumeration types
--    * Ada.Strings.Unbounded for response body
--
--  ===================================================================

with Ada.Strings.Unbounded;

package Dictionary.HTTP is

   --  ---------------------------------------------------------------
   --  HTTP method enumeration
   --  ---------------------------------------------------------------

   type HTTP_Method is
     (GET, POST, PUT, DELETE, Method_Unknown);

   subtype Known_Method is HTTP_Method
      with Static_Predicate => Known_Method in
        GET | POST | PUT | DELETE;

   --  ---------------------------------------------------------------
   --  HTTP status codes (only the ones we use)
   --  ---------------------------------------------------------------

   type Status_Code is
     (OK_200,
      Created_201,
      No_Content_204,
      Bad_Request_400,
      Not_Found_404,
      Method_Not_Allowed_405,
      Conflict_409,
      Internal_Error_500);

   --  ---------------------------------------------------------------
   --  Request record — produced by Parse_Request
   --  ---------------------------------------------------------------

   Max_Path_Length : constant := 256;
   Max_Body_Size  : constant := 4096;

   type Request is record
      Method         : HTTP_Method := Method_Unknown;
      Path           : String (1 .. Max_Path_Length)
                         := (others => ' ');
      Path_Length     : Natural := 0;
      Body_Text      : String (1 .. Max_Body_Size)
                         := (others => ' ');
      Body_Length     : Natural := 0;
      Content_Length  : Natural := 0;
      Valid          : Boolean := False;
   end record;

   --  ---------------------------------------------------------------
   --  Response record — consumed by Format_Response
   --  ---------------------------------------------------------------

   type Response is record
      Status : Status_Code := OK_200;
      Content : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   --  ---------------------------------------------------------------
   --  Parsing and formatting
   --  ---------------------------------------------------------------

   function Parse_Request (Raw : String) return Request;
   --  Parse a raw HTTP/1.1 request string into a typed record.
   --  Sets Valid = False when the request line is unparseable.

   function Format_Response (Resp : Response) return String;
   --  Format a Response into a complete HTTP/1.1 response string
   --  including status line, headers, blank line, and body.

   --  ---------------------------------------------------------------
   --  Helpers (exposed for testing)
   --  ---------------------------------------------------------------

   function Method_From_String (S : String) return HTTP_Method;
   --  Map "GET", "POST", "PUT", "DELETE" to the enum value.
   --  Returns Method_Unknown for anything else.

   function Status_To_Code (S : Status_Code) return String;
   --  Numeric code as a string, e.g., "200", "404".

   function Status_To_Reason (S : Status_Code) return String;
   --  Reason phrase, e.g., "OK", "Not Found".

   function Get_Path (R : Request) return String
      with Post => Get_Path'Result'Length = R.Path_Length;
   --  Return the path portion as a trimmed String.

   function Get_Body (R : Request) return String
      with Post => Get_Body'Result'Length = R.Body_Length;
   --  Return the body portion as a trimmed String.

end Dictionary.HTTP;
