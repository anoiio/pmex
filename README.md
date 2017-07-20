# pmex A

Purpose of this application is a case stady of implementing DSL for process manager in Elixir. <br />
EventsStream, subscription to EventsStream and pulling mechanisms implemented solelly as a mockup in order to drive process manager.

pmex starting with EventsStream and OrderingProcess already running and subscribed.

### Example of process definition

```elixir
defmodule OrderingProcess do
    use ProcessManager, initial_step: :start

    ######################################## Steps definitions ###################################

    defstep start do
        defevent order_started(%{customer: customer_id, order: order_id}) do
            open_shopping_cart(customer_id, order_id)
            go product_selection
        end
    end

    defstep product_selection do
        defevent product_selected(%{order: order_id, product: product_id}) do
            add_to_cart(order_id, product_id)
            go product_selection
        end

        defevent product_removed(%{order: order_id, product: product_id}) do
            remove_from_cart(order_id, product_id)
            go product_selection
        end

        defevent selection_completed(%{order: order_id}) do
            request_payment(order_id)
            go await_payment
        end 
    end

    defstep await_payment do
        defevent payment_done(%{order: order_id}) do
            complete_order(order_id)
            go order_confirmation
        end

        defevent payment_failed(%{order: order_id}) do
            cancel_order(order_id)
            go cancel_confirmation
        end
    end

    defstep order_confirmation do
        defevent order_closed(%{customer: customer_id, track_id: track}) do
            send_email(customer_id, track)
            finish
        end 
    end

    defstep cancel_confirmation do
        defevent order_canceled(%{customer: customer_id, order: order_id}) do
            send_cancelation_email(customer_id, order_id)
            finish
        end 
    end

    ############################## Commands implementations #######################################

    def open_shopping_cart(customer_id, order_id) do
        Logger.info "Command exec: open_shopping_cart: customer_id=#{customer_id}, order_id=#{order_id}"
    end

    def add_to_cart(order_id, product_id) do
        Logger.info "Command exec: add_to_cart: order_id=#{order_id}, product_id=#{product_id}"
    end

    def remove_from_cart(order_id, product_id) do
        Logger.info "Command exec: remove_from_cart: order_id=#{order_id}, product_id=#{product_id}"
    end

    def request_payment(order_id) do
        Logger.info "Command exec: request_payment: order_id=#{order_id}"
    end

    def complete_order(order_id) do
        Logger.info "Command exec: complete_order: order_id=#{order_id}"
    end

    def cancel_order(order_id) do
        Logger.info "Command exec: cancel_order: order_id=#{order_id}"
    end

    def send_email(customer_id, track) do
        Logger.info "Command exec: send_email: customer_id=#{customer_id} track=#{track}"
    end

    def send_cancelation_email(customer_id, order_id) do
        Logger.info "Command exec: send_cancelation_email: customer_id=#{customer_id} order_id=#{order_id}"
    end

end
```

### Step definition

```Elixir
defstep start do #step name
        defevent order_started(%{customer: customer_id, order: order_id}) do #event name and its payload paremeters
            open_shopping_cart(customer_id, order_id) #command that should be sent when event received
            go product_selection #next step
        end
end
```

1. Step can have several events.
2. Each event can define different next step.
3. Next step can be same or other step.

### Command functions should be implemented in the module

```Elixir
def open_shopping_cart(customer_id, order_id) do
        Logger.info "Command exec: open_shopping_cart: customer_id=#{customer_id}, order_id=#{order_id}"
end
```

### In order to proceed with the ordering process, submit following events to EventsStream:

#### Case 1
EventsStream.put({:order_started, %{customer: 123, order: 778899}}) <br />
EventsStream.put({:product_selected, %{order: 778899, product: 67890000}}) <br />
EventsStream.put({:product_removed, %{order: 778899, product: 67890000}}) <br />
EventsStream.put({:product_selected, %{order: 778899, product: 67890001}}) <br />
EventsStream.put({:product_selected, %{order: 778899, product: 67890002}}) <br />
EventsStream.put({:selection_completed, %{order: 778899}}) <br />
EventsStream.put({:payment_done, %{order: 778899}}) <br />
EventsStream.put({:order_closed, %{customer: 123, track_id: "EX32746932878CH"}}) <br />

#### Case 2
EventsStream.put({:order_started, %{customer: 123, order: 778899}}) <br />
EventsStream.put({:product_selected, %{order: 778899, product: 67890000}}) <br />
EventsStream.put({:product_removed, %{order: 778899, product: 67890000}}) <br />
EventsStream.put({:product_selected, %{order: 778899, product: 67890001}}) <br />
EventsStream.put({:product_selected, %{order: 778899, product: 67890002}}) <br />
EventsStream.put({:selection_completed, %{order: 778899}})<br />
EventsStream.put({:payment_failed, %{order: 778899}}) <br />
EventsStream.put({:order_canceled, %{customer: 123, order: 778899}}) <br />