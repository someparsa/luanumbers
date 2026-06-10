package.path = "./?.lua;" .. package.path

local numbers = require("luanumbers")

assert(numbers.version == "0.5.0")
numbers.configure("decimals=2,rounding=half-up,pad-zeroes=true,integers=false")
assert(numbers.format("3.14159") == "3.14")
assert(numbers.format("2.675") == "2.68")
assert(numbers.format("-1.235") == "-1.24")
assert(numbers.format("6.022e2") == "6.02e2")
assert(numbers.format("999999999999999999999999.995") ==
  "1000000000000000000000000.00")
assert(numbers.format(".125") == "0.13")
assert(numbers.format("3.") == "3.00")
assert(numbers.format("-0.004") == "0.00")
assert(numbers.format("−1.235") == "−1.24")

numbers.enable()
assert(numbers.process_input_buffer("Values: 3.14159 and 7.") ==
  "Values: 3.14 and 7.")
assert(numbers.process_input_buffer("Scientific: 6.022e2 and 6e2") ==
  "Scientific: 6.02e2 and 6e2")
assert(numbers.process_input_buffer("item2 and 4.567 % keep 8.999") ==
  "item2 and 4.57 % keep 8.999")

numbers.configure("decimals=1,warnings=off")
assert(numbers.process_input_buffer("Decimal 3.00 and integer 2") ==
  "Decimal 3.0 and integer 2")

assert(numbers.process_input_buffer("\\begin{tikzpicture}[x=1.25cm]") ==
  "\\begin{tikzpicture}[x=1.25cm]")
assert(numbers.process_input_buffer("\\draw (0.25,1.75) -- (3.26,4.84);") ==
  "\\draw (0.25,1.75) -- (3.26,4.84);")
assert(numbers.process_input_buffer("\\end{tikzpicture}") ==
  "\\end{tikzpicture}")
assert(numbers.process_input_buffer("Outside: 3.26") == "Outside: 3.3")

assert(numbers.process_input_buffer("\\begin{luanumbersexclude}") ==
  "\\begin{luanumbersexclude}")
assert(numbers.process_input_buffer("\\section{Selected 3.14159}") ==
  "\\section{Selected 3.14159}")
assert(numbers.process_input_buffer("\\label{sec:selected-3.14159}") ==
  "\\label{sec:selected-3.14159}")
assert(numbers.process_input_buffer("Selected body 3.14159") ==
  "Selected body 3.14159")
assert(numbers.process_input_buffer("\\end{luanumbersexclude}") ==
  "\\end{luanumbersexclude}")
assert(numbers.process_input_buffer("Next object 3.14159") ==
  "Next object 3.1")

assert(numbers.process_input_buffer("\\label{release-3.14159}") ==
  "\\label{release-3.14159}")
assert(numbers.process_input_buffer("\\includegraphics[width=0.75\\textwidth]{plot3.14159.pdf}") ==
  "\\includegraphics[width=0.75\\textwidth]{plot3.14159.pdf}")
assert(numbers.process_input_buffer("\\href{https://example.test/3.14159}{") ==
  "\\href{https://example.test/3.14159}{")
assert(numbers.process_input_buffer("Visible but protected 4.567}") ==
  "Visible but protected 4.567}")
assert(numbers.process_input_buffer("After command: 4.567") ==
  "After command: 4.6")
assert(numbers.process_input_buffer("URL https://example.test/3.14159") ==
  "URL https://example.test/3.14159")
assert(numbers.process_input_buffer("Grouped: 1,234.567") ==
  "Grouped: 1,234.567")
assert(numbers.process_input_buffer("Version: 1.2.3") == "Version: 1.2.3")

numbers.protect_environments("figure, table")
assert(numbers.process_input_buffer("\\begin{figure} 8.765") ==
  "\\begin{figure} 8.765")
assert(numbers.process_input_buffer("Caption value 8.765") ==
  "Caption value 8.765")
assert(numbers.process_input_buffer("\\end{figure}") == "\\end{figure}")
numbers.unprotect_environments("figure, table")

numbers.protect_commands("section, subsection, caption")
assert(numbers.process_input_buffer("\\section{Version 3.14159}") ==
  "\\section{Version 3.14159}")
assert(numbers.process_input_buffer("Body value 3.14159") ==
  "Body value 3.1")
numbers.unprotect_commands("section, subsection, caption")

numbers.configure("decimals=2,rounding=half-even")
assert(numbers.format("2.625") == "2.62")
assert(numbers.format("2.635") == "2.64")

numbers.configure("decimals=3,rounding=truncate,pad-zeroes=false")
assert(numbers.format("1.2399") == "1.239")
assert(numbers.format("4.5000") == "4.5")

numbers.configure("decimals=2,rounding=floor,pad-zeroes=true")
assert(numbers.format("-1.231") == "-1.24")
assert(numbers.format("1.239") == "1.23")

numbers.configure("decimals=2,rounding=ceil")
assert(numbers.format("-1.239") == "-1.23")
assert(numbers.format("1.231") == "1.24")

numbers.configure("decimals=1,rounding=half-up,input-decimal=comma")
assert(numbers.format("3,1415") == "3,1")
assert(numbers.process_input_buffer("Comma decimal: 3,1415") ==
  "Comma decimal: 3,1")

print("Lua unit tests passed")
