--  ===================================================================
--  Dictionary.JSON — Body
--  ===================================================================

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Dictionary.JSON is

   --  ---------------------------------------------------------------
   --  Internal helper: extract the string value for a given field
   --  name from a JSON object.
   --
   --  Scans for  "field_name" : "value"  and returns the content
   --  between the value quotes.  Handles \" and \\ escapes.
   --
   --  Returns Null_Unbounded_String when the field is not found.
   --  ---------------------------------------------------------------

   function Extract_Field
     (Text       : String;
      Field_Name : String) return Unbounded_String
   is
      --  Build the search target:  "field_name"
      Target : constant String :=
        '"' & Field_Name & '"';
      Pos    : Natural;
   begin
      --  Locate the field name in the JSON text.
      Pos := 0;
      for I in Text'First
        .. Text'Last - Target'Length + 1
      loop
         if Text (I .. I + Target'Length - 1) = Target then
            Pos := I + Target'Length;
            exit;
         end if;
      end loop;

      if Pos = 0 then
         return Null_Unbounded_String;
      end if;

      --  Skip whitespace and the colon after the field name.
      while Pos <= Text'Last
        and then Text (Pos) in ' ' | ASCII.HT | ':'
      loop
         Pos := Pos + 1;
      end loop;

      --  We should now be at the opening quote of the value.
      if Pos > Text'Last or else Text (Pos) /= '"' then
         return Null_Unbounded_String;
      end if;

      --  Move past the opening quote.
      Pos := Pos + 1;

      --  Collect characters until the closing (unescaped) quote.
      declare
         Result : Unbounded_String;
      begin
         while Pos <= Text'Last loop
            if Text (Pos) = '\' and then Pos < Text'Last then
               --  Handle escape sequences: \" and \\
               Pos := Pos + 1;
               Append (Result, Text (Pos));
            elsif Text (Pos) = '"' then
               --  Closing quote found.
               return Result;
            else
               Append (Result, Text (Pos));
            end if;
            Pos := Pos + 1;
         end loop;

         --  Reached end of text without a closing quote.
         return Null_Unbounded_String;
      end;
   end Extract_Field;

   --  ---------------------------------------------------------------
   --  Parse_Entry
   --  ---------------------------------------------------------------

   function Parse_Entry (Body_Text : String) return Parse_Result is
      Key_UB   : constant Unbounded_String :=
        Extract_Field (Body_Text, "key");
      Value_UB : constant Unbounded_String :=
        Extract_Field (Body_Text, "value");
   begin
      if Length (Key_UB) = 0
        and then Length (Value_UB) = 0
      then
         return (Status    => Malformed,
                 Key_Str   => Null_Unbounded_String,
                 Value_Str => Null_Unbounded_String);
      end if;

      return (Status    => OK,
              Key_Str   => Key_UB,
              Value_Str => Value_UB);
   end Parse_Entry;

   --  ---------------------------------------------------------------
   --  Serialize_Entry
   --  ---------------------------------------------------------------

   function Serialize_Entry (E : Entry_Record) return String is
   begin
      return "{""key"":"""
        & Key_Text.To_String (E.Key)
        & """,""value"":"""
        & Value_Text.To_String (E.Value)
        & """}";
   end Serialize_Entry;

   --  ---------------------------------------------------------------
   --  Serialize_Entry_List
   --  ---------------------------------------------------------------

   function Serialize_Entry_List
     (List : Entry_List) return String
   is
      Result : Unbounded_String;
   begin
      Append (Result, '[');

      for I in 1 .. List.Count loop
         if I > 1 then
            Append (Result, ',');
         end if;
         Append
           (Result,
            Serialize_Entry (List.Items (I)));
      end loop;

      Append (Result, ']');
      return To_String (Result);
   end Serialize_Entry_List;

   --  ---------------------------------------------------------------
   --  Serialize_Error
   --  ---------------------------------------------------------------

   function Serialize_Error (Message : String) return String is
   begin
      return "{""error"":""" & Message & """}";
   end Serialize_Error;

   --  ---------------------------------------------------------------
   --  Serialize_Health
   --  ---------------------------------------------------------------

   function Serialize_Health return String is
   begin
      return "{""status"":""healthy""}";
   end Serialize_Health;

end Dictionary.JSON;
