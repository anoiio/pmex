defmodule EventsStream do
use GenServer

    def start_link do
        GenServer.start_link(__MODULE__, [], [{:name, __MODULE__}])
    end

    def init([]) do
        {:ok, :queue.new} 
    end

    def put(event) do
         GenServer.cast(__MODULE__, {:put, event})
    end

    def request_all_events_async(subscriber) do
         GenServer.cast(__MODULE__, {:get, subscriber})
    end

    def handle_cast({:put, event}, queue) do
        IO.puts "EventsStream: putting event=#{inspect event} into queue=#{inspect queue}"
        {:noreply, :queue.in(event, queue)}
    end

    def handle_cast({:get, subscriber}, queue) do
        IO.puts "EventsStream: events requested"
        send_events(:queue.out(queue), subscriber)
        {:noreply, :queue.new}
    end

    def send_events({{:value, event}, queue}, to) do
        GenServer.cast(to, event)
        IO.puts "EventsStream: event=#{inspect event} sent"
        send_events(:queue.out(queue), to)
    end

    def send_events({:empty, _}, _) do

    end

    

end