--  ===================================================================
--  Dictionary.Bounded_Text — Generic Validated Bounded Text
--  ===================================================================
--
--  A reusable generic that pairs a fixed-capacity string buffer with
--  a character-validity predicate and an optional normalization step.
--
--  Why generic?
--    Both dictionary keys and values share the same structure:
--    bounded length, per-character validation, and immutable storage.
--    The only differences are the maximum length, the character set,
--    and whether normalization is applied (keys are lowercased).
--
--    Rather than duplicate that logic, we write it once here and
--    instantiate twice in Dictionary.Types.
--
--  Why not Ada.Strings.Bounded?
--    * Ada.Strings.Bounded uses controlled types (heap, finalization)
--      which are not SPARK-compatible.
--    * It does not enforce character validity at construction.
--    * A purpose-built type is simpler to teach and to prove.
--
--  Ada 2022 features used:
--    * Pre/Post contracts on public subprograms
--    * Quantified expressions in contracts ("for all C of S")
--    * Aspects over pragmas
--
--  ===================================================================

generic
   Max_Length : Positive;
   --  Maximum number of characters this text can hold.

   with function Is_Valid_Char (C : Character) return Boolean;
   --  Per-character predicate.  Must return True for every character
   --  that is allowed in this text type.

   with function Normalize (C : Character) return Character is <>;
   --  Optional per-character normalization applied at construction.
   --  Defaults to the identity function when not supplied.
   --  For dictionary keys this is Ada.Characters.Handling.To_Lower.

package Dictionary.Bounded_Text
   with Preelaborate
is

   --  ---------------------------------------------------------------
   --  The public opaque type
   --  ---------------------------------------------------------------

   type Text is private;

   Empty : constant Text;
   --  A zero-length text value.

   --  ---------------------------------------------------------------
   --  Construction
   --  ---------------------------------------------------------------

   function Create (S : String) return Text
      with Pre  =>
             S'Length >= 1
             and then S'Length <= Max_Length
             and then (for all C of S => Is_Valid_Char (C)),
           Post =>
             Length (Create'Result) = S'Length;
   --  Build a Text from a plain String.  The precondition guarantees
   --  that the caller has already validated the input; Create then
   --  applies Normalize to each character before storing it.

   --  ---------------------------------------------------------------
   --  Observers
   --  ---------------------------------------------------------------

   function To_String (T : Text) return String
      with Post => To_String'Result'Length = Length (T);
   --  Return the stored characters as a plain String.

   function Length (T : Text) return Natural
      with Post => Length'Result <= Max_Length;
   --  Number of characters currently stored.

   function Is_Empty (T : Text) return Boolean
      with Post => Is_Empty'Result = (Length (T) = 0);
   --  True when the text holds no characters.

   --  ---------------------------------------------------------------
   --  Comparison  (needed by Ada.Containers.Ordered_Maps)
   --  ---------------------------------------------------------------

   function "<" (L, R : Text) return Boolean;
   --  Lexicographic less-than on the stored (normalized) data.

   overriding
   function "=" (L, R : Text) return Boolean;
   --  Equality on the stored (normalized) data.

   --  ---------------------------------------------------------------
   --  Private representation
   --  ---------------------------------------------------------------

private

   subtype Length_Range is Natural range 0 .. Max_Length;
   subtype Index_Range  is Positive range 1 .. Max_Length;

   type Text is record
      Data : String (Index_Range) := (others => ' ');
      Len  : Length_Range         := 0;
   end record;

   Empty : constant Text :=
     (Data => (others => ' '),
      Len  => 0);

end Dictionary.Bounded_Text;
