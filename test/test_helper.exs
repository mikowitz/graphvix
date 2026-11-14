exclude = if System.find_executable("dot"), do: [], else: [:graphviz]
ExUnit.start(formatters: [ExUnit.CLIFormatter, Covenant.Formatter], exclude: exclude)
