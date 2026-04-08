--  ===================================================================
--  Test_Framework — Lightweight Test Harness
--  ===================================================================
--
--  A minimal test framework for the dictionary project.  Provides
--  assertion, result tracking, and a summary report.
--
--  Usage pattern in each test package:
--
--    procedure Run_Tests is
--    begin
--       Test_Framework.Assert (1 + 1 = 2, "math works");
--       Test_Framework.Assert (False, "this fails", "on purpose");
--    end Run_Tests;
--
--  The runner calls all test packages then:
--
--    Test_Framework.Report;
--    if Test_Framework.All_Passed then ...
--
--  ===================================================================

package Test_Framework is

   procedure Assert
     (Condition : Boolean;
      Test_Name : String;
      Message   : String := "");
   --  Record a pass or fail.  On failure, prints the test name
   --  and optional message to standard output.

   procedure Report;
   --  Print a summary: total, passed, failed.

   function Pass_Count return Natural;
   function Fail_Count return Natural;

   function All_Passed return Boolean;
   --  True when Fail_Count = 0 and at least one test ran.

end Test_Framework;
