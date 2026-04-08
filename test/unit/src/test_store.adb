with Test_Framework;
with Dictionary.Store;
with Dictionary.Types; use Dictionary.Types;

package body Test_Store is

   procedure Run is
      Status : Store_Status;
   begin
      --  Initially empty
      Test_Framework.Assert
        (Dictionary.Store.Dictionary_Store.Count = 0,
         "store: initially empty");

      --  Create an entry
      Dictionary.Store.Dictionary_Store.Create
        (Key_Text.Create ("alpha"),
         Value_Text.Create ("first letter"),
         Status);
      Test_Framework.Assert
        (Status = Success,
         "store: create alpha");
      Test_Framework.Assert
        (Dictionary.Store.Dictionary_Store.Count = 1,
         "store: count after create");

      --  Get the entry
      declare
         Result : constant Entry_Result :=
           Dictionary.Store.Dictionary_Store.Get
             (Key_Text.Create ("alpha"));
      begin
         Test_Framework.Assert
           (Result.Found,
            "store: get alpha found");
         Test_Framework.Assert
           (Value_Text.To_String (Result.Data.Value)
            = "first letter",
            "store: get alpha value");
      end;

      --  Contains
      Test_Framework.Assert
        (Dictionary.Store.Dictionary_Store.Contains
           (Key_Text.Create ("alpha")),
         "store: contains alpha");
      Test_Framework.Assert
        (not Dictionary.Store.Dictionary_Store.Contains
           (Key_Text.Create ("missing")),
         "store: not contains missing");

      --  Duplicate create
      Dictionary.Store.Dictionary_Store.Create
        (Key_Text.Create ("alpha"),
         Value_Text.Create ("dup"),
         Status);
      Test_Framework.Assert
        (Status = Already_Exists,
         "store: duplicate rejected");

      --  Case-insensitive duplicate
      Dictionary.Store.Dictionary_Store.Create
        (Key_Text.Create ("ALPHA"),
         Value_Text.Create ("dup"),
         Status);
      Test_Framework.Assert
        (Status = Already_Exists,
         "store: case-insensitive duplicate");

      --  Create second entry
      Dictionary.Store.Dictionary_Store.Create
        (Key_Text.Create ("beta"),
         Value_Text.Create ("second letter"),
         Status);
      Test_Framework.Assert
        (Status = Success,
         "store: create beta");

      --  Get_All returns sorted
      declare
         List : constant Entry_List :=
           Dictionary.Store.Dictionary_Store.Get_All;
      begin
         Test_Framework.Assert
           (List.Count = 2,
            "store: get_all count");
         Test_Framework.Assert
           (Key_Text.To_String (List.Items (1).Key)
            = "alpha",
            "store: get_all first is alpha");
         Test_Framework.Assert
           (Key_Text.To_String (List.Items (2).Key)
            = "beta",
            "store: get_all second is beta");
      end;

      --  Update existing
      Dictionary.Store.Dictionary_Store.Update
        (Key_Text.Create ("alpha"),
         Value_Text.Create ("updated"),
         Status);
      Test_Framework.Assert
        (Status = Success,
         "store: update alpha");

      --  Verify update
      declare
         Result : constant Entry_Result :=
           Dictionary.Store.Dictionary_Store.Get
             (Key_Text.Create ("alpha"));
      begin
         Test_Framework.Assert
           (Value_Text.To_String (Result.Data.Value)
            = "updated",
            "store: alpha value updated");
      end;

      --  Update non-existent
      Dictionary.Store.Dictionary_Store.Update
        (Key_Text.Create ("missing"),
         Value_Text.Create ("nope"),
         Status);
      Test_Framework.Assert
        (Status = Not_Found,
         "store: update missing not found");

      --  Delete existing
      Dictionary.Store.Dictionary_Store.Delete
        (Key_Text.Create ("beta"), Status);
      Test_Framework.Assert
        (Status = Success,
         "store: delete beta");
      Test_Framework.Assert
        (Dictionary.Store.Dictionary_Store.Count = 1,
         "store: count after delete");

      --  Delete non-existent
      Dictionary.Store.Dictionary_Store.Delete
        (Key_Text.Create ("beta"), Status);
      Test_Framework.Assert
        (Status = Not_Found,
         "store: delete missing not found");

      --  Get deleted entry
      declare
         Result : constant Entry_Result :=
           Dictionary.Store.Dictionary_Store.Get
             (Key_Text.Create ("beta"));
      begin
         Test_Framework.Assert
           (not Result.Found,
            "store: get deleted not found");
      end;
   end Run;

end Test_Store;
