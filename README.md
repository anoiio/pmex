# pmex

Application with a process manager writted in Elixir.

pmex starting with EventsStream and OrderingProcess already running and subscribed.

### Example of process definition

```elixir
defmodule OrderingProcess do
    use ProcessManager, initial_step: :order_started
 
    ######################################## Steps definitions ###################################

    defstep order_started do
        defevent product_selected(%{customer: customer_id, cid: cid}) do
            request_payment(customer_id, cid)
            go await_payment
        end 
    end

    defstep await_payment do
        defevent payment_done(%{customer: customer_id}) do
            complete_order(customer_id)
            go order_confirmation
        end
    end

    defstep order_confirmation do
        defevent order_closed(%{customer: customer_id, track_id: track}) do
            send_email(customer_id, track)
            finish
        end 
    end

    ############################## Process initialization (Should follow definition) ##############

    init_process

    ############################## Commands implementations #######################################

    def request_payment(customer_id, cid) do
        IO.puts "Print: request_payment: customer_id=#{customer_id}, cid=#{cid}"
    end

    def complete_order(customer_id) do
        IO.puts "Print: complete_order: customer_id=#{customer_id}"
    end

    def send_email(customer_id, track) do
        IO.puts "Print: send_email: customer_id=#{customer_id} track=#{track}"
    end

end
```

### Step definition

```Elixir
defstep order_started do # step name
  defevent product_selected(%{customer: customer_id, cid: cid}) do # event name and its paremeters
    request_payment(customer_id, cid) # command that should be sent when event received
    go await_payment # next step
  end 
end
```

### In order to proceed with the ordering process, submit following events to EventsStream:

1. EventsStream.put({:product_selected, %{customer: 123, cid: 778899}})
2. EventsStream.put({:payment_done, %{customer: 123}})
3. EventsStream.put({:order_closed, %{customer: 123, track_id: "EX32746932878CH"}})