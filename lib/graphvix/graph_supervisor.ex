defmodule Graphvix.GraphSupervisor do
  use Supervisor

  def start_link(state_pid) do
    Supervisor.start_link(__MODULE__, [state_pid])
  end

  def init(state_pid) do
    children = [worker(Graphvix.Graph, state_pid)]
    supervise(children, strategy: :one_for_one)
  end
end
