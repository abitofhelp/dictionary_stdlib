with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Test_Framework;
with Dictionary.JSON;  use Dictionary.JSON;
with Dictionary.Types; use Dictionary.Types;

package body Test_JSON is

   procedure Run is
   begin
      --  Parse: valid key+value
      declare
         R : constant Parse_Result :=
           Parse_Entry
             ("{""key"":""hello"",""value"":""world""}");
      begin
         Test_Framework.Assert
           (R.Status = OK, "json_parse: valid kv status");
         Test_Framework.Assert
           (To_String (R.Key_Str) = "hello",
            "json_parse: key extracted");
         Test_Framework.Assert
           (To_String (R.Value_Str) = "world",
            "json_parse: value extracted");
      end;

      --  Parse: value only (for PUT)
      declare
         R : constant Parse_Result :=
           Parse_Entry ("{""value"":""updated""}");
      begin
         Test_Framework.Assert
           (R.Status = OK,
            "json_parse: value-only status");
         Test_Framework.Assert
           (To_String (R.Value_Str) = "updated",
            "json_parse: value-only extracted");
      end;

      --  Parse: malformed (no fields)
      declare
         R : constant Parse_Result :=
           Parse_Entry ("not json at all");
      begin
         Test_Framework.Assert
           (R.Status = Malformed,
            "json_parse: malformed input");
      end;

      --  Parse: empty body
      declare
         R : constant Parse_Result :=
           Parse_Entry ("");
      begin
         Test_Framework.Assert
           (R.Status = Malformed,
            "json_parse: empty body");
      end;

      --  Serialize: single entry
      declare
         E : constant Entry_Record :=
           (Key   => Key_Text.Create ("abc"),
            Value => Value_Text.Create ("def"));
         S : constant String := Serialize_Entry (E);
      begin
         Test_Framework.Assert
           (S = "{""key"":""abc"",""value"":""def""}",
            "json_ser: single entry");
      end;

      --  Serialize: entry list (sorted)
      declare
         List : Entry_List;
         S    : constant String :=
           Serialize_Entry_List (List);
      begin
         --  Empty list.
         Test_Framework.Assert
           (S = "[]", "json_ser: empty list");
      end;

      declare
         List : Entry_List;
      begin
         List.Count := 2;
         List.Items (1) :=
           (Key   => Key_Text.Create ("a"),
            Value => Value_Text.Create ("first"));
         List.Items (2) :=
           (Key   => Key_Text.Create ("b"),
            Value => Value_Text.Create ("second"));

         declare
            S : constant String :=
              Serialize_Entry_List (List);
         begin
            Test_Framework.Assert
              (S = "[{""key"":""a"",""value"":""first""},"
               & "{""key"":""b"",""value"":""second""}]",
               "json_ser: two-entry list");
         end;
      end;

      --  Serialize: error
      Test_Framework.Assert
        (Serialize_Error ("oops")
         = "{""error"":""oops""}",
         "json_ser: error message");

      --  Serialize: health
      Test_Framework.Assert
        (Serialize_Health
         = "{""status"":""healthy""}",
         "json_ser: health");
   end Run;

end Test_JSON;
