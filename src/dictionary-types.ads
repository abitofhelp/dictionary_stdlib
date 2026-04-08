--  ===================================================================
--  Dictionary.Types — Domain Types
--  ===================================================================
--
--  Central type definitions shared by every other package in the
--  service.  Nothing in this package performs I/O or has side effects.
--
--  Ada 2022 features used:
--    * Generic instantiation with function formals
--    * Discriminated record as a lightweight Result type
--    * Subtype with constrained range
--    * Aspects (Preelaborate)
--
--  ===================================================================

with Ada.Characters.Handling;

with Dictionary.Bounded_Text;
with Dictionary.Validation;

package Dictionary.Types
   with Preelaborate
is
   --  ---------------------------------------------------------------
   --  Re-export limits so callers need not also "with" Validation
   --  ---------------------------------------------------------------

   Max_Key_Length   : constant Positive :=
     Dictionary.Validation.Max_Key_Length;

   Max_Value_Length : constant Positive :=
     Dictionary.Validation.Max_Value_Length;

   Max_Entries : constant Positive := 100;
   --  Upper bound on the number of dictionary entries.  Bounded to
   --  teach resource-limit awareness.

   --  ---------------------------------------------------------------
   --  Identity function — used as the default Normalize for values
   --  ---------------------------------------------------------------

   function Identity (C : Character) return Character is (C)
      with Inline;

   --  ---------------------------------------------------------------
   --  Bounded text instantiations
   --  ---------------------------------------------------------------
   --  Keys are normalized to lowercase so that lookups are
   --  case-insensitive.  Values are stored as-is.

   package Key_Text is new Dictionary.Bounded_Text
     (Max_Length     => Max_Key_Length,
      Is_Valid_Char  => Dictionary.Validation.Is_Key_Char,
      Normalize      => Ada.Characters.Handling.To_Lower);

   package Value_Text is new Dictionary.Bounded_Text
     (Max_Length     => Max_Value_Length,
      Is_Valid_Char  => Dictionary.Validation.Is_Value_Char,
      Normalize      => Identity);

   --  ---------------------------------------------------------------
   --  Entry record — one key-value pair
   --  ---------------------------------------------------------------

   type Entry_Record is record
      Key   : Key_Text.Text   := Key_Text.Empty;
      Value : Value_Text.Text := Value_Text.Empty;
   end record;

   --  ---------------------------------------------------------------
   --  Entry list — bounded collection returned by Get_All
   --  ---------------------------------------------------------------

   subtype Entry_Count is Natural range 0 .. Max_Entries;

   type Entry_Array is
     array (Positive range 1 .. Max_Entries) of Entry_Record;

   type Entry_List is record
      Items : Entry_Array;
      Count : Entry_Count := 0;
   end record;

   --  ---------------------------------------------------------------
   --  Store operation status
   --  ---------------------------------------------------------------

   type Store_Status is
     (Success,
      Already_Exists,
      Not_Found,
      Store_Full);

   --  ---------------------------------------------------------------
   --  Entry result — returned by single-entry queries
   --  ---------------------------------------------------------------
   --  A discriminated record acting as a lightweight Option type:
   --  either we Found the entry and carry its data, or we did not.

   type Entry_Result (Found : Boolean := False) is record
      case Found is
         when True  =>
            Data : Entry_Record;
         when False =>
            null;
      end case;
   end record;

end Dictionary.Types;
