--  ===================================================================
--  Unit_Runner — Main test entry point
--  ===================================================================
--
--  Calls all unit test packages in order, then prints a summary
--  and sets the exit code (0 = all passed, 1 = failures).
--
--  ===================================================================

with Ada.Text_IO;
with Ada.Command_Line;

with Test_Framework;
with Test_Validation;
with Test_Bounded_Text;
with Test_JSON;
with Test_HTTP;
with Test_Store;

procedure Unit_Runner is
begin
   Ada.Text_IO.Put_Line ("Dictionary Unit Tests");
   Ada.Text_IO.Put_Line ("====================");
   Ada.Text_IO.New_Line;

   Ada.Text_IO.Put_Line ("--- Validation ---");
   Test_Validation.Run;

   Ada.Text_IO.Put_Line ("--- Bounded_Text ---");
   Test_Bounded_Text.Run;

   Ada.Text_IO.Put_Line ("--- JSON ---");
   Test_JSON.Run;

   Ada.Text_IO.Put_Line ("--- HTTP ---");
   Test_HTTP.Run;

   Ada.Text_IO.Put_Line ("--- Store ---");
   Test_Store.Run;

   Test_Framework.Report;

   if Test_Framework.All_Passed then
      Ada.Command_Line.Set_Exit_Status (0);
   else
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Unit_Runner;
