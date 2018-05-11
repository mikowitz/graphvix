defmodule Graphvix.HTMLRecord do
  defstruct [
    rows: [],
    attributes: []
  ]


  import Graphvix.DotHelpers, only: [indent: 1]

  @doc """
  Returns a new `HTMLRecord` which can be turned into an HTML table vertex.

  It takes two arguments. The first is a list of table rows all returned from
  the `tr/1` function.

  The second is an optional keyword list of attributes to apply to the table as
  a whole. Valid keys for this list are:

  * `align`
  * `bgcolor`
  * `border`
  * `cellborder`
  * `cellpadding`
  * `cellspacing`
  * `color`
  * `columns`
  * `fixedsize`
  * `gradientangle`
  * `height`
  * `href`
  * `id`
  * `port`
  * `rows`
  * `sides`
  * `style`
  * `target`
  * `title`
  * `tooltip`
  * `valign`
  * `width`

  ## Example

      iex> import HTMLRecord, only: [tr: 1, td: 1]
      iex> HTMLRecord.new([
      ...>   tr([
      ...>     td("a"),
      ...>     td("b")
      ...>   ]),
      ...>   tr([
      ...>     td("c"),
      ...>     td("d")
      ...>   ])
      ...> ], border: 1, cellspacing: 0, cellborder: 1)
      %HTMLRecord{
        rows: [
          %{cells: [
            %{label: "a", attributes: []},
            %{label: "b", attributes: []},
          ]},
          %{cells: [
            %{label: "c", attributes: []},
            %{label: "d", attributes: []},
          ]}
        ],
        attributes: [
          border: 1,
          cellspacing: 0,
          cellborder: 1
        ]
      }

  """
  def new(rows, attributes \\ []) when is_list(rows) do
    %__MODULE__{rows: rows, attributes: attributes}
  end

  def tr(cells) when is_list(cells) do
    %{cells: cells}
  end

  def td(label, attributes \\ []) do
    %{label: label, attributes: attributes}
  end

  def to_label(%__MODULE__{rows: rows, attributes: attributes}) do
    [
      "<<table#{table_attributes_for_label(attributes)}>",
      Enum.map(rows, &tr_to_label/1),
      "</table>>"
    ] |> List.flatten |> Enum.join("\n")
  end

  defp tr_to_label(%{cells: cells}) do
    [
      "<tr>",
      Enum.map(cells, &td_to_label/1),
      "</tr>"
    ] |> List.flatten |> Enum.join("\n") |> indent
  end

  defp td_to_label(%{label: label, attributes: attributes}) do
    indent("<td#{td_attributes_for_label(attributes)}>#{label}</td>")
  end

  defp td_attributes_for_label(attributes) do
    case attributes do
      [] -> ""
      attrs ->
        " " <> (Enum.map(attrs, fn {k, v} ->
          ~s(#{k}="#{v}")
        end) |> Enum.join(" "))
    end
  end

  defp table_attributes_for_label(attributes) do
    case attributes do
      [] -> ""
      attrs ->
        " " <> (Enum.map(attrs, fn {k, v} ->
          ~s(#{k}="#{v}")
        end) |> Enum.join(" "))
    end
  end
end
