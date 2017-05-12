defmodule MultiTasq do
  @moduledoc """
  Module for handling simple queues, and keeping track of simultaneous process results.
  """

  @doc """
  Returns {:ok, pid}
  """
  def setup_queue() do
    MultiTasq.QueueSupervisor.start_queue()
  end

  @doc """
  Returns {:ok, pid}
  """
  def setup_queue(name) do
    MultiTasq.QueueSupervisor.start_queue(name)
  end

  @doc """
  Returns :ok
  """
  def stop_queue(queue) do
    MultiTasq.Queue.stop(queue)
  end

  @doc """
  Returns {:ok, %MultiTasq.Queue{}}
  """
  def add_queue_task(queue, %MultiTasq.Task{} = task) do
    MultiTasq.Queue.push(queue, task)
  end

  @doc """
  Returns {:ok, %MultiTasq.Queue{}}
  """
  def run_queue(queue) do
    MultiTasq.Queue.run(queue)
  end

  @doc """
  Returns {:ok, %MultiTasq.Queue{}}
  """
  def pause_queue(queue) do
    MultiTasq.Queue.pause(queue)
  end

  @doc """
  Returns {:ok, %MultiTasq.Queue{}}
  """
  def resume_queue(queue) do
    MultiTasq.Queue.resume(queue)
  end

  @doc """
  Returns {:ok, %MultiTasq.Queue{}}
  """
  def open_queue_floodgate(queue) do
    MultiTasq.Queue.open_floodgate(queue)
  end

  @doc """
  Returns {:ok, %MultiTasq.Queue{}}
  """
  def close_queue_floodgate(queue) do
    MultiTasq.Queue.close_floodgate(queue)
  end

  @doc """
  Returns {:ok, pid}
  """
  def setup_multitask() do
    MultiTasq.MultiTaskSupervisor.start_multitask()
  end

  @doc """
  Returns {:ok, pid}
  """
  def setup_multitask(name) do
    MultiTasq.MultiTaskSupervisor.start_multitask(name)
  end

  @doc """
  Returns :ok
  """
  def stop_multitask(multitask_id) do
    MultiTasq.MultiTask.stop(multitask_id)
  end

  @doc """
  Returns {:ok, %MultiTasq.MultiTask{}}
  """
  def add_multi_task(multitask_id, %MultiTasq.Task{} = task) do
    MultiTasq.MultiTask.push(multitask_id, task)
  end

  @doc """
  Returns {:ok, %MultiTasq.MultiTask{}}
  """
  def run_multitask(multitask_id, on_finished) do
    MultiTasq.MultiTask.run(multitask_id, on_finished)
  end

end
