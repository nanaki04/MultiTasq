defmodule MultiTasq.TaskSupervisor do
  @moduledoc """
  Module to supervise tasks being executed
  """

  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Task, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def execute_task(executable) do
    Supervisor.start_child(__MODULE__, [executable])
  end

end
