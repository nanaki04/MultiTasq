defmodule MultiTasq.Task do
  @moduledoc """
  Datastructure representing a task to be handled by a Multitasq.Queue or Multitasq.Multitask
  """

  defstruct handler: &__MODULE__.default_handler/3

  def get_executable(task, id, value, done) do
    fn ->
      task.handler.(id, value, done)
    end
  end

  def default_handler(id, _value, done), do: done.(id, {:error, :no_handler_set})
end
