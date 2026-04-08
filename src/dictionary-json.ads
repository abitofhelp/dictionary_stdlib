--  ===================================================================
--  Dictionary.JSON — Hand-Rolled JSON Parse / Serialize
--  ===================================================================
--
--  Minimal JSON handling for the dictionary's two payload shapes:
--
--  Incoming (request bodies):
--    {"key":"<key>","value":"<value>"}    — for POST
--    {"value":"<value>"}                  — for PUT
--
--  Outgoing (response bodies):
--    {"key":"…","value":"…"}             — single entry
--    [{"key":"…","value":"…"}, …]        — entry list
--    {"error":"…"}                       — error message
--    {"status":"healthy"}                — health check
--
--  Why hand-rolled?
--    The Ada standard library has no JSON support.  For the simple
--    payloads this service uses, a full parser is overkill.  We scan
--    for known field names and extract quoted string values.  This
--    approach teaches how JSON is structured at the byte level.
--
--  Limitations (documented as teaching points):
--    * No nested objects or arrays in request bodies.
--    * Only \" and \\ escape sequences are handled.
--    * No Unicode escape (\uXXXX) support.
--    * Response serialization does not escape special characters in
--      values — this is safe because our validation rejects all
--      characters outside printable ASCII, and we never store
--      backslashes or quotes in values.
--
--  Ada 2022 features used:
--    * Quantified expressions in contracts
--    * Ada.Strings.Unbounded for response building
--
--  ===================================================================

with Ada.Strings.Unbounded;

with Dictionary.Types; use Dictionary.Types;

package Dictionary.JSON is

   --  ---------------------------------------------------------------
   --  Parse result — incoming JSON
   --  ---------------------------------------------------------------

   type Parse_Status is (OK, Malformed);
   --  The parser extracts whatever fields are present without
   --  enforcing which fields are required.  Endpoint-specific
   --  presence rules (e.g., POST requires both key and value,
   --  PUT requires only value) are enforced by the router.

   type Parse_Result is record
      Status    : Parse_Status := Malformed;
      Key_Str   : Ada.Strings.Unbounded.Unbounded_String;
      Value_Str : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   function Parse_Entry (Body_Text : String) return Parse_Result;
   --  Extract "key" and "value" fields from a JSON object.
   --  On success, Status = OK and Key_Str / Value_Str hold the
   --  extracted plain-text values (quotes and escapes removed).
   --  Either field may be empty if absent from the input.
   --  If no recognizable fields are found, Status = Malformed.

   --  ---------------------------------------------------------------
   --  Serialization — outgoing JSON
   --  ---------------------------------------------------------------

   function Serialize_Entry (E : Entry_Record) return String;
   --  {"key":"…","value":"…"}

   function Serialize_Entry_List
     (List : Entry_List) return String;
   --  [{"key":"…","value":"…"},…]  (may be empty: [])

   function Serialize_Error (Message : String) return String;
   --  {"error":"…"}

   function Serialize_Health return String;
   --  {"status":"healthy"}

end Dictionary.JSON;
