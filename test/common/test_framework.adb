--  ===================================================================
--  Test_Framework — Body
--  ===================================================================

with Ada.Text_IO;

package body Test_Framework is

   Passes : Natural := 0;
   Fails  : Natural := 0;

   --  ---------------------------------------------------------------
   --  Assert
   --  ---------------------------------------------------------------

   procedure Assert
     (Condition : Boolean;
      Test_Name : String;
      Message   : String := "")
   is
   begin
      if Condition then
         Passes := Passes + 1;
      else
         Fails := Fails + 1;
         Ada.Text_IO.Put_Line
           ("  FAIL: " & Test_Name);
         if Message'Length > 0 then
            Ada.Text_IO.Put_Line
              ("        " & Message);
         end if;
      end if;
   end Assert;

   --  ---------------------------------------------------------------
   --  Report
   --  ---------------------------------------------------------------

   procedure Report is
      Total : constant Natural := Passes + Fails;
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line
        ("========================================");
      Ada.Text_IO.Put_Line
        ("  Total: " & Natural'Image (Total));
      Ada.Text_IO.Put_Line
        ("  Pass:  " & Natural'Image (Passes));
      Ada.Text_IO.Put_Line
        ("  Fail:  " & Natural'Image (Fails));
      Ada.Text_IO.Put_Line
        ("========================================");

      if Fails = 0 and then Total > 0 then
         Ada.Text_IO.Put_Line ("  Result: ALL PASSED");
      elsif Total = 0 then
         Ada.Text_IO.Put_Line ("  Result: NO TESTS RAN");
      else
         Ada.Text_IO.Put_Line ("  Result: FAILURES");
      end if;

      Ada.Text_IO.Put_Line
        ("========================================");
   end Report;

   --  ---------------------------------------------------------------
   --  Accessors
   --  ---------------------------------------------------------------

   function Pass_Count return Natural is (Passes);
   function Fail_Count return Natural is (Fails);

   function All_Passed return Boolean is
     (Fails = 0 and then (Passes + Fails) > 0);

end Test_Framework;
