defmodule MultiTasq.Queue do
  @moduledoc """
  Module for handling simple sequential queues
  """

  defstruct [:queue_id, # the pid or registered name of the MultiTasq.Queue process
    :value, # value to be passed and edited or accumulated from task to task
    {:entrance_hall, []}, # tasks being pushed are received here, and either be executed automatically in order when the floodgate is open, or hold until further notice when the floodgate is closed
    {:ready_for_execution, []}, # tasks to be executed one by one regardless of the floodgate status
    {:floodgate, :open}, # do new tasks pushed while processing get processed automatically, or hold until re-opened
    {:paused, false}, # is queue processing on hold by an outside call of the pause method
    {:running, false}, # has the queue run been called or not
    {:processing, false}] # is one of the queues tasks currently being processed

  # need genServer to be able to store new tasks while executing
  use GenServer

  # Start

  def start_link() do
    {:ok, queue_pid} = GenServer.start_link(__MODULE__, %MultiTasq.Queue{}, [])
    update_state(queue_pid, queue_id: queue_pid)
    {:ok, queue_pid}
  end

  def start_link(name) do
    queue = GenServer.start_link(__MODULE__, %MultiTasq.Queue{}, name: name)
    update_state(name, queue_id: name)
    queue
  end

  # Push Tasks

  def push(queue, %MultiTasq.Task{} = task), do:
    GenServer.call(queue, {:push, task})

  # Run

  def run(queue) do
    {:ok, state} = update_state(queue, running: true)
    run_next_task(queue, state)
  end

  # Loop Task Execution Handlers

  def run_next_task(queue), do:
    run_next_task(queue, get_state!(queue))

  def run_next_task(queue, %MultiTasq.Queue{paused: true}), do:
    update_state(queue, processing: false)

  def run_next_task(queue, %MultiTasq.Queue{ready_for_execution: [], entrance_hall: []}), do:
    update_state(queue, processing: false)

  def run_next_task(queue, %MultiTasq.Queue{ready_for_execution: [], floodgate: :closed}), do:
    update_state(queue, processing: false)

  def run_next_task(queue, %MultiTasq.Queue{ready_for_execution: [], floodgate: :open} = state) do
    {:ok, state} = update_state(queue,
      ready_for_execution: Enum.reverse(state.entrance_hall),
      entrance_hall: []
    )
    run_executable(state)
  end

  def run_next_task(_queue, state) do
    run_executable(state)
  end

  def on_task_finished(queue, value) do
    update_state(queue, value: value)
    run_next_task(queue)
  end

  # Floodgate Maintenance

  def open_floodgate(queue_id), do:
    open_floodgate(queue_id, get_state!(queue_id))

  def open_floodgate(_queue_id, %MultiTasq.Queue{floodgate: :open}, state), do: state

  def open_floodgate(queue_id, %MultiTasq.Queue{running: false} = state) do
    push_entrance_hall_members(state)
    update_state(queue_id, floodgate: :open)
  end

  def open_floodgate(queue_id, %MultiTasq.Queue{queue_id: queue_id, processing: false}) do
    update_state(queue_id, floodgate: :open)
    run_next_task(queue_id)
  end

  def close_floodgate(queue_id), do:
    close_floodgate(queue_id, get_state!(queue_id))

  def close_floodgate(queue_id, state) do
    push_entrance_hall_members(state)
    update_state(queue_id, floodgate: :closed)
  end

  # Pause and Resume

  def pause(queue_id), do:
    update_state(queue_id, paused: true)

  def resume(queue_id), do:
    resume(queue_id, get_state!(queue_id))

  def resume(queue_id, %MultiTasq.Queue{processing: true}), do:
    update_state(queue_id, paused: false)

  def resume(queue_id, %MultiTasq.Queue{running: false}), do:
    update_state(queue_id, paused: false)

  def resume(queue_id, _state) do
    {:ok, state} = update_state(queue_id, paused: false)
    run_next_task(queue_id, state)
  end

  # Generic State Updater

  def update_state(queue, key_value_list), do:
    GenServer.call(queue, {:update_state, key_value_list})

  def get_state(queue), do:
    GenServer.call(queue, :get_state)

  def get_state!(queue) do
    {:ok, state} = get_state(queue)
    state
  end

  # Private

  defp push_entrance_hall_members(%MultiTasq.Queue{queue_id: queue_id, entrance_hall: entrance_hall, ready_for_execution: ready_for_execution}) do
    update_state(queue_id,
      ready_for_execution: ready_for_execution ++ Enum.reverse(entrance_hall),
      entrance_hall: []
    )
  end

  defp run_executable(%MultiTasq.Queue{ready_for_execution: []} = state), do:
    state
  defp run_executable(%MultiTasq.Queue{queue_id: queue_id, value: value, ready_for_execution: ready_for_execution}) do
    task = hd(ready_for_execution)
    {:ok, state} = update_state(queue_id, 
      ready_for_execution: tl(ready_for_execution),
      processing: true
    )
    executable = MultiTasq.Task.get_executable(task, queue_id, value, &MultiTasq.Queue.on_task_finished/2)
    MultiTasq.TaskSupervisor.execute_task(executable)
    state
  end

  # Server Callbacks

  # Push Tasks

  def handle_call({:push, task}, _, %MultiTasq.Queue{entrance_hall: []} = state), do:
    {:reply, {:ok, state}, Map.put(state, :entrance_hall, [task])}
  def handle_call({:push, task}, _, %MultiTasq.Queue{} = state), do:
    {:reply, {:ok, state}, Map.put(state, :entrance_hall, [task | state.entrance_hall])}

  # Generic State Updater

  def handle_call({:update_state, key_value_list}, _, state) do
    state = Enum.reduce(key_value_list, state, fn({key, value}, state) -> Map.put(state, key, value) end)
    {:reply, {:ok, state}, state}
  end

  def handle_call(:get_state, _, state), do:
    {:reply, {:ok, state}, state}
end
