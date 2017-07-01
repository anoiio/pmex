defmodule ProcessManager do 

    defmacro __using__(opts) do
        quote do 
            import ProcessManager
            use GenServer
            require Logger
            
            defstruct [process_id: nil,
                       initial_step: unquote(opts[:initial_step]),
                       current_step: nil]

            @transitions Map.new
            @expanding_step_name nil

            def start_link(options) do
                 {:ok, pid} = GenServer.start_link(__MODULE__, options, [{:name, __MODULE__}])
                 GenServer.cast(pid, :start)
                 {:ok, pid}
            end

            def init(%{process_id: id}) do
                {:ok, %__MODULE__{process_id: id}}  
            end

            def handle_cast(event, state) do
                result = case handle_event(event, state) do
                    {:ok, :ok, new_state} -> {:noreply, new_state}
                    :error -> {:noreply, state}
                    {:stop, reason, state} -> {:stop, reason, state}
                    
                end
                result
            end

            def handle_info(:query, state) do
                Logger.debug "#{inspect __MODULE__}: Requesting events"
                EventsStream.request_all_events_async(self())
                schedule_query()
                {:noreply, state}
            end

            def schedule_query do
                Process.send_after(self(), :query, 10000) # In 10 sec
            end

            @before_compile ProcessManager
        end
    end

    defmacro __before_compile__(_env) do
        quote do
            unquote(create_transition_valiadation_func())
            unquote(create_handle_event_func())
            unquote(create_apply_step_transition_func())
        end
    end

    def go(step) do
        step
    end

    defmacro defstep(step_def, do: events_def) do
        quote do
            {step_name, timeout} = case unquote(Macro.escape(step_def, unquote: true)) do
                {name, _, [{:wait, _, [seconds]}]} -> {name, seconds}
                {name, _, _} -> {name, :no}
            end 

            @expanding_step_name step_name

            unquote(events_def)

            IO.puts "@transitions: #{inspect @transitions}"
         end
    end

    defmacro defevent(event_def, event) do
        quote do
            {event_name, _, _} = unquote(Macro.escape(event_def, unquote: true))
            event_definition = unquote(Macro.escape(event_def, unquote: true))
            event_body = unquote(Macro.escape(event, unquote: true))
            next_step = unquote(find_next_step(Macro.escape(event, unquote: true)))

            unquote(create_event_func())
            unquote(create_transition())
            unquote(create_step_func())
        end
    end

    def create_transition() do
        quote bind_quoted: [] do
            @transitions Map.put_new(@transitions, event_name, {@expanding_step_name, next_step})
        end
    end

    def create_step_func() do
        quote bind_quoted: [] do
            def unquote(next_step)() do
                unquote(next_step)
            end
        end
    end

    def create_event_func() do
        quote bind_quoted: [] do
            def unquote(event_definition) do
                unquote(event_body)
            end
        end
    end

    def create_transition_valiadation_func() do
        quote do
            def validate_transition(step, event) do          
                result = with {current_step, _} <- @transitions[event]
                do
                    valid = case current_step do
                        ^step -> true
                        _     -> false
                    end
                end

                result = case result do
                    nil     -> false
                    not_nil -> result
                end
            end
        end
    end

    def create_apply_step_transition_func() do
        quote do
            def apply_step_transition([do: :finish], state) do
                Logger.debug "#{inspect __MODULE__}: finished"         
                {:stop, :normal, state}
            end

            def apply_step_transition([do: next_step], state) do          
                {:ok, :ok, %__MODULE__{state | current_step: next_step}}
            end
        end
    end

    def find_next_step(event_body) do
        quote do
            next_step = case unquote(event_body) do
                [do: {:go, _, [{step, _, _}]}] -> step
                [do: {:__block__, _, body}] -> case List.last(body) do
                                                    {:go, _, [{step, _, _}]} -> step
                                                    {:finish, _, _} -> :finish
                                                end
            end
        end
    end

    def create_handle_event_func do
        quote do
            def handle_event({event_type, %{} = payload}, state) do
                {status, reason, state} = case valid = validate_transition(state.current_step, event_type) do
                    true  -> apply(__MODULE__, event_type, [payload])
                            |> apply_step_transition(state)
                    false ->  Logger.debug "#{inspect __MODULE__}: Invalid transition: state=#{inspect state.current_step}, event_type=#{inspect event_type}"
                            {:ok, :ok, state}          
                end

                {status, reason, state}
            end

            def handle_event(:start, state) do
                Logger.info "#{inspect __MODULE__}: started with #{inspect state.initial_step}"
                schedule_query()
                {:ok, :ok, %__MODULE__{state | current_step: state.initial_step}}
            end

            def handle_event(_, _) do
                 Logger.debug "#{inspect __MODULE__}: Unknown message"
                :error
            end
        end
    end

end