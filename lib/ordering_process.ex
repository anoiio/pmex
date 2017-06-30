defmodule OrderingProcess do
    use ProcessManager

    @initial_step :order_started
 
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

    ############################## Commands implementations #######################################

    # EventsStream.put({:product_selected, %{customer: 123, cid: 778899}})

    def request_payment(customer_id, cid) do
        Logger.info "Command exec: request_payment: customer_id=#{customer_id}, cid=#{cid}"
        # EventsStream.put({:payment_done, %{customer: 123}})
    end

    def complete_order(customer_id) do
        Logger.info "Command exec: complete_order: customer_id=#{customer_id}"
        # EventsStream.put({:order_closed, %{customer: 123, track_id: "EX32746932878CH"}})
    end

    def send_email(customer_id, track) do
        Logger.info "Command exec: send_email: customer_id=#{customer_id} track=#{track}"
    end

end