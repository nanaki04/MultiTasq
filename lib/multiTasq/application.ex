defmodule MultiTasq.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Registry, [:unique, MultiTasq.Registry]),
      supervisor(MultiTasq.TaskSupervisor, []),
      supervisor(MultiTasq.QueueSupervisor, []),
      supervisor(MultiTasq.MultiTaskSupervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MultiTasq.Supervisor)
  end
end
