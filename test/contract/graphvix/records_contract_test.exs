defmodule Graphvix.RecordsContractTest do
  use Covenant.Case, component: "graphvix.records", async: true
  use ExUnitProperties

  alias Graphvix.{HTMLRecord, Record}

  import Graphvix.HTMLRecord, only: [tr: 1, td: 1, td: 2, br: 0, font: 2]

  defp plain_text, do: string(Enum.concat([?a..?z, ?A..?Z, ?0..?9]), min_length: 1)

  # -- I1 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I1"
  property "a string body renders as its text" do
    check all(text <- plain_text()) do
      assert Record.to_label(Record.new(text)) == text
    end
  end

  @tag obligation: "graphvix.records.I1"
  property "a plain list renders as a row" do
    check all(cells <- list_of(plain_text(), min_length: 2, max_length: 5)) do
      assert Record.to_label(Record.new(cells)) == Enum.join(cells, " | ")
      assert Record.to_label(Record.new(Record.row(cells))) == Enum.join(cells, " | ")
    end
  end

  @tag obligation: "graphvix.records.I1"
  property "a column renders in braces" do
    check all(cells <- list_of(plain_text(), min_length: 2, max_length: 5)) do
      assert Record.to_label(Record.new(Record.column(cells))) == "{ #{Enum.join(cells, " | ")} }"
    end
  end

  @tag obligation: "graphvix.records.I1"
  test "rows and columns nest as in 1.x" do
    record =
      Record.new(
        Record.row([
          "a",
          Record.column(["b", "c", "d"]),
          Record.column(["e", "f", Record.row(["g", "h", "i"])])
        ])
      )

    assert Record.to_label(record) == "a | { b | c | d } | { e | f | { g | h | i } }"
  end

  # -- I2 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I2"
  test "port cells render with their port" do
    assert Record.to_label(Record.new(["a", {"port_b", "b"}])) == "a | <port_b> b"
  end

  @tag obligation: "graphvix.records.I2"
  test "ports lists every port at any depth in definition order" do
    record =
      Record.new([
        {"p1", "a"},
        Record.column(["b", {"p2", "c"}, Record.row([{"p3", "d"}])]),
        "e"
      ])

    assert Record.ports(record) == ["p1", "p2", "p3"]
    assert Record.ports(Record.new("plain")) == []
  end

  # -- I3 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I3"
  property "record cell text never leaves a special character unescaped" do
    check all(text <- string([?a, ?b, ?n, ?\s, ?{, ?}, ?|, ?<, ?>, ?\\], min_length: 1)) do
      expected =
        ~r/(\\+)(?=[{}|<>]|$)/
        |> Regex.replace(text, fn _, run -> run <> run end)
        |> String.replace(~r/([{}|<>])/, "\\\\\\1")

      assert Record.to_label(Record.new([text, "x"])) == expected <> " | x"
      assert Record.to_label(Record.new(text)) == expected
    end
  end

  @tag obligation: "graphvix.records.I3"
  test "port cell text is escaped too" do
    assert Record.to_label(Record.new([{"p", "a|b"}])) == "<p> a\\|b"
  end

  @tag obligation: ["graphvix.records.I2", "graphvix.records.I3"]
  test "port names are escaped like cell text" do
    assert Record.to_label(Record.new([{"a>b", "x"}])) == "<a\\>b> x"
    assert Record.to_label(Record.new([{"a{b|c", "x"}])) == "<a\\{b\\|c> x"
  end

  @tag obligation: "graphvix.records.I3"
  test "a backslash before a special character is escaped and others are kept" do
    assert Record.to_label(Record.new(["x\\{y"])) == "x\\\\\\{y"
    assert Record.to_label(Record.new(["end\\", "z"])) == "end\\\\ | z"
    assert Record.to_label(Record.new(["line\\nbreak"])) == "line\\nbreak"
    assert Record.to_label(Record.new(["a\\\n"])) == "a\\\n"
  end

  # -- I4 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I4"
  test "Record.new takes only a body" do
    Code.ensure_loaded!(Record)

    assert function_exported?(Record, :new, 1)
    refute function_exported?(Record, :new, 2)
  end

  # -- I5 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I5"
  test "an html record renders as one line of table markup" do
    record = HTMLRecord.new([tr([td("a"), td("b")]), tr([td("c"), td("d")])])

    assert HTMLRecord.to_label(record) ==
             "<table><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>"
  end

  @tag obligation: "graphvix.records.I5"
  test "br font and nested tables render in place" do
    nested = HTMLRecord.new([tr([td("x")])])
    record = HTMLRecord.new([tr([td(["b", br(), font("B", color: "red")]), td(nested)])])

    assert HTMLRecord.to_label(record) ==
             ~s(<table><tr><td>b<br/><font color="red">B</font></td><td><table><tr><td>x</td></tr></table></td></tr></table>)
  end

  # -- I6 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I6"
  test "attributes are hyphenated quoted and kept in order" do
    record =
      HTMLRecord.new(
        [tr([td(font("B", color: "red", point_size: 100), colspan: 2, bgcolor: "blue")])],
        border: 0,
        cellspacing: 1
      )

    assert HTMLRecord.to_label(record) ==
             ~s(<table border="0" cellspacing="1"><tr><td colspan="2" bgcolor="blue"><font color="red" point-size="100">B</font></td></tr></table>)
  end

  # -- I7 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I7"
  test "html text and attribute values are escaped" do
    record = HTMLRecord.new([tr([td("a & <b>", title: ~s(say "hi"))])])

    assert HTMLRecord.to_label(record) ==
             ~s(<table><tr><td title="say &quot;hi&quot;">a &amp; &lt;b&gt;</td></tr></table>)
  end

  # -- I8 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I8"
  test "td ports render and are listed including nested tables" do
    nested = HTMLRecord.new([tr([td("x", port: "inner")])])
    record = HTMLRecord.new([tr([td("a", port: "p1"), td(nested)])], port: "whole")

    assert HTMLRecord.to_label(record) =~ ~s(<td port="p1">a</td>)
    assert HTMLRecord.ports(record) == ["whole", "p1", "inner"]
  end

  # -- I9 -----------------------------------------------------------------------

  @tag obligation: "graphvix.records.I9"
  test "allowed attributes are the 1.x lists" do
    assert HTMLRecord.allowed_attributes(:table) ==
             ~w(align bgcolor border cellborder cellpadding cellspacing color columns fixedsize gradientangle height href id port rows sides style target title tooltip valign width)

    assert HTMLRecord.allowed_attributes(:td) ==
             ~w(align balign bgcolor border cellpadding cellspacing color colspan fixedsize gradientangle height href id port rowspan sides style target title tooltip valign width)

    assert HTMLRecord.allowed_attributes(:font) == ~w(color face point-size)
  end
end
