--  ===================================================================
--  Dictionary.Router — Route Matching and Handler Dispatch
--  ===================================================================
--
--  The router is the bridge between the HTTP layer and the store.
--  It examines the method and path of a parsed request, calls the
--  appropriate validation / store / JSON operations, and builds
--  an HTTP response.
--
--  Design:
--    * Static dispatch — direct procedure calls per route.  No tagged
--      types or classwide operations.  Simple and predictable.
--    * The store is a package-level singleton in Dictionary.Store;
--      the router calls it directly.
--
--  Ada 2022 features used:
--    * Delta aggregates for building Response records
--    * Declare expressions (where clarity benefits)
--
--  ===================================================================

with Dictionary.HTTP;

package Dictionary.Router is

   function Handle_Request
     (Req : Dictionary.HTTP.Request)
      return Dictionary.HTTP.Response;
   --  Main dispatch entry point.  Matches method + path pattern,
   --  delegates to the appropriate handler, and returns the response.

end Dictionary.Router;
