--  ===================================================================
--  Integration_Runner — Router pipeline tests
--  ===================================================================

with Ada.Text_IO;
with Ada.Command_Line;

with Test_Framework;
with Test_Router;

procedure Integration_Runner is
begin
   Ada.Text_IO.Put_Line ("Dictionary Integration Tests");
   Ada.Text_IO.Put_Line ("============================");
   Ada.Text_IO.New_Line;

   Ada.Text_IO.Put_Line ("--- Router Pipeline ---");
   Test_Router.Run;

   Test_Framework.Report;

   if Test_Framework.All_Passed then
      Ada.Command_Line.Set_Exit_Status (0);
   else
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Integration_Runner;
