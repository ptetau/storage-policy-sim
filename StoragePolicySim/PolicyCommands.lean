/-
The `sim forecast` and `sim policy` commands. Built: `sim forecast` and `sim policy run`. The
policy commands `compare`, `robust`, `tune` and `plan` are not built yet.
-/
import StoragePolicySim.Cli
import StoragePolicySim.HomeSim

namespace StoragePolicySim

/-! ## Options of `sim policy run` -/

/-- A number option of the home, the tank or the policy, with a whole-number flag. -/
private def policyNumberOption (flag meaning : String) (default lowest highest : Float)
    (wholeOnly : Bool := false) : NumberOption :=
  { flag, meaning, wholeOnly, default, lowest, highest }

/-- The window of the first tank in the default static policy. -/
private def defaultWindow : TankWindow := defaultStatic.windows[0]!

/-- The tank options, in the order that the range step reads them. -/
private def tankOptions : List NumberOption :=
  [policyNumberOption "--tank" "kWh that the tank holds" defaultTank.capacityKwh 0 50,
   policyNumberOption "--element" "kW of the element" defaultTank.elementKw 0 20,
   policyNumberOption "--cut-in" "kWh below which the thermostat cuts in"
     defaultTank.cutInKwh 0 50,
   policyNumberOption "--floor" "kWh below which the tank is cold" defaultTank.floorKwh 0 50]

/-- The hot-water and forecast options. -/
private def drawOptions : List NumberOption :=
  [policyNumberOption "--draw" "kWh of hot water each day" defaultHome.drawKwhPerDay 0 100,
   policyNumberOption "--draw-cv" "spread of the draw from day to day" defaultHome.drawCv 0 1,
   policyNumberOption "--fetches" "forecast fetches each day" defaultHome.fetchesPerDay.toFloat 1
     10 (wholeOnly := true),
   policyNumberOption "--forecast-error" "scale of the forecast error" defaultHome.errorScale 0 5]

/-- The options of the policies. -/
private def heatStartOption : NumberOption :=
  policyNumberOption "--heat-start" "hour that the heating starts" defaultWindow.heatStart.toFloat
    0 23 (wholeOnly := true)

private def heatHoursOption : NumberOption :=
  policyNumberOption "--heat-hours" "hours of heating" defaultWindow.heatHours.toFloat 0 24
    (wholeOnly := true)

private def dischargeFromOption : NumberOption :=
  policyNumberOption "--discharge-from" "hour from which the battery may discharge"
    defaultStatic.dischargeFrom.toFloat 0 24 (wholeOnly := true)

private def flexStartOption : NumberOption :=
  policyNumberOption "--flex-start" "hour that the flexible load starts"
    defaultStatic.flexStart.toFloat 0 23 (wholeOnly := true)

private def targetOption : NumberOption :=
  policyNumberOption "--target" "kWh that a policy heats the tank to" defaultTank.capacityKwh 0 50

private def minSolarOption : NumberOption :=
  policyNumberOption "--min-solar" "kWh of forecast that an hour needs to heat" 0.5 0 10

private def lowOption : NumberOption :=
  policyNumberOption "--low" "kWh below which a dynamic policy heats" defaultTank.cutInKwh 0 50

/-- The number options of `sim policy run`. -/
private def runOptions : List NumberOption :=
  rangedOptions ++ tankOptions ++ drawOptions ++
    [heatStartOption, heatHoursOption, dischargeFromOption, flexStartOption, targetOption,
     minSolarOption, lowOption]

/-- The flag that picks the policy. -/
private def policyFlag : String := "--policy"

/-- The options of a `sim policy` command line after the reading step. -/
private structure PolicyLine where
  /-- The name of the policy. -/
  policy : String := "static"
  /-- The number options, the last typed first. -/
  numbers : List (String × TypedNumber) := []

/-- The `--flex` option as the reading step sees it. Its range depends on `--load`, and
`rangeProblemIn` checks it. -/
private def flexReadOption : NumberOption :=
  policyNumberOption flexFlag "kWh of the daily load that a policy can move" defaultFlexKwh 0
    1000

/-- Reads each option and its value, from left to right. The first problem stops the reading. -/
private def readPolicyOptions (line : PolicyLine) : List String → Except Problem PolicyLine
  | [] => .ok line
  | flag :: rest =>
    if flag == policyFlag then
      match rest with
      | [] => .error (.missingValue flag)
      | name :: afterName =>
        if policyNames.contains name then readPolicyOptions { line with policy := name } afterName
        else .error (.unknownPolicy name)
    else match numberOptionIn (flexReadOption :: runOptions) flag, rest with
      | none, _ => .error (.unknownOption flag)
      | some _, [] => .error (.missingValue flag)
      | some option, value :: afterValue => do
        let typed ← readTyped option value
        readPolicyOptions { line with numbers := (flag, typed) :: line.numbers } afterValue

/-! ## The home and the policy of the options -/

/-- The home of the options: the home `generic` with the values that the person typed. -/
private def PolicyLine.home (line : PolicyLine) : Home :=
  let loadKwh := numberIn line.numbers loadOption
  let flexKwh := ((typedIn line.numbers flexFlag).map (·.value)).getD (min defaultFlexKwh loadKwh)
  let pvKw := numberIn line.numbers pvOption
  { defaultHome with
    site := { latitude := numberIn line.numbers latitudeOption, pvKw,
              dailyLoadKwh := loadKwh, flexKwh },
    arrays := #[{ kw := pvKw, direction := 0.0, tilt := 0.0 }],
    battery := { capacityKwh := numberIn line.numbers batteryOption,
                 powerKw := numberIn line.numbers powerOption },
    tanks := #[{ defaultTank with
      capacityKwh := numberIn line.numbers tankOptions[0]!,
      elementKw := numberIn line.numbers tankOptions[1]!,
      cutInKwh := numberIn line.numbers tankOptions[2]!,
      floorKwh := numberIn line.numbers tankOptions[3]! }],
    drawKwhPerDay := numberIn line.numbers drawOptions[0]!,
    drawCv := numberIn line.numbers drawOptions[1]!,
    fetchesPerDay := wholeIn line.numbers drawOptions[2]!,
    errorScale := numberIn line.numbers drawOptions[3]! }

/-- The policy of the options. -/
private def PolicyLine.policyOf (line : PolicyLine) : Policy :=
  let dischargeFrom := wholeIn line.numbers dischargeFromOption
  -- A value that is not typed stays out of the array: the tank gives the default.
  let typedArray (option : NumberOption) : Array Float :=
    match typedIn line.numbers option.flag with
    | some typed => #[typed.value]
    | none => #[]
  let targets := typedArray targetOption
  let lows := typedArray lowOption
  match line.policy with
  | "precomputed" =>
    .precomputed { targetKwh := targets,
                   minSolarKwh := numberIn line.numbers minSolarOption, dischargeFrom }
  | "dynamic" =>
    .dynamic { lowKwh := lows, targetKwh := targets, dischargeFrom }
  | _ =>
    .static { windows := #[{ heatStart := wholeIn line.numbers heatStartOption,
                             heatHours := wholeIn line.numbers heatHoursOption }],
              dischargeFrom, flexStart := wholeIn line.numbers flexStartOption }

/-! ## Output -/

/-- The 15 lines of `sim policy run`. -/
private def policyRunLines (line : PolicyLine) (policy : Policy) (totals : HomeTotals) :
    List String :=
  let days := wholeIn line.numbers daysOption
  let energy (label : String) (kwh : Float) := labelledLine label (oneDecimal kwh ++ " kWh")
  let ratio (label : String) (percent : Float) := labelledLine label (oneDecimal percent ++ " %")
  let startsPerDay := if days == 0 then 0.0 else totals.policyStarts.toFloat / days.toFloat
  [labelledLine "policy" policy.name,
   labelledLine "days" (toString days),
   labelledLine "seed" (toString (wholeIn line.numbers seedOption)),
   energy "solar" totals.pvKwh, energy "load" totals.loadKwh,
   energy "import" totals.importKwh, energy "export" totals.exportKwh,
   energy "curtailed" totals.curtailedKwh, energy "heating" totals.heatKwh,
   energy "backstop" totals.backstopKwh, energy "unmet-hot-water" totals.unmetKwh,
   labelledLine "cold-hours" (toString totals.coldHours),
   labelledLine "starts-per-day" (oneDecimal startsPerDay),
   ratio "self-consumption" totals.selfConsumption,
   ratio "self-sufficiency" totals.selfSufficiency]

/-- The lines of `sim policy run`, or the first problem of its options. -/
private def policyRun (words : List String) : Except Problem (List String) := do
  let line ← readPolicyOptions {} words
  match rangeProblemIn runOptions line.numbers with
  | some problem => .error problem
  | none =>
    let policy := line.policyOf
    let result := runHome line.home policy (wholeIn line.numbers seedOption)
      (wholeIn line.numbers daysOption)
    .ok (policyRunLines line policy result.totals)

/-- The usage of `sim policy`. -/
private def policyUsage : List String :=
  ["usage: sim policy run|compare|robust|tune|plan [options]",
   "",
   "sim policy run simulates one policy and prints the totals."]

/-- Prints the lines of a command, or its error line. Returns the exit code. -/
private def finish (outcome : Except Problem (List String)) : IO UInt32 := do
  match outcome with
  | .ok lines =>
    IO.print (String.join (lines.map (· ++ "\n")))
    return 0
  | .error problem =>
    IO.eprintln problem.line
    return 2

/-! ## The command `sim forecast` -/

/-- The `--lon` option of `sim forecast`. -/
private def lonOption : NumberOption :=
  policyNumberOption "--lon" "longitude in degrees, east is positive" 174.8 (-180) 180

/-- The `--hour` option of `sim forecast`, with the last hour of a run of `days` days. -/
private def hourOption (days : Nat) : NumberOption :=
  policyNumberOption "--hour" "hour of the run that the fetch is made" 0 0
    ((hoursInDay * days).toFloat - 1) (wholeOnly := true)

/-- The `--hour` option for the reading step: the widest true range, that of the most days. -/
private def hourReadOption : NumberOption :=
  hourOption daysOption.highest.toUInt64.toNat

/-- The `--forecast-error` option, as `sim policy run` has it. -/
private def forecastErrorOption : NumberOption := drawOptions[3]!

/-- Reads each option of `sim forecast` and its value, from left to right. The first problem
stops the reading. The last typed value is first in the list. -/
private def readForecastOptions (options : List NumberOption) :
    List (String × TypedNumber) → List String → Except Problem (List (String × TypedNumber))
  | numbers, [] => .ok numbers
  | numbers, flag :: rest =>
    match numberOptionIn options flag, rest with
    | none, _ => .error (.unknownOption flag)
    | some _, [] => .error (.missingValue flag)
    | some option, value :: afterValue => do
      let typed ← readTyped option value
      readForecastOptions options ((flag, typed) :: numbers) afterValue

/-- The Solcast JSON of one fetch, or the first problem of the options. -/
private def forecastRun (words : List String) : Except Problem (List String) := do
  let readable := [hourReadOption, lonOption, forecastErrorOption, latitudeOption, pvOption,
    daysOption, seedOption]
  let numbers ← readForecastOptions readable [] words
  let days := wholeIn numbers daysOption
  let options := [daysOption, seedOption, latitudeOption, pvOption, hourOption days, lonOption,
    forecastErrorOption]
  match rangeProblemIn options numbers with
  | some problem => .error problem
  | none =>
    let site := { defaultHome.site with latitude := numberIn numbers latitudeOption,
                                         pvKw := numberIn numbers pvOption }
    let seed := wholeIn numbers seedOption
    let fetchHour := wholeIn numbers (hourOption days)
    let periods := forecastOf (scenario site seed days) site seed
      (numberIn numbers forecastErrorOption) fetchHour
    .ok [forecastJson periods (numberIn numbers lonOption)]

/-- Runs `sim forecast` with its words: prints the Solcast JSON of one fetch. -/
def forecastCommand (words : List String) : IO UInt32 := finish (forecastRun words)

/-- Runs `sim policy` with its words. The commands `compare`, `robust`, `tune` and `plan` are not
built yet. -/
def policyCommand (words : List String) : IO UInt32 := do
  match words with
  | [] | "help" :: _ => finish (.ok policyUsage)
  | "run" :: options => finish (policyRun options)
  | word :: _ =>
    if ["compare", "robust", "tune", "plan"].contains word then
      IO.eprintln "error: not implemented"
      return 3
    else finish (.error (.unknownCommand s!"policy {word}"))

end StoragePolicySim
