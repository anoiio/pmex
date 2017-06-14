defmodule App do
  use Application

   def start(_,_) do
        EventsStream.start_link()
        OrderingProcess.start_link(%{process_id: 123})
   end
  end