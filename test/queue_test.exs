defmodule MultiTasq.QueueTest do
  use ExUnit.Case
  doctest MultiTasq.Queue

  setup do
    IO.puts "\nInitializing a MultiTasq.Queue with name :q"
    MultiTasq.Queue.start_link(:q)

    task = %MultiTasq.Task{handler: fn(id, _val, done) ->
      IO.puts("task 1 procced")
      :timer.sleep(100)
      done.(id, [:task_1_done])
    end}

    task2 = %MultiTasq.Task{handler: fn(id, val, done) ->
      IO.puts("task 2 procced")
      assert val === [:task_1_done]
      done.(id, [:task_2_done | val])
    end}

    [task: task, task2: task2]
  end

  test "push a task", context do
    task = context[:task]
    MultiTasq.Queue.push(:q, task)
    {:ok, state} = MultiTasq.Queue.get_state(:q)
    assert hd(state.entrance_hall) === task
  end

  test "run all tasks one by one", context do
    task = context[:task]
    task2 = context[:task2]
    MultiTasq.Queue.push(:q, task)
    MultiTasq.Queue.push(:q, task2)
    MultiTasq.Queue.run(:q)
    :timer.sleep(200)
  end

  test "push a task while executing another should run the task when the first is done", context do
    task = context[:task]
    task2 = context[:task2]
    MultiTasq.Queue.push(:q, task)
    MultiTasq.Queue.run(:q)
    :timer.sleep(50)
    MultiTasq.Queue.push(:q, task2)
    :timer.sleep(150)
  end

  test "push a task while another task is finished should run the task automatically", context do
    task = context[:task]
    task2 = context[:task2]
    MultiTasq.Queue.push(:q, task)
    MultiTasq.Queue.run(:q)
    :timer.sleep(150)
    MultiTasq.Queue.push(:q, task2)
    :timer.sleep(50)
  end

  test "push a task after having called run and having the floodgate close does not run the task automatically", context do
    task = context[:task]
    task2 = context[:task2]
    MultiTasq.Queue.push(:q, task)
    MultiTasq.Queue.run(:q)
    MultiTasq.Queue.close_floodgate(:q)
    MultiTasq.Queue.push(:q, task2)
    :timer.sleep(200)
    {:ok, state} = MultiTasq.Queue.get_state(:q)
    assert hd(state.entrance_hall) === task2
  end

  test "re-opening the floodgate with tasks waiting behind the gate will execute them", context do
    task = context[:task]
    task2 = context[:task2]
    MultiTasq.Queue.push(:q, task)
    MultiTasq.Queue.run(:q)
    MultiTasq.Queue.close_floodgate(:q)
    MultiTasq.Queue.push(:q, task2)
    :timer.sleep(150)
    MultiTasq.Queue.open_floodgate(:q)
    :timer.sleep(50)
    {:ok, state} = MultiTasq.Queue.get_state(:q)
    assert length(state.entrance_hall) === 0
  end

  test "pausing the queue and calling run theirafter will not run any tasks", context do
    task = context[:task]
    MultiTasq.Queue.push(:q, task)
    MultiTasq.Queue.pause(:q)
    MultiTasq.Queue.run(:q)
    :timer.sleep(150)
    {:ok, state} = MultiTasq.Queue.get_state(:q)
    assert state.value === nil
  end

  test "resuming a paused queue with tasks waiting will run the queued tasks", context do
    task = context[:task]
    task2 = context[:task2]
    MultiTasq.Queue.push(:q, task)
    MultiTasq.Queue.push(:q, task2)
    MultiTasq.Queue.run(:q)
    :timer.sleep(50)
    MultiTasq.Queue.pause(:q)
    :timer.sleep(100)
    {:ok, state} = MultiTasq.Queue.get_state(:q)
    assert state.value === [:task_1_done]
    MultiTasq.Queue.resume(:q)
    :timer.sleep(50)
    {:ok, state} = MultiTasq.Queue.get_state(:q)
    assert state.value === [:task_2_done, :task_1_done]
  end
end
