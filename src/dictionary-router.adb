--  ===================================================================
--  Dictionary.Router — Body
--  ===================================================================

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Dictionary.HTTP;  use Dictionary.HTTP;
with Dictionary.JSON;  use Dictionary.JSON;
with Dictionary.Store;
with Dictionary.Types; use Dictionary.Types;
use Dictionary.Types.Key_Text;
with Dictionary.Validation;

package body Dictionary.Router is

   --  Prefix constant for path matching.
   Entries_Path : constant String := "/entries";

   --  ---------------------------------------------------------------
   --  Internal: extract the key segment from the path.
   --  Given "/entries/my-key", returns "my-key".
   --  Given "/entries" or "/entries/", returns "".
   --  ---------------------------------------------------------------

   function Extract_Key (Path : String) return String is
      Prefix_Len : constant Natural := Entries_Path'Length;
   begin
      if Path'Length <= Prefix_Len then
         return "";
      end if;

      if Path (Path'First + Prefix_Len) /= '/' then
         return "";
      end if;

      return Path (Path'First + Prefix_Len + 1 .. Path'Last);
   end Extract_Key;

   --  ---------------------------------------------------------------
   --  Internal: build a Response with a JSON error body.
   --  ---------------------------------------------------------------

   function Error_Response
     (Code    : Status_Code;
      Message : String) return Response
   is
   begin
      return
        (Status  => Code,
         Content =>
           To_Unbounded_String
             (Dictionary.JSON.Serialize_Error (Message)));
   end Error_Response;

   --  ---------------------------------------------------------------
   --  Internal: build a Response with a JSON body.
   --  ---------------------------------------------------------------

   function JSON_Response
     (Code    : Status_Code;
      Payload : String) return Response
   is
   begin
      return
        (Status  => Code,
         Content => To_Unbounded_String (Payload));
   end JSON_Response;

   --  ---------------------------------------------------------------
   --  Handler: GET /health
   --  ---------------------------------------------------------------

   function Handle_Health return Response is
   begin
      return JSON_Response
        (OK_200, Dictionary.JSON.Serialize_Health);
   end Handle_Health;

   --  ---------------------------------------------------------------
   --  Handler: GET /entries  (list all, sorted by key ascending)
   --  ---------------------------------------------------------------

   function Handle_Get_All return Response is
      List : constant Entry_List :=
        Dictionary.Store.Dictionary_Store.Get_All;
   begin
      return JSON_Response
        (OK_200,
         Dictionary.JSON.Serialize_Entry_List (List));
   end Handle_Get_All;

   --  ---------------------------------------------------------------
   --  Handler: GET /entries/{key}
   --  ---------------------------------------------------------------

   function Handle_Get_One
     (Key_Str : String) return Response
   is
   begin
      if not Dictionary.Validation.Is_Valid_Key (Key_Str) then
         return Error_Response
           (Bad_Request_400,
            "The key is invalid or exceeds"
            & " 50 characters.");
      end if;

      declare
         Key    : constant Key_Text.Text :=
           Key_Text.Create (Key_Str);
         Result : constant Entry_Result :=
           Dictionary.Store.Dictionary_Store.Get (Key);
      begin
         if Result.Found then
            return JSON_Response
              (OK_200,
               Dictionary.JSON.Serialize_Entry (Result.Data));
         else
            return Error_Response
              (Not_Found_404,
               "No entry was found for key '"
               & Key_Str & "'.");
         end if;
      end;
   end Handle_Get_One;

   --  ---------------------------------------------------------------
   --  Handler: POST /entries
   --  ---------------------------------------------------------------

   function Handle_Create (Req : Request) return Response is
      Parsed : constant Dictionary.JSON.Parse_Result :=
        Dictionary.JSON.Parse_Entry (Get_Body (Req));
      Key_S  : constant String :=
        To_String (Parsed.Key_Str);
      Val_S  : constant String :=
        To_String (Parsed.Value_Str);
   begin
      if Parsed.Status /= Dictionary.JSON.OK then
         return Error_Response
           (Bad_Request_400,
            "The request body is not valid JSON.");
      end if;

      if not Dictionary.Validation.Is_Valid_Key (Key_S) then
         return Error_Response
           (Bad_Request_400,
            "The key is invalid or exceeds"
            & " 50 characters.");
      end if;

      if not Dictionary.Validation.Is_Valid_Value (Val_S) then
         return Error_Response
           (Bad_Request_400,
            "The value is empty, non-printable,"
            & " or exceeds 200 characters.");
      end if;

      declare
         Key       : constant Key_Text.Text :=
           Key_Text.Create (Key_S);
         Value     : constant Value_Text.Text :=
           Value_Text.Create (Val_S);
         Status    : Store_Status;
         Entry_Rec : constant Entry_Record :=
           (Key => Key, Value => Value);
      begin
         Dictionary.Store.Dictionary_Store.Create
           (Key, Value, Status);

         case Status is
            when Success =>
               return JSON_Response
                 (Created_201,
                  Dictionary.JSON.Serialize_Entry
                    (Entry_Rec));
            when Already_Exists =>
               return Error_Response
                 (Conflict_409,
                  "An entry with key '"
                  & Key_Text.To_String (Key)
                  & "' already exists.");
            when Store_Full =>
               return Error_Response
                 (Conflict_409,
                  "The dictionary is full"
                  & " (maximum 100 entries).");
            when Not_Found =>
               return Error_Response
                 (Internal_Error_500,
                  "An unexpected error occurred.");
         end case;
      end;
   end Handle_Create;

   --  ---------------------------------------------------------------
   --  Handler: PUT /entries/{key}  (strict update)
   --  ---------------------------------------------------------------

   function Handle_Update
     (Req     : Request;
      Key_Str : String) return Response
   is
   begin
      if not Dictionary.Validation.Is_Valid_Key (Key_Str) then
         return Error_Response
           (Bad_Request_400,
            "The key is invalid or exceeds"
            & " 50 characters.");
      end if;

      declare
         Parsed : constant Dictionary.JSON.Parse_Result :=
           Dictionary.JSON.Parse_Entry (Get_Body (Req));
         Val_S  : constant String :=
           To_String (Parsed.Value_Str);
      begin
         if Parsed.Status /= Dictionary.JSON.OK then
            return Error_Response
              (Bad_Request_400,
               "The request body is not valid JSON.");
         end if;

         --  If a "key" field is present in the body, it must
         --  be valid AND match the URL key.
         declare
            Body_Key_S : constant String :=
              To_String (Parsed.Key_Str);
         begin
            if Body_Key_S'Length > 0 then
               if not Dictionary.Validation.Is_Valid_Key
                        (Body_Key_S)
               then
                  return Error_Response
                    (Bad_Request_400,
                     "The key in the request body"
                     & " is invalid.");
               end if;

               declare
                  URL_Key  : constant Key_Text.Text :=
                    Key_Text.Create (Key_Str);
                  Body_Key : constant Key_Text.Text :=
                    Key_Text.Create (Body_Key_S);
               begin
                  if URL_Key /= Body_Key then
                     return Error_Response
                       (Bad_Request_400,
                        "The key in the request body"
                        & " does not match the URL.");
                  end if;
               end;
            end if;
         end;

         if not Dictionary.Validation.Is_Valid_Value (Val_S)
         then
            return Error_Response
              (Bad_Request_400,
               "The value is empty, contains"
               & " non-printable characters,"
               & " or exceeds 200 characters.");
         end if;

         declare
            Key    : constant Key_Text.Text :=
              Key_Text.Create (Key_Str);
            Value  : constant Value_Text.Text :=
              Value_Text.Create (Val_S);
            Status : Store_Status;
         begin
            Dictionary.Store.Dictionary_Store.Update
              (Key, Value, Status);

            case Status is
               when Success =>
                  return JSON_Response
                    (OK_200,
                     Dictionary.JSON.Serialize_Entry
                       ((Key => Key, Value => Value)));
               when Not_Found =>
                  return Error_Response
                    (Not_Found_404,
                     "No entry was found for key '"
                     & Key_Str & "'.");
               when Already_Exists | Store_Full =>
                  return Error_Response
                    (Internal_Error_500,
                     "An unexpected error occurred.");
            end case;
         end;
      end;
   end Handle_Update;

   --  ---------------------------------------------------------------
   --  Handler: DELETE /entries/{key}
   --  ---------------------------------------------------------------

   function Handle_Delete
     (Key_Str : String) return Response
   is
   begin
      if not Dictionary.Validation.Is_Valid_Key (Key_Str) then
         return Error_Response
           (Bad_Request_400,
            "The key is invalid or exceeds"
            & " 50 characters.");
      end if;

      declare
         Key    : constant Key_Text.Text :=
           Key_Text.Create (Key_Str);
         Status : Store_Status;
      begin
         Dictionary.Store.Dictionary_Store.Delete
           (Key, Status);

         case Status is
            when Success =>
               return
                 (Status  => No_Content_204,
                  Content => Null_Unbounded_String);
            when Not_Found =>
               return Error_Response
                 (Not_Found_404,
                  "No entry was found for key '"
                  & Key_Str & "'.");
            when Already_Exists | Store_Full =>
               return Error_Response
                 (Internal_Error_500,
                  "An unexpected error occurred.");
         end case;
      end;
   end Handle_Delete;

   --  ---------------------------------------------------------------
   --  Handle_Request — main dispatch
   --  ---------------------------------------------------------------

   function Handle_Request
     (Req : Request) return Response
   is
      Path : constant String := Get_Path (Req);
   begin
      --  Health endpoint.
      if Path = "/health" then
         if Req.Method = GET then
            return Handle_Health;
         else
            return Error_Response
              (Method_Not_Allowed_405,
               "The /health endpoint only supports"
               & " GET.");
         end if;
      end if;

      --  Entries collection: /entries
      if Path = Entries_Path then
         case Req.Method is
            when GET =>
               return Handle_Get_All;
            when POST =>
               return Handle_Create (Req);
            when others =>
               return Error_Response
                 (Method_Not_Allowed_405,
                  "The /entries endpoint supports"
                  & " GET and POST.");
         end case;
      end if;

      --  Single entry: /entries/{key}
      if Path'Length > Entries_Path'Length
        and then Path
          (Path'First
           .. Path'First + Entries_Path'Length - 1)
                 = Entries_Path
      then
         declare
            Key_Str : constant String :=
              Extract_Key (Path);
         begin
            if Key_Str'Length = 0 then
               return Error_Response
                 (Bad_Request_400,
                  "The key is missing from the URL.");
            end if;

            case Req.Method is
               when GET =>
                  return Handle_Get_One (Key_Str);
               when PUT =>
                  return Handle_Update (Req, Key_Str);
               when DELETE =>
                  return Handle_Delete (Key_Str);
               when others =>
                  return Error_Response
                    (Method_Not_Allowed_405,
                     "The /entries/{key} endpoint"
                     & " supports GET, PUT,"
                     & " and DELETE.");
            end case;
         end;
      end if;

      --  Unknown path.
      return Error_Response
        (Not_Found_404,
         "The requested path was not found.");
   end Handle_Request;

end Dictionary.Router;
