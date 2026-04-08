with Test_Framework;
with Dictionary.Validation;

package body Test_Validation is

   use Dictionary.Validation;

   procedure Run is
   begin
      --  Is_Key_Char: valid characters
      Test_Framework.Assert
        (Is_Key_Char ('a'), "key_char: lowercase a");
      Test_Framework.Assert
        (Is_Key_Char ('z'), "key_char: lowercase z");
      Test_Framework.Assert
        (Is_Key_Char ('A'), "key_char: uppercase A");
      Test_Framework.Assert
        (Is_Key_Char ('Z'), "key_char: uppercase Z");
      Test_Framework.Assert
        (Is_Key_Char ('0'), "key_char: digit 0");
      Test_Framework.Assert
        (Is_Key_Char ('9'), "key_char: digit 9");
      Test_Framework.Assert
        (Is_Key_Char ('-'), "key_char: hyphen");

      --  Is_Key_Char: invalid characters
      Test_Framework.Assert
        (not Is_Key_Char (' '), "key_char: reject space");
      Test_Framework.Assert
        (not Is_Key_Char ('_'), "key_char: reject underscore");
      Test_Framework.Assert
        (not Is_Key_Char ('.'), "key_char: reject dot");
      Test_Framework.Assert
        (not Is_Key_Char ('!'), "key_char: reject bang");

      --  Is_Value_Char: valid range
      Test_Framework.Assert
        (Is_Value_Char (' '), "val_char: space");
      Test_Framework.Assert
        (Is_Value_Char ('~'), "val_char: tilde");
      Test_Framework.Assert
        (Is_Value_Char ('A'), "val_char: letter");

      --  Is_Value_Char: invalid
      Test_Framework.Assert
        (not Is_Value_Char (ASCII.NUL),
         "val_char: reject NUL");
      Test_Framework.Assert
        (not Is_Value_Char (ASCII.LF),
         "val_char: reject LF");
      Test_Framework.Assert
        (not Is_Value_Char (ASCII.DEL),
         "val_char: reject DEL");

      --  Is_Valid_Key: good keys
      Test_Framework.Assert
        (Is_Valid_Key ("hello"), "valid_key: hello");
      Test_Framework.Assert
        (Is_Valid_Key ("my-key-123"),
         "valid_key: alphanumeric with hyphens");
      Test_Framework.Assert
        (Is_Valid_Key ("a"), "valid_key: single char");

      --  Is_Valid_Key: bad keys
      Test_Framework.Assert
        (not Is_Valid_Key (""), "valid_key: reject empty");
      Test_Framework.Assert
        (not Is_Valid_Key ("has space"),
         "valid_key: reject space");
      Test_Framework.Assert
        (not Is_Valid_Key ("has_underscore"),
         "valid_key: reject underscore");

      --  Is_Valid_Key: too long (51 chars)
      declare
         Long_Key : constant String (1 .. 51) :=
           (others => 'a');
      begin
         Test_Framework.Assert
           (not Is_Valid_Key (Long_Key),
            "valid_key: reject >50 chars");
      end;

      --  Is_Valid_Key: max length (50 chars)
      declare
         Max_Key : constant String (1 .. 50) :=
           (others => 'x');
      begin
         Test_Framework.Assert
           (Is_Valid_Key (Max_Key),
            "valid_key: accept 50 chars");
      end;

      --  Is_Valid_Value: good values
      Test_Framework.Assert
        (Is_Valid_Value ("Hello, world!"),
         "valid_value: printable ASCII");
      Test_Framework.Assert
        (Is_Valid_Value ("x"),
         "valid_value: single char");

      --  Is_Valid_Value: bad values
      Test_Framework.Assert
        (not Is_Valid_Value (""),
         "valid_value: reject empty");

      declare
         Long_Val : constant String (1 .. 201) :=
           (others => 'a');
      begin
         Test_Framework.Assert
           (not Is_Valid_Value (Long_Val),
            "valid_value: reject >200 chars");
      end;
   end Run;

end Test_Validation;
