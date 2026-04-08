--  ===================================================================
--  Dictionary.Server — TCP Listener with Task-Per-Connection
--  ===================================================================
--
--  This package implements the HTTP server using only Ada standard
--  library networking (GNAT.Sockets).  It demonstrates:
--
--    * TCP socket lifecycle: create, bind, listen, accept, close
--    * Ada task types for concurrent connection handling
--    * Entry calls for passing the socket to a worker task
--    * Converting between Stream_Element_Array and String
--
--  Design:
--    * The Start procedure creates a listening socket and enters an
--      infinite accept loop.
--    * Each accepted connection spawns a dynamically allocated
--      Connection_Task that reads the HTTP request, dispatches
--      through the router, sends the response, and closes the socket.
--    * Connection: close is sent on every response, so each task
--      handles exactly one request then terminates.
--
--  Scope limitations (intentional for teaching):
--    * No graceful shutdown (Ctrl+C terminates the process).
--    * No read timeout on sockets.
--    * Dynamically allocated tasks leak memory on termination.
--      A production server would use a bounded task pool.
--    * HTTP only — no TLS.  See README for rationale.
--
--  ===================================================================

with GNAT.Sockets;

package Dictionary.Server is

   Default_Port : constant GNAT.Sockets.Port_Type := 8080;

   procedure Start
     (Port : GNAT.Sockets.Port_Type := Default_Port);
   --  Start the HTTP server on the given port.  This procedure
   --  does not return — it runs an infinite accept loop.
   --  Terminate with Ctrl+C.

end Dictionary.Server;
