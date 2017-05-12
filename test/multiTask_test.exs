defmodule MultiTasq.MultiTaskTest do
  use ExUnit.Case
  doctest MultiTasq.MultiTask

  setup do
    IO.puts "\nInitializing a MultiTasq.MultiTask with name :m"
    MultiTasq.MultiTaskSupervisor.start_multitask(:m)

    task = %MultiTasq.Task{task_id: :task_1, handler: fn(_) ->
      :timer.sleep(100)
      IO.puts("task 1 done")
      {:task_1, :done}
    end}

    task2 = %MultiTasq.Task{task_id: :task_2, handler: fn(_) ->
      :timer.sleep(200)
      IO.puts("task 2 done")
      {:task_2, :done}
    end}

    task3 = %MultiTasq.Task{handler: fn(_) ->
      :timer.sleep(150)
      IO.puts("task 3 done")
      {:task_3, :done}
    end}

    [task: task, task2: task2, task3: task3]
  end

  test "push a task", context do
    MultiTasq.MultiTask.push(:m, context[:task])
    %MultiTasq.MultiTask{task_list: task_list} = MultiTasq.MultiTask.get_state!(:m)
    assert hd(task_list) === context[:task]
  end

  test "run all tasks simultaneously", context do
    MultiTasq.MultiTask.push(:m, context[:task])
    MultiTasq.MultiTask.push(:m, context[:task2])
    MultiTasq.MultiTask.push(:m, context[:task3])
    MultiTasq.MultiTask.run(:m, fn(val) ->
      assert [task_2: :done, task_3: :done, task_1: :done] = val
    end)
    :timer.sleep(250)
  end

end
