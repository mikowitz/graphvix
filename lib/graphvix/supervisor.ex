defmodule Graphvix.Supervisor do
  use Supervisor

  def start_link do
    result = {:ok, sup} = Supervisor.start_link(__MODULE__, [])
    start_workers(sup)
    result
  end

  def start_workers(sup) do
    {:ok, state_pid} = Supervisor.start_child(sup, worker(Graphvix.State, []))
    Supervisor.start_child(sup, supervisor(Graphvix.GraphSupervisor, [state_pid]))
  end

  def init(_) do
    supervise([], strategy: :one_for_one)
  end
end
