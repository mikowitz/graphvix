defmodule Graphvix.Record.Port do
  defstruct [
    body: nil,
    port_name: nil
  ]

  def new(body, port_name) do
    %__MODULE__{body: body, port_name: port_name}
  end

  def to_label(port) do
    "<#{port.port_name}> #{port.body}"
  end
end


