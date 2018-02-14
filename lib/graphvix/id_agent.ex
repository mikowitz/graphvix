defmodule Graphvix.IdAgent do
  @moduledoc false

  def next do
    Agent.get_and_update(agent, &{&1, &1 + 1})
  end

  def clear do
    Agent.stop(agent)
    agent()
  end

  defp agent do
    case Agent.start(fn -> 1 end, name: :id_agent) do
      {:ok, agent} -> agent
      {:error, {:already_started, agent}} -> agent
    end
  end
end
