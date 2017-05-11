defmodule MultiTasq.Task do
  @moduledoc """
  Datastructure representing a task to be handled by a Multitasq.Queue or Multitasq.Multitask
  """

  defstruct [:task_id,
    :value,
    :monitor_ref,
    :on_finished,
    {:handler, &__MODULE__.default_handler/1}]

  use GenServer

  def start_link(%MultiTasq.Task{} = task) do
    GenServer.start_link(__MODULE__, task, [])
  end

  def execute(task_id, on_finished) do
    GenServer.call(task_id, {:execute, task_id, on_finished})
  end

  def handle_call({:execute, task_id, on_finished}, _, %MultiTasq.Task{value: value, handler: handler} = task) do
    {:ok, handler_id} = Task.start(fn ->
      value = handler.(value)
      GenServer.call(task_id, {:update_value, value})
    end)
    {:ok, task} = monitor(handler_id, on_finished, task)
    {:reply, {:ok, task}, task}
  end

  def handle_call({:update_value, value}, _, task) do
    {:reply, {:ok, value}, Map.put(task, :value, value)}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, %MultiTasq.Task{monitor_ref: monitor_ref} = task) when ref === monitor_ref do
    task.on_finished.(task.value)
    {:stop, :normal, task}
  end

  defp monitor(handler_id, on_finished, task) do
    monitor_ref = Process.monitor(handler_id)
    task = task
    |> Map.put(:monitor_ref, monitor_ref)
    |> Map.put(:on_finished, on_finished)
    {:ok, task}
  end

  def default_handler(_value), do: {:error, :no_handler_set}
end
