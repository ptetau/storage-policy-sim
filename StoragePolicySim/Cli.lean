/-
The shared parts of the commands of `sim`: the number options with a fixed range, the reading of a
number, the problems of a command line, and the printing of numbers, lines and tables.
DES-errors (error codes) gives the codes.
-/
import StoragePolicySim.Strategy

namespace StoragePolicySim

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
  deriving Inhabited

/-- The `--days` option. -/
def daysOption : NumberOption :=
  { flag := "--days", meaning := "days to simulate", wholeOnly := true,
    default := 365, lowest := 1, highest := 3650 }

/-- The `--seed` option. -/
def seedOption : NumberOption :=
  { flag := "--seed", meaning := "seed of the weather", wholeOnly := true,
    default := 1, lowest := 0, highest := 4294967295 }

/-- The `--lat` option. -/
def latitudeOption : NumberOption :=
  { flag := "--lat", meaning := "latitude in degrees, south is negative",
    default := -41.3, lowest := -90, highest := 90 }

/-- The `--pv` option. -/
def pvOption : NumberOption :=
  { flag := "--pv", meaning := "kW of the solar panels", default := 5, lowest := 0, highest := 100 }

/-- The `--battery` option. -/
def batteryOption : NumberOption :=
  { flag := "--battery", meaning := "kWh that the battery holds",
    default := 10, lowest := 0, highest := 200 }

/-- The `--power` option. -/
def powerOption : NumberOption :=
  { flag := "--power", meaning := "kW in or out of the battery",
    default := 5, lowest := 0, highest := 100 }

/-- The `--load` option. -/
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

/-- A number option value, as the person typed it and as a number. -/
structure TypedNumber where
  text : String
  value : Float

/-- The last value that the person typed for the option. `numbers` holds the last typed first. -/
def typedIn (numbers : List (String × TypedNumber)) (flag : String) : Option TypedNumber :=
  (numbers.find? (·.1 == flag)).map (·.2)

/-- The last typed value of the option, or its default. -/
def numberIn (numbers : List (String × TypedNumber)) (option : NumberOption) : Float :=
  ((typedIn numbers option.flag).map (·.value)).getD option.default

/-- The value of a whole-number option. The reading step makes sure that the value is whole, and
the range step makes sure that it is not negative. -/
def wholeIn (numbers : List (String × TypedNumber)) (option : NumberOption) : Nat :=
  (numberIn numbers option).toUInt64.toNat

/-- A problem of the command line. -/
inductive Problem
  | unknownCommand (word : String)
  | unknownOption (word : String)
  | missingValue (flag : String)
  | badNumber (flag text : String)
  | outOfRange (flag text lowest highest : String)
  | unknownStrategy (name : String)
  | unknownPolicy (name : String)
  | unknownGoal (name : String)
  | unknownHome (name names : String)

/-- The strategy names, as the usage and the errors list them. -/
def strategyNames : String := ", ".intercalate (Strategy.all.map (·.name))

/-- The names of the policies, as the errors list them. -/
def policyNames : List String := ["static", "precomputed", "dynamic"]

/-- The error line of a problem. -/
def Problem.line : Problem → String
  | .unknownCommand word => s!"error: UNKNOWN_COMMAND: {word}"
  | .unknownOption word => s!"error: UNKNOWN_OPTION: {word}"
  | .missingValue flag => s!"error: MISSING_VALUE: {flag}"
  | .badNumber flag text => s!"error: BAD_NUMBER: {flag} {text}"
  | .outOfRange flag text lowest highest =>
    s!"error: OUT_OF_RANGE: {flag} {text} ({lowest} to {highest})"
  | .unknownStrategy name =>
    s!"error: UNKNOWN_STRATEGY: {name} ({strategyNames})"
  | .unknownPolicy name =>
    s!"error: UNKNOWN_POLICY: {name} ({", ".intercalate policyNames})"
  | .unknownGoal name => s!"error: UNKNOWN_GOAL: {name} (self-consumption, import)"
  | .unknownHome name names => s!"error: UNKNOWN_HOME: {name} ({names})"

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

/-- The option of a flag among the options, or `none`. -/
def numberOptionIn (options : List NumberOption) (flag : String) : Option NumberOption :=
  options.find? (·.flag == flag)

/-- Reads the value of an option as a number. A bad number is a problem. -/
def readTyped (option : NumberOption) (value : String) : Except Problem TypedNumber :=
  match readNumber option.wholeOnly value with
  | some number => .ok ⟨value, number⟩
  | none => .error (.badNumber option.flag value)

/-- Finds the first of the options outside its range. Then finds a `--flex` value outside 0 to the
`--load` value. -/
def rangeProblemIn (options : List NumberOption) (numbers : List (String × TypedNumber)) :
    Option Problem :=
  let outside (typed : TypedNumber) (lowest highest : Float) :=
    typed.value < lowest || typed.value > highest
  let ranged := options.findSome? fun option =>
    (typedIn numbers option.flag).bind fun typed =>
      if outside typed option.lowest option.highest then
        some (.outOfRange option.flag typed.text (boundText option.lowest)
          (boundText option.highest))
      else none
  let loadText := ((typedIn numbers loadOption.flag).map (·.text)).getD
    (boundText loadOption.default)
  ranged <|> (typedIn numbers flexFlag).bind fun typed =>
    if outside typed 0 (numberIn numbers loadOption) then
      some (.outOfRange flexFlag typed.text "0" loadText)
    else none

/-! ## Output -/

/-- The width of the label and its spaces in a line of `sim run`. -/
def labelWidth : Nat := 18

/-- A label, spaces to column 19, and a value. -/
def labelledLine (label value : String) : String :=
  label ++ "".pushn ' ' (labelWidth - label.length) ++ value

/-- The header, and then a row for each list of fields. The first column aligns left, and
each other column aligns right under its header word. -/
def table (header : List String) (rows : List (List String)) : List String :=
  let alignedRow (fields : List String) : String :=
    let cells := (header.zip fields).zipIdx.map fun ((word, field), column) =>
      let spaces := "".pushn ' ' (word.length - field.length)
      if column == 0 then field ++ spaces else spaces ++ field
    " ".intercalate cells
  " ".intercalate header :: rows.map alignedRow

end StoragePolicySim
