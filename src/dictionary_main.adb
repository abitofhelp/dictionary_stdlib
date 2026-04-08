--  ===================================================================
--  Dictionary_Main — Entry Point
--  ===================================================================
--
--  The main procedure for the Dictionary_Stdlib REST microservice.
--
--  This is a standalone compilation unit, not a child of the
--  Dictionary package.  In Ada, child packages (Dictionary.Types,
--  Dictionary.Store, etc.) require the parent to be a package spec,
--  not a procedure.  So the main procedure lives outside the
--  hierarchy.
--
--  The GPR Builder package maps this unit to the executable name
--  "dictionary_stdlib" so the binary is bin/dictionary_stdlib.
--
--  ===================================================================

with Ada.Text_IO;
with Dictionary.Server;

procedure Dictionary_Main is
begin
   Ada.Text_IO.Put_Line
     ("Dictionary_Stdlib REST Microservice v0.1.0-dev");
   Ada.Text_IO.Put_Line
     ("Press Ctrl+C to stop.");
   Ada.Text_IO.New_Line;
   Dictionary.Server.Start;
end Dictionary_Main;
