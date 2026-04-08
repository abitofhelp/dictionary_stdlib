with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Test_Framework;
with Dictionary.HTTP; use Dictionary.HTTP;

package body Test_HTTP is

   CRLF : constant String := ASCII.CR & ASCII.LF;

   procedure Run is
   begin
      --  Method_From_String
      Test_Framework.Assert
        (Method_From_String ("GET") = GET,
         "http_method: GET");
      Test_Framework.Assert
        (Method_From_String ("POST") = POST,
         "http_method: POST");
      Test_Framework.Assert
        (Method_From_String ("PUT") = PUT,
         "http_method: PUT");
      Test_Framework.Assert
        (Method_From_String ("DELETE") = DELETE,
         "http_method: DELETE");
      Test_Framework.Assert
        (Method_From_String ("PATCH") = Method_Unknown,
         "http_method: unknown");

      --  Status helpers
      Test_Framework.Assert
        (Status_To_Code (OK_200) = "200",
         "http_status: 200 code");
      Test_Framework.Assert
        (Status_To_Reason (Not_Found_404) = "Not Found",
         "http_status: 404 reason");
      Test_Framework.Assert
        (Status_To_Code (Created_201) = "201",
         "http_status: 201 code");

      --  Parse: simple GET
      declare
         Raw : constant String :=
           "GET /health HTTP/1.1" & CRLF
           & "Host: localhost" & CRLF
           & CRLF;
         Req : constant Request := Parse_Request (Raw);
      begin
         Test_Framework.Assert
           (Req.Valid, "http_parse: GET valid");
         Test_Framework.Assert
           (Req.Method = GET,
            "http_parse: GET method");
         Test_Framework.Assert
           (Get_Path (Req) = "/health",
            "http_parse: GET path");
         Test_Framework.Assert
           (Req.Body_Length = 0,
            "http_parse: GET no body");
      end;

      --  Parse: POST with body
      declare
         Body_Text : constant String :=
           "{""key"":""hi"",""value"":""there""}";
         Raw : constant String :=
           "POST /entries HTTP/1.1" & CRLF
           & "Content-Length:"
           & Natural'Image (Body_Text'Length) & CRLF
           & CRLF
           & Body_Text;
         Req : constant Request := Parse_Request (Raw);
      begin
         Test_Framework.Assert
           (Req.Valid, "http_parse: POST valid");
         Test_Framework.Assert
           (Req.Method = POST,
            "http_parse: POST method");
         Test_Framework.Assert
           (Get_Path (Req) = "/entries",
            "http_parse: POST path");
         Test_Framework.Assert
           (Req.Body_Length = Body_Text'Length,
            "http_parse: POST body length");
         Test_Framework.Assert
           (Get_Body (Req) = Body_Text,
            "http_parse: POST body content");
      end;

      --  Parse: DELETE with path parameter
      declare
         Raw : constant String :=
           "DELETE /entries/my-key HTTP/1.1" & CRLF
           & CRLF;
         Req : constant Request := Parse_Request (Raw);
      begin
         Test_Framework.Assert
           (Req.Valid, "http_parse: DELETE valid");
         Test_Framework.Assert
           (Req.Method = DELETE,
            "http_parse: DELETE method");
         Test_Framework.Assert
           (Get_Path (Req) = "/entries/my-key",
            "http_parse: DELETE path with key");
      end;

      --  Parse: garbage
      declare
         Req : constant Request :=
           Parse_Request ("not http");
      begin
         Test_Framework.Assert
           (not Req.Valid,
            "http_parse: garbage invalid");
      end;

      --  Format: response with body
      declare
         Resp : constant Response :=
           (Status  => OK_200,
            Content =>
              To_Unbounded_String ("{""ok"":true}"));
         S : constant String :=
           Format_Response (Resp);
      begin
         Test_Framework.Assert
           (S (S'First .. S'First + 14)
            = "HTTP/1.1 200 OK",
            "http_format: status line");
         --  Check body appears at the end.
         Test_Framework.Assert
           (S (S'Last - 10 .. S'Last)
            = "{""ok"":true}",
            "http_format: body at end");
      end;

      --  Format: 204 No Content (empty body)
      declare
         Resp : constant Response :=
           (Status  => No_Content_204,
            Content => Null_Unbounded_String);
         S : constant String :=
           Format_Response (Resp);
      begin
         Test_Framework.Assert
           (S (S'First .. S'First + 22)
            = "HTTP/1.1 204 No Content",
            "http_format: 204 status line");
      end;
   end Run;

end Test_HTTP;
