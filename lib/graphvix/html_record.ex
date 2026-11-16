defmodule Graphvix.HTMLRecord do
  @allowed_attributes [
    table:
      ~w(align bgcolor border cellborder cellpadding cellspacing color columns fixedsize gradientangle height href id port rows sides style target title tooltip valign width),
    td:
      ~w(align balign bgcolor border cellpadding cellspacing color colspan fixedsize gradientangle height href id port rowspan sides style target title tooltip valign width),
    font: ~w(color face point-size)
  ]

  defstruct [:body, attrs: []]

  def new(body, attrs \\ []), do: %__MODULE__{body: body, attrs: attrs}

  def tr(body, attrs \\ []), do: {:tr, body, attrs}

  def td(body, attrs \\ []), do: {:td, body, attrs}

  def font(body, attrs), do: {:font, body, attrs}

  def br, do: {:br}

  def ports(%__MODULE__{} = record),
    do: collect_ports(record) |> List.flatten() |> Enum.reject(&is_nil/1)

  defp collect_ports(cells) when is_list(cells), do: Enum.map(cells, &collect_ports/1)
  defp collect_ports(%__MODULE__{body: body, attrs: attrs}), do: collect_ports(body, attrs)
  defp collect_ports({_, body, attrs}), do: collect_ports(body, attrs)
  defp collect_ports(_), do: []

  defp collect_ports(body, attrs), do: [attrs[:port] | collect_ports(body)]

  def allowed_attributes(type), do: @allowed_attributes[type]

  def to_label(%__MODULE__{body: body, attrs: attrs}),
    do: "<table#{build_attrs(attrs)}>#{to_label(body)}</table>"

  def to_label(body) when is_binary(body), do: escape(body)
  def to_label(body) when is_list(body), do: Enum.map_join(body, "", &to_label/1)

  def to_label({type, body, attrs}) when type in [:tr, :td],
    do: "<#{type}#{build_attrs(attrs)}>#{to_label(body)}</#{type}>"

  def to_label({:br}), do: "<br/>"

  def to_label({:font, body, attrs}) do
    attrs = build_attrs(attrs)
    "<font#{attrs}>#{to_label(body)}</font>"
  end

  defp build_attrs([]), do: ""

  defp build_attrs(attrs),
    do:
      " " <>
        Enum.map_join(attrs, " ", fn {k, v} ->
          "#{format_key(k)}=#{inspect(escape(to_string(v)))}"
        end)

  defp format_key(k), do: to_string(k) |> String.replace("_", "-")

  defp escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
