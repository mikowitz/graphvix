defmodule Writer do
  @moduledoc false
  def write(%{nodes: nodes, edges: edges}) do
    [
      "digraph G {",
      (nodes |> Enum.map(&node_to_dot/1)),
      "",
      (edges |> Enum.map(&edge_to_dot/1)),
      "}"
    ] |> List.flatten |> Enum.join("\n")
  end

  def save(dot, filename) do
    File.write(filename <> ".dot", dot)
    filename
  end

  def compile(filename) do
    System.cmd("dot", ["-Tpdf", filename <> ".dot", "-o", filename <> ".pdf"])
    filename
  end

  def open(filename) do
    System.cmd("open", [filename <> ".pdf"])
  end

  defp node_to_dot({id, %{attrs: attrs}}) do
    [
      "  node_#{id}",
      attrs_to_dot(attrs)
    ] |> Enum.reject(&is_nil/1) |> Enum.join(" ") |> Kernel.<>(";")
  end

  defp edge_to_dot({_id, %{start_node: n1_id, end_node: n2_id, attrs: attrs}}) do
    [
      "  node_#{n1_id}",
      "->",
      "node_#{n2_id}",
      attrs_to_dot(attrs)
    ] |> Enum.reject(&is_nil/1) |> Enum.join(" ") |> Kernel.<>(";")
  end

  defp attrs_to_dot(attrs) do
    case attrs do
      [] -> nil
      _ ->
        attr_str = attrs
        |> Enum.map(fn {k, v} ->
          "#{k}=\"#{v}\""
        end) |> Enum.join(",")
        "[" <> attr_str <> "]"
    end
  end
end
