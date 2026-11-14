defmodule Graphvix.HTMLRecord do
  @moduledoc """
  An HTML-like table label.

  Use it as the value of any `label`; a node whose own label is an
  `HTMLRecord` is drawn with `shape: "plaintext"` unless it sets a shape of
  its own. This is the only way to produce an HTML-like label: every other
  string is quoted and escaped.

      iex> import Graphvix.HTMLRecord
      iex> record = Graphvix.HTMLRecord.new([tr([td("a", port: "p"), td(["b", br(), font("c", color: "red")])])])
      iex> Graphvix.HTMLRecord.to_label(record)
      ~s(<table><tr><td port="p">a</td><td>b<br/><font color="red">c</font></td></tr></table>)

  Attribute names are hyphenated (`point_size:` becomes `point-size`), values
  are quoted, and text is escaped as HTML entities. Cell content is a string,
  `br/0`, `font/2`, a nested `HTMLRecord`, or a list of these.
  """

  defstruct rows: [], attributes: []

  @type content :: String.t() | :br | {:font, content(), keyword()} | t() | [content()]
  @type td :: {:td, content(), keyword()}
  @type tr :: {:tr, [td()]}
  @type t :: %__MODULE__{rows: [tr()], attributes: keyword()}

  @allowed %{
    table:
      ~w(align bgcolor border cellborder cellpadding cellspacing color columns fixedsize gradientangle height href id port rows sides style target title tooltip valign width),
    td:
      ~w(align balign bgcolor border cellpadding cellspacing color colspan fixedsize gradientangle height href id port rowspan sides style target title tooltip valign width),
    font: ~w(color face point-size)
  }

  @doc "A table of rows built with `tr/1`, with optional table attributes."
  @spec new([tr()], keyword()) :: t()
  def new(rows, attributes \\ []) when is_list(rows),
    do: %__MODULE__{rows: rows, attributes: attributes}

  @doc "A table row of cells built with `td/2`."
  @spec tr([td()]) :: tr()
  def tr(cells) when is_list(cells), do: {:tr, cells}

  @doc "A table cell. `port:` lets edges attach to it."
  @spec td(content(), keyword()) :: td()
  def td(content, attributes \\ []), do: {:td, content, attributes}

  @doc "A line break inside a cell."
  @spec br() :: :br
  def br, do: :br

  @doc "Formatted text; attributes are `color`, `face` and `point_size`."
  @spec font(content(), keyword()) :: {:font, content(), keyword()}
  def font(content, attributes \\ []), do: {:font, content, attributes}

  @doc "The label as one line of HTML, without the outer `<` and `>`."
  @spec to_label(t()) :: String.t()
  def to_label(%__MODULE__{rows: rows, attributes: attributes}) do
    "<table#{attrs(attributes)}>" <> Enum.map_join(rows, &row/1) <> "</table>"
  end

  @doc "Every port in the table, its cells and nested tables, in definition order."
  @spec ports(t()) :: [String.t()]
  def ports(%__MODULE__{} = record) do
    for {_element, attributes} <- elements(record),
        {key, value} <- attributes,
        to_string(key) == "port",
        do: to_string(value)
  end

  @doc "The attribute names allowed on `:table`, `:td` and `:font`, hyphenated."
  @spec allowed_attributes(:table | :td | :font) :: [String.t()]
  def allowed_attributes(element), do: Map.fetch!(@allowed, element)

  @doc false
  # Every element's attributes, in the order the label renders them.
  @spec elements(t()) :: [{:table | :td | :font, keyword()}]
  def elements(%__MODULE__{rows: rows, attributes: attributes}) do
    [
      {:table, attributes}
      | Enum.flat_map(rows, fn {:tr, cells} -> Enum.flat_map(cells, &cell_elements/1) end)
    ]
  end

  defp cell_elements({:td, content, attributes}),
    do: [{:td, attributes} | content_elements(content)]

  defp content_elements(list) when is_list(list), do: Enum.flat_map(list, &content_elements/1)

  defp content_elements({:font, content, attributes}),
    do: [{:font, attributes} | content_elements(content)]

  defp content_elements(%__MODULE__{} = table), do: elements(table)
  defp content_elements(_text_or_br), do: []

  defp row({:tr, cells}), do: "<tr>" <> Enum.map_join(cells, &cell/1) <> "</tr>"

  defp cell({:td, content, attributes}),
    do: "<td#{attrs(attributes)}>" <> content(content) <> "</td>"

  defp content(list) when is_list(list), do: Enum.map_join(list, &content/1)
  defp content(:br), do: "<br/>"

  defp content({:font, inner, attributes}),
    do: "<font#{attrs(attributes)}>" <> content(inner) <> "</font>"

  defp content(%__MODULE__{} = table), do: to_label(table)
  defp content(text), do: text |> to_string() |> escape()

  defp attrs(attributes) do
    Enum.map_join(attributes, fn {key, value} ->
      ~s( #{hyphenate(key)}="#{value |> to_string() |> escape() |> String.replace(~s("), "&quot;")}")
    end)
  end

  defp hyphenate(key), do: key |> to_string() |> String.replace("_", "-")

  defp escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
