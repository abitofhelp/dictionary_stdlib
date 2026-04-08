with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Test_Framework;
with Dictionary.HTTP;   use Dictionary.HTTP;
with Dictionary.Router;

package body Test_Router is

   CRLF : constant String := ASCII.CR & ASCII.LF;

   --  Helper: build a raw HTTP request string.
   function Make_Request
     (Method : String;
      Path   : String;
      Body_Content : String := "") return String
   is
      Result : Unbounded_String;
   begin
      Append (Result,
        Method & " " & Path & " HTTP/1.1" & CRLF);
      Append (Result,
        "Host: localhost" & CRLF);
      if Body_Content'Length > 0 then
         Append (Result,
           "Content-Length:"
           & Natural'Image (Body_Content'Length)
           & CRLF);
      end if;
      Append (Result, CRLF);
      Append (Result, Body_Content);
      return To_String (Result);
   end Make_Request;

   --  Helper: get the status code from a response.
   function Response_Status
     (Resp : Response) return Status_Code
   is (Resp.Status);

   --  Helper: check if response body contains a substring.
   function Body_Contains
     (Resp : Response;
      Sub  : String) return Boolean
   is
      S : constant String := To_String (Resp.Content);
   begin
      for I in S'First .. S'Last - Sub'Length + 1 loop
         if S (I .. I + Sub'Length - 1) = Sub then
            return True;
         end if;
      end loop;
      return False;
   end Body_Contains;

   procedure Run is
      Req  : Request;
      Resp : Response;
   begin
      --  ============================================================
      --  Health endpoint
      --  ============================================================

      Req := Parse_Request
        (Make_Request ("GET", "/health"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = OK_200,
         "router: GET /health => 200");
      Test_Framework.Assert
        (Body_Contains (Resp, "healthy"),
         "router: health body contains healthy");

      --  Health: wrong method
      Req := Parse_Request
        (Make_Request ("POST", "/health"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Method_Not_Allowed_405,
         "router: POST /health => 405");

      --  ============================================================
      --  Unknown path
      --  ============================================================

      Req := Parse_Request
        (Make_Request ("GET", "/unknown"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Not_Found_404,
         "router: GET /unknown => 404");

      --  ============================================================
      --  CRUD lifecycle
      --  ============================================================

      --  Create entry
      Req := Parse_Request
        (Make_Request ("POST", "/entries",
         "{""key"":""test-key"","
         & """value"":""test value""}"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Created_201,
         "router: POST /entries => 201");
      Test_Framework.Assert
        (Body_Contains (Resp, "test-key"),
         "router: create body has key");

      --  Create duplicate
      Req := Parse_Request
        (Make_Request ("POST", "/entries",
         "{""key"":""test-key"","
         & """value"":""dup""}"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Conflict_409,
         "router: POST duplicate => 409");

      --  Create case-insensitive duplicate
      Req := Parse_Request
        (Make_Request ("POST", "/entries",
         "{""key"":""TEST-KEY"","
         & """value"":""dup""}"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Conflict_409,
         "router: POST case-dup => 409");

      --  Get entry
      Req := Parse_Request
        (Make_Request ("GET", "/entries/test-key"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = OK_200,
         "router: GET /entries/test-key => 200");
      Test_Framework.Assert
        (Body_Contains (Resp, "test value"),
         "router: get body has value");

      --  Get missing
      Req := Parse_Request
        (Make_Request ("GET", "/entries/nope"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Not_Found_404,
         "router: GET missing => 404");

      --  Create second entry for list test
      Req := Parse_Request
        (Make_Request ("POST", "/entries",
         "{""key"":""aaa"","
         & """value"":""first alphabetically""}"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Created_201,
         "router: POST /entries aaa => 201");

      --  List all (sorted)
      Req := Parse_Request
        (Make_Request ("GET", "/entries"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = OK_200,
         "router: GET /entries => 200");
      --  "aaa" should appear before "test-key"
      declare
         S    : constant String :=
           To_String (Resp.Content);
         Aaa_Pos : Natural := 0;
         Tk_Pos  : Natural := 0;
      begin
         for I in S'First .. S'Last - 2 loop
            if S (I .. I + 2) = "aaa" then
               Aaa_Pos := I;
               exit;
            end if;
         end loop;
         for I in S'First .. S'Last - 7 loop
            if S (I .. I + 7) = "test-key" then
               Tk_Pos := I;
               exit;
            end if;
         end loop;
         Test_Framework.Assert
           (Aaa_Pos > 0 and then Tk_Pos > 0
            and then Aaa_Pos < Tk_Pos,
            "router: list sorted aaa before test-key");
      end;

      --  Update entry
      Req := Parse_Request
        (Make_Request ("PUT", "/entries/test-key",
         "{""key"":""test-key"","
         & """value"":""updated value""}"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = OK_200,
         "router: PUT /entries/test-key => 200");
      Test_Framework.Assert
        (Body_Contains (Resp, "updated value"),
         "router: update body has new value");

      --  Update with mismatched key in body
      Req := Parse_Request
        (Make_Request ("PUT", "/entries/test-key",
         "{""key"":""wrong-key"","
         & """value"":""nope""}"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Bad_Request_400,
         "router: PUT key mismatch => 400");

      --  Update missing
      Req := Parse_Request
        (Make_Request ("PUT", "/entries/nope",
         "{""value"":""x""}"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Not_Found_404,
         "router: PUT missing => 404");

      --  Delete entry
      Req := Parse_Request
        (Make_Request ("DELETE", "/entries/test-key"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = No_Content_204,
         "router: DELETE /entries/test-key => 204");

      --  Delete already deleted
      Req := Parse_Request
        (Make_Request ("DELETE", "/entries/test-key"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Not_Found_404,
         "router: DELETE again => 404");

      --  ============================================================
      --  Validation errors through the router
      --  ============================================================

      --  Bad key in URL (underscore is not allowed)
      Req := Parse_Request
        (Make_Request ("GET", "/entries/bad_key!"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Bad_Request_400,
         "router: GET bad key => 400");

      --  Empty JSON body
      Req := Parse_Request
        (Make_Request ("POST", "/entries", "{}"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Bad_Request_400,
         "router: POST empty json => 400");

      --  Malformed JSON body
      Req := Parse_Request
        (Make_Request ("POST", "/entries", "not json"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Bad_Request_400,
         "router: POST malformed json => 400");

      --  ============================================================
      --  Method not allowed
      --  ============================================================

      Req := Parse_Request
        (Make_Request ("DELETE", "/entries"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Method_Not_Allowed_405,
         "router: DELETE /entries => 405");

      Req := Parse_Request
        (Make_Request ("POST", "/entries/aaa"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = Method_Not_Allowed_405,
         "router: POST /entries/{key} => 405");

      --  Clean up: delete aaa
      Req := Parse_Request
        (Make_Request ("DELETE", "/entries/aaa"));
      Resp := Dictionary.Router.Handle_Request (Req);
      Test_Framework.Assert
        (Response_Status (Resp) = No_Content_204,
         "router: cleanup DELETE aaa => 204");
   end Run;

end Test_Router;
