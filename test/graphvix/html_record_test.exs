defmodule Graphvix.HTMLRecordTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Graphvix.HTMLRecord
  import HTMLRecord, only: [tr: 1, td: 1, td: 2]
  doctest HTMLRecord

  test "generating a basic HTML label" do
    cell1 = td("left")
    cell2 = td("mid dle")
    cell3 = td("right")
    row = tr([cell1, cell2, cell3])

    record = HTMLRecord.new([row])

    assert HTMLRecord.to_label(record) == """
    <table>
      <tr>
        <td>left</td>
        <td>mid dle</td>
        <td>right</td>
      </tr>
    </table>
    """ |> String.trim
  end

  test "generating an HTML label with col and rowspans" do
    row1_cell1 = td("hello<br/>world", rowspan: 3)
    row1_cell2 = td("b", colspan: 3)
    row1_cell3 = td("g", rowspan: 3)
    row1_cell4 = td("h", rowspan: 3)

    row1 = tr([
      row1_cell1,
      row1_cell2,
      row1_cell3,
      row1_cell4
    ])

    row2_cell1 = td("c")
    row2_cell2 = td("d")
    row2_cell3 = td("e")

    row2 = tr([
      row2_cell1,
      row2_cell2,
      row2_cell3
    ])

    row3_cell1 = td("f", colspan: 3)

    row3 = tr([row3_cell1])

    record = HTMLRecord.new([row1, row2, row3])

    assert HTMLRecord.to_label(record) == """
    <table>
      <tr>
        <td rowspan="3">hello<br/>world</td>
        <td colspan="3">b</td>
        <td rowspan="3">g</td>
        <td rowspan="3">h</td>
      </tr>
      <tr>
        <td>c</td>
        <td>d</td>
        <td>e</td>
      </tr>
      <tr>
        <td colspan="3">f</td>
      </tr>
    </table>
    """ |> String.trim
  end
end

