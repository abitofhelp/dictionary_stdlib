--  ===================================================================
--  Dictionary.Validation — Character and String Predicates
--  ===================================================================
--
--  Pure functions that answer "is this character/string valid?" for
--  dictionary keys and values.  These predicates are passed as generic
--  formal parameters to Dictionary.Bounded_Text so that validation
--  is enforced at construction time.
--
--  Key rules:
--    * Characters: a-z  A-Z  0-9  hyphen (-)
--    * Length: 1 .. Max_Key_Length
--    * Keys are case-insensitive (normalized to lowercase on storage)
--
--  Value rules:
--    * Characters: printable ASCII (space ' ' .. tilde '~')
--    * Length: 1 .. Max_Value_Length
--
--  ===================================================================

package Dictionary.Validation
   with Pure
is

   Max_Key_Length   : constant Positive := 50;
   Max_Value_Length : constant Positive := 200;

   --  ---------------------------------------------------------------
   --  Character-level predicates
   --  ---------------------------------------------------------------

   function Is_Key_Char (C : Character) return Boolean
      with Post =>
        Is_Key_Char'Result =
          (C in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '-');
   --  True when C is alphanumeric or a hyphen.

   function Is_Value_Char (C : Character) return Boolean
      with Post =>
        Is_Value_Char'Result = (C in ' ' .. '~');
   --  True when C is a printable ASCII character.

   --  ---------------------------------------------------------------
   --  String-level predicates  (convenience, used by JSON parser)
   --  ---------------------------------------------------------------

   function Is_Valid_Key (S : String) return Boolean
      with Post =>
        (if S'Length = 0 or else S'Length > Max_Key_Length
         then not Is_Valid_Key'Result);
   --  True when S is non-empty, within length, and every character
   --  satisfies Is_Key_Char.

   function Is_Valid_Value (S : String) return Boolean
      with Post =>
        (if S'Length = 0 or else S'Length > Max_Value_Length
         then not Is_Valid_Value'Result);
   --  True when S is non-empty, within length, and every character
   --  satisfies Is_Value_Char.

end Dictionary.Validation;
