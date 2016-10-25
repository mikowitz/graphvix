defmodule Graphvix.Writer do
  @moduledoc false
  def write(%{nodes: nodes, edges: edges, clusters: clusters, attrs: attrs}) do
    contents = [
       graph_attrs_to_dot(attrs),
       collection_to_dot(nodes, &node_to_dot/1),
       collection_to_dot(edges, &edge_to_dot/1),
       collection_to_dot(clusters, &cluster_to_dot/1)
   ] |> List.flatten |> Enum.reject(&(&1 == "")) |> Enum.join("\n\n")
   "digraph G {\n" <> contents <> "\n}"
  end

  def save(dot, filename) do
    with dot_filename <- file_with_ext(filename, :dot) do
      File.write(dot_filename, dot)
    end
    filename
  end

  def compile(filename, filetype \\ :pdf) do
    with dot_filename <- file_with_ext(filename, :dot),
         output_filename <- file_with_ext(filename, filetype) do
      System.cmd("dot", ["-T#{filetype}", dot_filename, "-o", output_filename])
    end
    {filename, filetype}
  end

  def open({filename, filetype}) do
    with filename_with_ext <- file_with_ext(filename, filetype) do
      System.cmd("open", [filename_with_ext])
    end
    {filename, filetype}
  end

  defp collection_to_dot(coll, to_dot_fun) do
    coll |> Enum.map(to_dot_fun) |> Enum.join("\n")
  end

  defp node_to_dot({id, %{attrs: attrs}}) do
    [
      "node_#{id}",
      attrs_to_dot(attrs)
    ] |> convert_to_indented_line
  end

  defp edge_to_dot({_id, %{start_node: n1_id, end_node: n2_id, attrs: attrs}}) do
    [
      "node_#{n1_id}",
      "->",
      "node_#{n2_id}",
      attrs_to_dot(attrs)
    ] |> convert_to_indented_line
  end

  defp cluster_to_dot({id, %{node_ids: node_ids}}) do
    connected_node_ids = node_ids
    |> Enum.map(&"node_#{&1}")
    |> Enum.join(" -> ")
    |> Kernel.<>(" [style=invis];")
    rank_ids = node_ids |> Enum.map(&"node_#{&1};") |> Enum.join(" ")
    [
      "subgraph cluster_#{id} {",
      connected_node_ids |> indent,
      ~s/{ rank = "same"; #{rank_ids} }/ |> indent,
      "}"
    ] |> List.flatten |> Enum.map(&indent(&1, 1)) |> Enum.join("\n")
  end

  def convert_to_indented_line(elements) do
    elements |> Enum.reject(&is_nil/1) |> Enum.join(" ")
    |> Kernel.<>(";") |> indent
  end

  defp file_with_ext(filename, ext) do
    with ext_str <- ext |> to_string do
      filename <> "." <> ext_str
    end
  end

  defp indent(str, depth \\ 1) do
    String.duplicate("  ", depth) <> str
  end

  defp attrs_to_dot(attrs) do
    case attrs do
      [] -> nil
      _ -> "[" <> attributes_to_dot_format(attrs) <> "]"
    end
  end

  defp attributes_to_dot_format(attrs) do
    attrs
    |> Enum.map(&pair_to_dot_format/1)
    |> Enum.join(",")
  end

  defp graph_attrs_to_dot(attrs) do
    attrs
    |> Enum.map(fn kv -> pair_to_dot_format(kv) <> ";" end)
    |> Enum.map(&indent/1)
    |> Enum.join("\n")
  end

  defp pair_to_dot_format({k, v}) do
    ~s/#{k}="#{v}"/
  end
end
