--  ===================================================================
--  Dictionary.Store — Thread-Safe Key-Value Store
--  ===================================================================
--
--  A protected object that wraps an Ada.Containers.Ordered_Maps map,
--  providing thread-safe CRUD operations for dictionary entries.
--
--  Why a protected object?
--    Ada's protected types give us built-in reader/writer locking:
--    * Functions allow concurrent readers (no mutation).
--    * Procedures provide exclusive access (one writer at a time,
--      no concurrent readers during a write).
--    No external mutex library is needed — this is a language feature.
--
--  Why Ordered_Maps?
--    GET /entries must return entries sorted by key ascending.
--    Ordered_Maps maintain entries in key order via a balanced tree,
--    so iteration is automatically sorted — no post-sort needed.
--
--  Ada 2022 features used:
--    * Protected types with functions (concurrent read) and
--      procedures (exclusive write)
--    * Out-mode parameters for status reporting
--    * Generic instantiation of Ada.Containers.Ordered_Maps
--
--  ===================================================================

with Ada.Containers.Ordered_Maps;

with Dictionary.Types; use Dictionary.Types;

package Dictionary.Store is

   --  ---------------------------------------------------------------
   --  Map instantiation (must be at package level, not inside the
   --  protected type, because generic instantiation creates a
   --  package and packages cannot nest inside protected types).
   --
   --  Key:     Key_Text.Text   (case-normalized, bounded)
   --  Element: Value_Text.Text (bounded printable ASCII)
   --  Order:   Key_Text."<"    (lexicographic on lowercase data)
   --  ---------------------------------------------------------------

   package Entry_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Key_Text.Text,
      Element_Type => Value_Text.Text,
      "<"          => Key_Text."<",
      "="          => Value_Text."=");

   --  ---------------------------------------------------------------
   --  The thread-safe store
   --  ---------------------------------------------------------------

   protected Dictionary_Store is

      --  Read operations (concurrent access permitted)

      function Contains (Key : Key_Text.Text) return Boolean;
      --  True when the store holds an entry with the given key.

      function Get (Key : Key_Text.Text) return Entry_Result;
      --  Retrieve a single entry.  Returns Found = False when
      --  the key is not present.

      function Get_All return Entry_List;
      --  All entries sorted by key ascending.  Items (1 .. Count)
      --  are populated; the rest are default-initialized.

      function Count return Entry_Count;
      --  Number of entries currently stored.

      --  Write operations (exclusive access)

      procedure Create
        (Key    : Key_Text.Text;
         Value  : Value_Text.Text;
         Status : out Store_Status);
      --  Insert a new entry.
      --    Success        — entry created
      --    Already_Exists — duplicate key
      --    Store_Full     — Max_Entries reached

      procedure Update
        (Key    : Key_Text.Text;
         Value  : Value_Text.Text;
         Status : out Store_Status);
      --  Replace the value for an existing key.
      --    Success   — value replaced
      --    Not_Found — key does not exist

      procedure Delete
        (Key    : Key_Text.Text;
         Status : out Store_Status);
      --  Remove an entry.
      --    Success   — entry removed
      --    Not_Found — key does not exist

   private

      Map : Entry_Maps.Map;

   end Dictionary_Store;

end Dictionary.Store;
