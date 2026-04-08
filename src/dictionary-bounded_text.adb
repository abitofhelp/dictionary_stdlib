--  ===================================================================
--  Dictionary.Bounded_Text — Body
--  ===================================================================

package body Dictionary.Bounded_Text is

   --  ---------------------------------------------------------------
   --  Create
   --  ---------------------------------------------------------------

   function Create (S : String) return Text is
      Result : Text;
   begin
      Result.Len := S'Length;
      for I in S'Range loop
         Result.Data (I - S'First + 1) := Normalize (S (I));
      end loop;
      return Result;
   end Create;

   --  ---------------------------------------------------------------
   --  To_String
   --  ---------------------------------------------------------------

   function To_String (T : Text) return String is
   begin
      return T.Data (1 .. T.Len);
   end To_String;

   --  ---------------------------------------------------------------
   --  Length
   --  ---------------------------------------------------------------

   function Length (T : Text) return Natural is
   begin
      return T.Len;
   end Length;

   --  ---------------------------------------------------------------
   --  Is_Empty
   --  ---------------------------------------------------------------

   function Is_Empty (T : Text) return Boolean is
   begin
      return T.Len = 0;
   end Is_Empty;

   --  ---------------------------------------------------------------
   --  "<"  (lexicographic on stored data)
   --  ---------------------------------------------------------------

   function "<" (L, R : Text) return Boolean is
      Min_Len : constant Natural := Natural'Min (L.Len, R.Len);
   begin
      for I in 1 .. Min_Len loop
         if L.Data (I) < R.Data (I) then
            return True;
         elsif L.Data (I) > R.Data (I) then
            return False;
         end if;
      end loop;
      --  All compared characters are equal; shorter string is "less".
      return L.Len < R.Len;
   end "<";

   --  ---------------------------------------------------------------
   --  "="
   --  ---------------------------------------------------------------

   overriding
   function "=" (L, R : Text) return Boolean is
   begin
      return L.Len = R.Len
        and then L.Data (1 .. L.Len) = R.Data (1 .. R.Len);
   end "=";

end Dictionary.Bounded_Text;
