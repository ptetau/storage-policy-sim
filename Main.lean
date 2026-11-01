/-
The `sim` command. `sim run` simulates one strategy, and `sim compare` simulates each
strategy on the same weather. JOB-simulate (simulate a year of solar) gives the rules.
-/
import StoragePolicySim.Simulation

open StoragePolicySim

/-! ## Options -/

/-- A command that simulates. -/
inductive Command
  | run
  | compare
  deriving BEq

/-- An option that takes a number with a fixed range. -/
structure NumberOption where
  flag : String
  /-- What the number gives, for the usage. -/
  meaning : String
  /-- True when the option takes only whole numbers. -/
  wholeOnly : Bool := false
  default : Float
  lowest : Float
  highest : Float

def daysOption : NumberOption :=
  { flag := "--days", meaning := "days to simulate", wholeOnly := true,
    default := 365, lowest := 1, highest := 3650 }

def seedOption : NumberOption :=
  { flag := "--seed", meaning := "seed of the weather", wholeOnly := true,
    default := 1, lowest := 0, highest := 4294967295 }

def latitudeOption : NumberOption :=
  { flag := "--lat", meaning := "latitude in degrees, south is negative",
    default := -41.3, lowest := -90, highest := 90 }

def pvOption : NumberOption :=
  { flag := "--pv", meaning := "kW of the solar panels", default := 5, lowest := 0, highest := 100 }

def batteryOption : NumberOption :=
  { flag := "--battery", meaning := "kWh that the battery holds",
    default := 10, lowest := 0, highest := 200 }

def powerOption : NumberOption :=
  { flag := "--power", meaning := "kW in or out of the battery",
    default := 5, lowest := 0, highest := 100 }

def loadOption : NumberOption :=
  { flag := "--load", meaning := "kWh of household load each day",
    default := 20, lowest := 0.1, highest := 1000 }

/-- The number options with a fixed range, in the order that the range step reads them. -/
def rangedOptions : List NumberOption :=
  [daysOption, seedOption, latitudeOption, pvOption, batteryOption, powerOption, loadOption]

/-- The `--flex` range is from 0 to the `--load` value. Thus, `--flex` is not a ranged option. -/
def flexFlag : String := "--flex"

/-- The `--flex` value when the person gives none, unless the `--load` value is less. -/
def defaultFlexKwh : Float := 3

def strategyFlag : String := "--strategy"

def monthlyFlag : String := "--monthly"

def defaultStrategy : Strategy := .greedy

/-- A number option value, as the person typed it and as a number. -/
structure TypedNumber where
  text : String
  value : Float

/-- The options of a command line after the reading step. -/
structure CommandLine where
  strategy : Strategy := defaultStrategy
  monthly : Bool := false
  /-- The number options, the last typed first. -/
  numbers : List (String × TypedNumber) := []

/-- The last value that the person typed for the option. -/
def CommandLine.typed (commandLine : CommandLine) (flag : String) : Option TypedNumber :=
  (commandLine.numbers.find? (·.1 == flag)).map (·.2)

/-- The last typed value of the option, or its default. -/
def CommandLine.number (commandLine : CommandLine) (option : NumberOption) : Float :=
  ((commandLine.typed option.flag).map (·.value)).getD option.default

/-! ## Errors -/

/-- A problem of the command line. DES-errors (error codes) gives the codes. -/
inductive Problem
  | unknownCommand (word : String)
  | unknownOption (word : String)
  | missingValue (flag : String)
  | badNumber (flag text : String)
  | outOfRange (flag text lowest highest : String)
  | unknownStrategy (name : String)

/-- The strategy names, as the usage and the errors list them. -/
def strategyNames : String := ", ".intercalate (Strategy.all.map (·.name))

def Problem.line : Problem → String
  | .unknownCommand word => s!"error: UNKNOWN_COMMAND: {word}"
  | .unknownOption word => s!"error: UNKNOWN_OPTION: {word}"
  | .missingValue flag => s!"error: MISSING_VALUE: {flag}"
  | .badNumber flag text => s!"error: BAD_NUMBER: {flag} {text}"
  | .outOfRange flag text lowest highest =>
    s!"error: OUT_OF_RANGE: {flag} {text} ({lowest} to {highest})"
  | .unknownStrategy name =>
    s!"error: UNKNOWN_STRATEGY: {name} ({strategyNames})"

/-! ## Numbers -/

/-- The value of decimal digits. -/
def digitsValue (digits : List Char) : Nat :=
  digits.foldl (fun n c => n * 10 + (c.toNat - '0'.toNat)) 0

/-- Reads an optional sign, digits, and an optional point with more digits. A whole number
has no point. -/
def readNumber (wholeOnly : Bool) (text : String) : Option Float :=
  let (negative, unsigned) := match text.toList with
    | '-' :: rest => (true, rest)
    | '+' :: rest => (false, rest)
    | rest => (false, rest)
  let wholeDigits := unsigned.takeWhile Char.isDigit
  let fraction : Option (List Char) := match unsigned.dropWhile Char.isDigit with
    | [] => some []
    | '.' :: digits => if wholeOnly || digits.isEmpty || !digits.all Char.isDigit then none
      else some digits
    | _ => none
  match fraction with
  | some fractionDigits =>
    if wholeDigits.isEmpty then none
    else
      let magnitude := Float.ofScientific (digitsValue (wholeDigits ++ fractionDigits)) true
        fractionDigits.length
      some (if negative then -magnitude else magnitude)
  | none => none

/-- The value with one decimal, rounded half away from zero. -/
def oneDecimal (x : Float) : String :=
  let tenths := (x.abs * 10).round.toUInt64.toNat
  let sign := if x < 0 && tenths > 0 then "-" else ""
  s!"{sign}{tenths / 10}.{tenths % 10}"

/-- A bound of a range, as the usage and the errors write it: `-90`, `0.1` or `3650`. -/
def boundText (x : Float) : String :=
  if x.floor == x then
    let magnitude := x.abs.toUInt64.toNat
    if x < 0 then s!"-{magnitude}" else s!"{magnitude}"
  else oneDecimal x

/-! ## Reading the command line -/

def numberOption? (flag : String) : Option NumberOption :=
  rangedOptions.find? (·.flag == flag)

/-- Adds the value of an option that takes a value. A bad number or strategy name is a
problem. -/
def CommandLine.add (commandLine : CommandLine) (flag value : String) :
    Except Problem CommandLine :=
  if flag == strategyFlag then
    match Strategy.ofName? value with
    | some strategy => .ok { commandLine with strategy }
    | none => .error (.unknownStrategy value)
  else
    let wholeOnly := ((numberOption? flag).map (·.wholeOnly)).getD false
    match readNumber wholeOnly value with
    | some number =>
      .ok { commandLine with numbers := (flag, ⟨value, number⟩) :: commandLine.numbers }
    | none => .error (.badNumber flag value)

/-- True when the command takes the option and the option takes a value. -/
def takesValue (command : Command) (flag : String) : Bool :=
  (numberOption? flag).isSome || flag == flexFlag || (command == .run && flag == strategyFlag)

/-- Reads each option and its value, from left to right. The first problem stops the reading. -/
def readOptions (command : Command) (commandLine : CommandLine) :
    List String → Except Problem CommandLine
  | [] => .ok commandLine
  | flag :: rest =>
    if command == .run && flag == monthlyFlag then
      readOptions command { commandLine with monthly := true } rest
    else if !takesValue command flag then .error (.unknownOption flag)
    else match rest with
      | [] => .error (.missingValue flag)
      | value :: afterValue => do
        readOptions command (← commandLine.add flag value) afterValue

/-- Finds the first option outside its range. Then finds a `--flex` value outside 0 to the
`--load` value. -/
def CommandLine.rangeProblem? (commandLine : CommandLine) : Option Problem :=
  let outside (typed : TypedNumber) (lowest highest : Float) :=
    typed.value < lowest || typed.value > highest
  let ranged := rangedOptions.findSome? fun option =>
    (commandLine.typed option.flag).bind fun typed =>
      if outside typed option.lowest option.highest then
        some (.outOfRange option.flag typed.text (boundText option.lowest)
          (boundText option.highest))
      else none
  let loadText := ((commandLine.typed loadOption.flag).map (·.text)).getD
    (boundText loadOption.default)
  ranged <|> (commandLine.typed flexFlag).bind fun typed =>
    if outside typed 0 (commandLine.number loadOption) then
      some (.outOfRange flexFlag typed.text "0" loadText)
    else none

/-! ## Simulation and output -/

def CommandLine.site (commandLine : CommandLine) : Site :=
  let loadKwh := commandLine.number loadOption
  let flexKwh := ((commandLine.typed flexFlag).map (·.value)).getD (min defaultFlexKwh loadKwh)
  { latitude := commandLine.number latitudeOption, pvKw := commandLine.number pvOption,
    dailyLoadKwh := loadKwh, flexKwh }

def CommandLine.battery (commandLine : CommandLine) : Battery :=
  { capacityKwh := commandLine.number batteryOption, powerKw := commandLine.number powerOption }

/-- The value of a whole-number option. The range step makes sure that the value is whole and
not negative. -/
def CommandLine.whole (commandLine : CommandLine) (option : NumberOption) : Nat :=
  (commandLine.number option).toUInt64.toNat

def CommandLine.simulate (commandLine : CommandLine) (strategy : Strategy) : Result :=
  StoragePolicySim.simulate commandLine.site commandLine.battery strategy
    (commandLine.whole seedOption) (commandLine.whole daysOption)

/-- The width of the label and its spaces in a line of `sim run`. -/
def labelWidth : Nat := 18

def labelledLine (label value : String) : String :=
  label ++ "".pushn ' ' (labelWidth - label.length) ++ value

/-- The 11 lines of `sim run`. -/
def runLines (commandLine : CommandLine) (totals : Totals) : List String :=
  let energy (label : String) (kwh : Float) := labelledLine label (oneDecimal kwh ++ " kWh")
  let ratio (label : String) (percent : Float) := labelledLine label (oneDecimal percent ++ " %")
  [labelledLine "strategy" commandLine.strategy.name,
   labelledLine "days" (toString (commandLine.whole daysOption)),
   labelledLine "seed" (toString (commandLine.whole seedOption)),
   energy "solar" totals.pvKwh, energy "load" totals.loadKwh,
   energy "self-used" totals.selfUsedKwh, energy "import" totals.importKwh,
   energy "export" totals.exportKwh, energy "losses" totals.lossKwh,
   ratio "self-consumption" totals.selfConsumption,
   ratio "self-sufficiency" totals.selfSufficiency]

/-- The header, and then a row for each list of fields. The first column aligns left, and
each other column aligns right under its header word. -/
def table (header : List String) (rows : List (List String)) : List String :=
  let alignedRow (fields : List String) : String :=
    let cells := (header.zip fields).zipIdx.map fun ((word, field), column) =>
      let spaces := "".pushn ' ' (word.length - field.length)
      if column == 0 then field ++ spaces else spaces ++ field
    " ".intercalate cells
  " ".intercalate header :: rows.map alignedRow

def monthHeader : List String :=
  ["month", "solar-kWh", "load-kWh", "import-kWh", "export-kWh", "self-consumption-%",
   "self-sufficiency-%"]

def monthRow (month : Month) : List String :=
  let totals := month.totals
  month.name :: [totals.pvKwh, totals.loadKwh, totals.importKwh, totals.exportKwh,
    totals.selfConsumption, totals.selfSufficiency].map oneDecimal

def compareHeader : List String :=
  ["strategy", "self-consumption-%", "self-sufficiency-%", "import-kWh", "export-kWh"]

def compareRow (strategy : Strategy) (totals : Totals) : List String :=
  strategy.name :: [totals.selfConsumption, totals.selfSufficiency, totals.importKwh,
    totals.exportKwh].map oneDecimal

/-- The stdout lines of a command with good options. -/
def output (command : Command) (commandLine : CommandLine) : List String :=
  match command with
  | .run =>
    let result := commandLine.simulate commandLine.strategy
    let monthTable := if commandLine.monthly
      then "" :: table monthHeader (result.months.toList.map monthRow) else []
    runLines commandLine result.totals ++ monthTable
  | .compare =>
    table compareHeader (Strategy.all.map fun strategy =>
      compareRow strategy (commandLine.simulate strategy).totals)

/-! ## The command -/

/-- A line of the usage: the option and its value, spaces to column 21, and the meaning. -/
def usageLine (option meaning : String) : String :=
  "  " ++ option ++ "".pushn ' ' (labelWidth - option.length) ++ meaning

def usage : List String :=
  let numberLine (option : NumberOption) :=
    usageLine s!"{option.flag} N" (s!"{option.meaning}. Default {boundText option.default}, " ++
      s!"range {boundText option.lowest} to {boundText option.highest}.")
  ["usage: sim run [options] | sim compare [options]",
   "",
   "sim run simulates one strategy and prints the totals.",
   "sim compare simulates each strategy on the same weather.",
   "",
   "Options:",
   usageLine s!"{strategyFlag} NAME"
     s!"sim run only. Default {defaultStrategy.name}, one of {strategyNames}.",
   usageLine monthlyFlag "sim run only. Also prints the totals of each month."] ++
  rangedOptions.map numberLine ++
  [usageLine s!"{flexFlag} N" (s!"kWh of the daily load that a strategy can move. " ++
     s!"Default {boundText defaultFlexKwh}, or the --load value when that is less. " ++
     "Range 0 to the --load value.")]

/-- Reads the options of the command. The first problem gives the error. -/
def runCommand (command : Command) (words : List String) : Except Problem (List String) := do
  let commandLine ← readOptions command {} words
  match commandLine.rangeProblem? with
  | some problem => .error problem
  | none => .ok (output command commandLine)

def main (args : List String) : IO UInt32 := do
  let outcome : Except Problem (List String) := match args with
    | [] | "help" :: _ | "--help" :: _ => .ok usage
    | "run" :: words => runCommand .run words
    | "compare" :: words => runCommand .compare words
    | word :: _ => .error (.unknownCommand word)
  match outcome with
  | .ok lines =>
    IO.print (String.join (lines.map (· ++ "\n")))
    return 0
  | .error problem =>
    IO.eprintln problem.line
    return 2
