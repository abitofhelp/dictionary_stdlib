--  ===================================================================
--  Dictionary — Root Package
--  ===================================================================
--
--  This is the root namespace for the Dictionary REST microservice.
--  All child packages (Dictionary.Types, Dictionary.Store, etc.) live
--  under this hierarchy.
--
--  The package is Pure — it contains no state, no elaboration code,
--  and no dependencies.  It exists solely to anchor the child-package
--  naming tree.
--
--  ===================================================================

package Dictionary
   with Pure
is
   --  Intentionally empty.  All declarations live in child packages.
end Dictionary;
