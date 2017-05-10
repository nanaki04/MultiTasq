defmodule MultiTasq do
  @moduledoc """
  Module for handling simple queues, and keeping track of simultaneous process results.
  """

  @doc """
  Returns {:ok, pid}
  """
  def setup_queue() do
    MultiTasq.Queue.start_link()
  end

  @doc """
  Returns {:ok, pid}
  """
  def setup_queue(name) do
    MultiTasq.Queue.start_link(name)
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

  def setup_multitask() do

  end

  def setup_multitask(name) do

  end

  def add_multi_task(multitask_id, %MultiTasq.Task{} = task) do

  end

  def on_multitask_end(multitask_id, lambda) do

  end

  def run_multitask(multitask_id) do

  end

end
