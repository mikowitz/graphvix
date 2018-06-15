defmodule Graphvix.RecordTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Graphvix.{Record, RecordSubset, Graph}

  doctest Record

  property "generating a simple record" do
    check all label <- string(:ascii, min_length: 3)
    do
      record = Record.new(label)
      assert Record.to_label(record) == label
    end
  end

  property "generating a basic record with a single row" do
    check all labels <- list_of(string(:ascii, min_length: 3), min_length: 2, max_length: 5)
    do
      record = Record.new(labels)
      assert Record.to_label(record) == Enum.join(labels, " | ")
    end
  end

  property "generating a record as a column" do
    check all labels <- list_of(string(:ascii, min_length: 3), min_length: 2, max_length: 5)
    do
      record = Record.new(RecordSubset.new(labels, true))
      assert Record.to_label(record) == "{ #{Enum.join(labels, " | ")} }"
    end
  end

  property "generating a nested record starting with a row" do
    check all [l1, l2, l3, l4, l5] <- list_of(string(:ascii, min_length: 3), length: 5)
    do
      record = Record.new(RecordSubset.new([
        l1,
        RecordSubset.new([l2, l3, l4], true),
        l5
      ]))
      assert Record.to_label(record) == "#{l1} | { #{l2} | #{l3} | #{l4} } | #{l5}"
    end
  end

  property "multi-nested record" do
    check all [l1, l2, l3, l4, l5, l6, l7, l8] <- list_of(string(:ascii, min_length: 3), length: 8)
    do
      record = Record.new(RecordSubset.new([
        l1,
        RecordSubset.new([l2, RecordSubset.new([l3, l4, RecordSubset.new([l5, l6], true)]), l7], true),
        l8
      ]))
      assert Record.to_label(record) == "#{l1} | { #{l2} | { #{l3} | #{l4} | { #{l5} | #{l6} } } | #{l7} } | #{l8}"
    end
  end

  property "basic record with named ports" do
    check all [l1, l2, l3] <- list_of(string(:ascii, min_length: 3), length: 3),
      port_name <- string(:ascii, min_length: 3)
    do
      record = Record.new(RecordSubset.new([l1, {port_name, l2}, l3]))
      assert Record.to_label(record) == "#{l1} | <#{port_name}> #{l2} | #{l3}"
    end
  end

  property "multi-nested record with ports" do
    check all [l1, l2, l3, l4, l5, l6, l7, l8, p1, p2] <- list_of(string(:ascii, min_length: 3), length: 10)
    do
      record = Record.new(RecordSubset.new([
        {p1, l1},
        RecordSubset.new([l2, RecordSubset.new([l3, l4, RecordSubset.new([l5, {p2, l6}])], true), l7]),
        l8
      ], true))
      assert Record.to_label(record) == "{ <#{p1}> #{l1} | { #{l2} | { #{l3} | #{l4} | { #{l5} | <#{p2}> #{l6} } } | #{l7} } | #{l8} }"
    end
  end
end

