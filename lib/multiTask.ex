defmodule MultiTasq.MultiTask do
  @moduledoc """
  Module for handling multiple tasks simultaneously, and returning the results
  """

  defstruct [:multi_id,
    {:value, []},
    {:task_list, []},
    {:task_progress, %{}},
    {:running, false},
    {:on_finished, &__MODULE__.default_on_finished/1}]

  use GenServer

  def start_link() do
    {:ok, multi_pid} = GenServer.start_link(__MODULE__, %MultiTasq.MultiTask{}, [])
    update_state(multi_pid, multi_id: multi_pid)
    {:ok, multi_pid}
  end

  def start_link(name) do
    multi = GenServer.start_link(__MODULE__, %MultiTasq.MultiTask{}, name: name)
    update_state(name, multi_id: name)
    multi
  end

  def stop(multi_id) do
    GenServer.stop(multi_id)
  end

  def push(multi_id, %MultiTasq.Task{} = task), do:
    GenServer.call(multi_id, {:push, task})

  def run(multi_id, on_finished) do
    {:ok, state} = update_state(multi_id, on_finished: on_finished)
    Enum.each(state.task_list, fn(task) -> run_single_task(multi_id, task) end)
    {:ok, state}
  end

  def on_task_finished(multi_id, task_id, value), do:
    GenServer.call(multi_id, {:on_finished, {task_id, value}})

  def push_value(multi_id, value), do:
    GenServer.call(multi_id, {:push_value, value})

  def update_state(multi_id, key_value_list), do:
    GenServer.call(multi_id, {:update_state, key_value_list})

  def get_state(multi_id), do:
    GenServer.call(multi_id, :get_state)

  def get_state!(multi_id) do
    {:ok, state} = get_state(multi_id)
    state
  end

  defp run_single_task(multi_id, %MultiTasq.Task{task_id: task_id} = task) do
    MultiTasq.TaskSupervisor.execute_task(task, fn(value) ->
      on_task_finished(multi_id, task_id, value)
    end)
  end

  def handle_call({:push, %MultiTasq.Task{task_id: nil} = task}, _, %MultiTasq.MultiTask{task_list: task_list} = state) do
    push_task_with_id(task, length(task_list), state)
  end

  def handle_call({:push, %MultiTasq.Task{task_id: task_id} = task}, _, state) do
    push_task_with_id(task, task_id, state)
  end

  def handle_call({:on_finished, {task_id, value}}, _, state) do
    state = state
    |> Map.put(:value, [value | state.value])
    |> Map.put(:task_progress, Map.put(state.task_progress, task_id, :done))
    if is_done?(state.task_progress) do
      state.on_finished.(state.value)
      {:stop, :normal, {:ok, state}, state}
    else
      {:reply, {:ok, state}, state}
    end
  end

  def handle_call({:update_state, key_value_list}, _, state) do
    state = Enum.reduce(key_value_list, state, fn({key, value}, state) -> Map.put(state, key, value) end)
    {:reply, {:ok, state}, state}
  end

  def handle_call(:get_state, _, state), do:
    {:reply, {:ok, state}, state}

  def handle_call({:push_value, value}, _, %MultiTasq.MultiTask{value: value_list} = state) do
    state = Map.put(state, :value, [value | value_list])
    {:reply, {:ok, state}, state}
  end

  def default_on_finished(_value), do:
    {:error, :on_finished_not_set}

  defp is_done?(task_progress) do
    Enum.reduce(task_progress, true, fn
      {_, :in_progress}, _ -> false
      {_, :done}, is_done -> is_done
    end)
  end

  defp push_task_with_id(task, task_id, %MultiTasq.MultiTask{task_list: task_list} = state) do
    unless Map.has_key?(state.task_progress, task_id) do
      task = Map.put(task, :task_id, task_id)
      task_progress = Map.put(state.task_progress, task_id, :in_progress)
      state = state
      |> Map.put(:task_list, [task | task_list])
      |> Map.put(:task_progress, task_progress)
      {:reply, {:ok, state}, state}
    else
      {:reply, {:error, :duplicate_task_id}, state}
    end
  end

end
