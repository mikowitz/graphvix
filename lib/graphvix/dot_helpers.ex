defmodule Graphvix.DotHelpers do
  def global_properties_to_dot(graph) do
    global_props = [
      _global_properties_to_dot(graph, :node),
      _global_properties_to_dot(graph, :edge)
    ] |> Enum.reject(&is_nil/1)

    case length(global_props) do
      0 -> nil
      _ -> Enum.join(global_props, "\n")
    end
  end

  def attributes_to_dot([]), do: nil
  def attributes_to_dot(attributes) do
    [
      "[",
      Enum.map(attributes, fn {key, value} ->
        attribute_to_dot(key, value)
      end) |> Enum.join(","),
      "]"
    ] |> Enum.join("")
  end

  def attribute_to_dot(key, value) do
    ~s(#{key}="#{value}")
  end

  def indent(indentee, depth \\ 1)
  def indent(string, depth) when is_bitstring(string) do
    string
    |> String.split("\n")
    |> indent(depth)
    |> Enum.join("\n")
  end
  def indent(list, depth) when is_list(list) do
    Enum.map(list, fn s -> String.duplicate("  ", depth) <> s end)
  end

  def elements_to_dot(table, formatting_func) when is_reference(table) do
    :ets.tab2list(table) |> elements_to_dot(formatting_func)
  end
  def elements_to_dot(list, formatting_func) when is_list(list) do
    list
    |> sort_elements_by_id()
    |> Enum.map(&formatting_func.(&1))
    |> Enum.reject(&is_nil/1)
    |> return_joined_list_or_nil()
  end

  def return_joined_list_or_nil([]), do: nil
  def return_joined_list_or_nil(list, joiner \\ "\n") do
    Enum.join(list, joiner)
  end

  def sort_elements_by_id(elements) do
    Enum.sort_by(elements, fn element ->
      [[_ | id] | _] = Tuple.to_list(element)
      id
    end)
  end

  def compact(enum), do: Enum.reject(enum, &is_nil/1)

  ## Private

  defp _global_properties_to_dot(%{global_properties: global_props}, key) do
    with props <- Keyword.get(global_props, key) do
      case length(props) do
        0 -> nil
        _ -> "  #{key} #{attributes_to_dot(props)}"
      end
    end
  end
end
