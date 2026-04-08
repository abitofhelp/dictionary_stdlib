--  ===================================================================
--  Dictionary.Store — Body
--  ===================================================================

package body Dictionary.Store is

   protected body Dictionary_Store is

      --  ============================================================
      --  Read operations
      --  ============================================================

      --  -----------------------------------------------------------
      --  Contains
      --  -----------------------------------------------------------

      function Contains (Key : Key_Text.Text) return Boolean is
      begin
         return Map.Contains (Key);
      end Contains;

      --  -----------------------------------------------------------
      --  Get
      --  -----------------------------------------------------------

      function Get (Key : Key_Text.Text) return Entry_Result is
         Cursor : constant Entry_Maps.Cursor := Map.Find (Key);
      begin
         if Entry_Maps.Has_Element (Cursor) then
            return
              (Found => True,
               Data  =>
                 (Key   => Key,
                  Value => Entry_Maps.Element (Cursor)));
         else
            return (Found => False);
         end if;
      end Get;

      --  -----------------------------------------------------------
      --  Get_All
      --  -----------------------------------------------------------
      --  Ordered_Maps iteration visits keys in ascending order,
      --  which is exactly what GET /entries requires.

      function Get_All return Entry_List is
         Result : Entry_List;
         Cursor : Entry_Maps.Cursor := Map.First;
      begin
         while Entry_Maps.Has_Element (Cursor) loop
            Result.Count := Result.Count + 1;
            Result.Items (Result.Count) :=
              (Key   => Entry_Maps.Key (Cursor),
               Value => Entry_Maps.Element (Cursor));
            Entry_Maps.Next (Cursor);
         end loop;
         return Result;
      end Get_All;

      --  -----------------------------------------------------------
      --  Count
      --  -----------------------------------------------------------

      function Count return Entry_Count is
      begin
         return Entry_Count (Map.Length);
      end Count;

      --  ============================================================
      --  Write operations
      --  ============================================================

      --  -----------------------------------------------------------
      --  Create
      --  -----------------------------------------------------------

      procedure Create
        (Key    : Key_Text.Text;
         Value  : Value_Text.Text;
         Status : out Store_Status)
      is
         Cursor   : Entry_Maps.Cursor;
         Inserted : Boolean;
      begin
         --  Check capacity before attempting insert.
         if Natural (Map.Length) >= Max_Entries then
            Status := Store_Full;
            return;
         end if;

         --  Insert returns the cursor and whether it was new.
         Map.Insert
           (Key      => Key,
            New_Item => Value,
            Position => Cursor,
            Inserted => Inserted);

         if Inserted then
            Status := Success;
         else
            Status := Already_Exists;
         end if;
      end Create;

      --  -----------------------------------------------------------
      --  Update
      --  -----------------------------------------------------------

      procedure Update
        (Key    : Key_Text.Text;
         Value  : Value_Text.Text;
         Status : out Store_Status)
      is
         Cursor : constant Entry_Maps.Cursor := Map.Find (Key);
      begin
         if Entry_Maps.Has_Element (Cursor) then
            Map.Replace_Element (Cursor, Value);
            Status := Success;
         else
            Status := Not_Found;
         end if;
      end Update;

      --  -----------------------------------------------------------
      --  Delete
      --  -----------------------------------------------------------

      procedure Delete
        (Key    : Key_Text.Text;
         Status : out Store_Status)
      is
         Cursor : Entry_Maps.Cursor := Map.Find (Key);
      begin
         if Entry_Maps.Has_Element (Cursor) then
            Map.Delete (Cursor);
            Status := Success;
         else
            Status := Not_Found;
         end if;
      end Delete;

   end Dictionary_Store;

end Dictionary.Store;
