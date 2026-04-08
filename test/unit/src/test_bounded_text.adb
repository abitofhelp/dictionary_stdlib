with Test_Framework;
with Dictionary.Types; use Dictionary.Types;
use Dictionary.Types.Key_Text;
use Dictionary.Types.Value_Text;

package body Test_Bounded_Text is

   procedure Run is
   begin
      --  Key_Text: create and retrieve
      declare
         K : constant Key_Text.Text :=
           Key_Text.Create ("hello");
      begin
         Test_Framework.Assert
           (Key_Text.To_String (K) = "hello",
            "key: create and to_string");
         Test_Framework.Assert
           (Key_Text.Length (K) = 5,
            "key: length");
         Test_Framework.Assert
           (not Key_Text.Is_Empty (K),
            "key: not empty");
      end;

      --  Key_Text: case normalization
      declare
         K : constant Key_Text.Text :=
           Key_Text.Create ("HeLLo");
      begin
         Test_Framework.Assert
           (Key_Text.To_String (K) = "hello",
            "key: normalized to lowercase");
      end;

      --  Key_Text: case-insensitive equality
      declare
         K1 : constant Key_Text.Text :=
           Key_Text.Create ("Hello");
         K2 : constant Key_Text.Text :=
           Key_Text.Create ("HELLO");
      begin
         Test_Framework.Assert
           (K1 = K2,
            "key: case-insensitive equality");
      end;

      --  Key_Text: ordering
      declare
         A : constant Key_Text.Text :=
           Key_Text.Create ("alpha");
         B : constant Key_Text.Text :=
           Key_Text.Create ("beta");
      begin
         Test_Framework.Assert
           (A < B, "key: alpha < beta");
         Test_Framework.Assert
           (not (B < A), "key: not beta < alpha");
      end;

      --  Key_Text: empty
      Test_Framework.Assert
        (Key_Text.Is_Empty (Key_Text.Empty),
         "key: Empty is empty");
      Test_Framework.Assert
        (Key_Text.Length (Key_Text.Empty) = 0,
         "key: Empty length is 0");

      --  Value_Text: create and retrieve
      declare
         V : constant Value_Text.Text :=
           Value_Text.Create ("Hello, world!");
      begin
         Test_Framework.Assert
           (Value_Text.To_String (V) = "Hello, world!",
            "value: create and to_string");
         Test_Framework.Assert
           (Value_Text.Length (V) = 13,
            "value: length");
      end;

      --  Value_Text: no normalization (preserves case)
      declare
         V : constant Value_Text.Text :=
           Value_Text.Create ("MiXeD CaSe");
      begin
         Test_Framework.Assert
           (Value_Text.To_String (V) = "MiXeD CaSe",
            "value: preserves case");
      end;

      --  Value_Text: equality
      declare
         V1 : constant Value_Text.Text :=
           Value_Text.Create ("same");
         V2 : constant Value_Text.Text :=
           Value_Text.Create ("same");
         V3 : constant Value_Text.Text :=
           Value_Text.Create ("diff");
      begin
         Test_Framework.Assert
           (V1 = V2, "value: equality");
         Test_Framework.Assert
           (not (V1 = V3), "value: inequality");
      end;
   end Run;

end Test_Bounded_Text;
