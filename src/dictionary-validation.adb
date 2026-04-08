--  ===================================================================
--  Dictionary.Validation — Body
--  ===================================================================

package body Dictionary.Validation is

   --  ---------------------------------------------------------------
   --  Is_Key_Char
   --  ---------------------------------------------------------------

   function Is_Key_Char (C : Character) return Boolean is
   begin
      return C in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-';
   end Is_Key_Char;

   --  ---------------------------------------------------------------
   --  Is_Value_Char
   --  ---------------------------------------------------------------

   function Is_Value_Char (C : Character) return Boolean is
   begin
      return C in ' ' .. '~';
   end Is_Value_Char;

   --  ---------------------------------------------------------------
   --  Is_Valid_Key
   --  ---------------------------------------------------------------

   function Is_Valid_Key (S : String) return Boolean is
   begin
      if S'Length = 0 or else S'Length > Max_Key_Length then
         return False;
      end if;

      for C of S loop
         if not Is_Key_Char (C) then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_Key;

   --  ---------------------------------------------------------------
   --  Is_Valid_Value
   --  ---------------------------------------------------------------

   function Is_Valid_Value (S : String) return Boolean is
   begin
      if S'Length = 0 or else S'Length > Max_Value_Length then
         return False;
      end if;

      for C of S loop
         if not Is_Value_Char (C) then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_Value;

end Dictionary.Validation;
