defmodule OrderingProcess do
    use ProcessManager, initial_step: :order_started
 
    defstep order_started do
        defevent product_selected(%{customer: customer_id, cid: cid}) do
            request_payment(customer_id, cid)
            go await_payment
        end 
    end

    defstep await_payment do
        defevent payment_done(%{customer: customer_id, cid: cid}) do
            complete_order(customer_id, cid)
            go order_confirmation
        end
    end

    defstep order_confirmation do
        defevent order_closed(%{customer: customer_id, cid: cid}) do
            send_email(customer_id, cid)
            finish
        end 
    end

    init_process

    def request_payment(customer_id, cid) do
        IO.puts "Print: request_payment: customer_id=#{customer_id}, cid=#{cid}"
    end

    def complete_order(customer_id, cid) do
        IO.puts "Print: complete_order: customer_id=#{customer_id}, cid=#{cid}"
    end

    def send_email(customer_id, cid) do
        IO.puts "Print: send_email: customer_id=#{customer_id}, cid=#{cid}"
    end
end