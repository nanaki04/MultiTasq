defmodule MultiTasq.MultiTaskSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_queue(name) do
    Supervisor.start_child(__MODULE__, [name])
  end

  def init(:ok) do
    children = [
      worker(MultiTasq.MultiTask, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
