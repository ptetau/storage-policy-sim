import StoragePolicySim.HomeSim
open StoragePolicySim

def f1 (x : Float) : String :=
  let s := toString ((x * 10).round / 10)
  match s.splitOn "." with
  | [w, f] => w ++ "." ++ (f.take 1).toString
  | _ => s

/-- The home `mine` with a cut-in for each tank and a draw spread. -/
def variant (home : Home) (cutShare cv drawScale : Float) : Home :=
  { home with
    tanks := home.tanks.map (fun (t : TankConfig) => { t with cutInKwh := cutShare * t.capacityKwh }),
    drawCv := cv, drawKwhPerDay := home.drawKwhPerDay * drawScale }

def report (label : String) (home : Home) (p : StaticParams) : IO Unit := do
  let mut imp := 0.0; let mut unmet := 0.0; let mut cold := 0; let mut bs := 0.0
  let mut low0 := 1000.0; let mut low1 := 1000.0; let mut unmetDays := 0
  for seed in [4, 5, 6, 7, 8, 9, 10, 11, 12, 13] do
    let r := runHome home (Policy.static p) seed 365
    imp := imp + r.totals.importKwh; unmet := unmet + r.totals.unmetKwh
    cold := cold + r.totals.coldHours; bs := bs + r.totals.backstopKwh
    low0 := min low0 r.totals.minTankKwh[0]!; low1 := min low1 r.totals.minTankKwh[1]!
    let mut day := 1000000; 
    for h in r.hours do
      if h.tanks.any (fun (t : TankHour) => t.unmetKwh > 0.000001) && h.day != day then
        unmetDays := unmetDays + 1; day := h.day
  IO.println s!"{label}: import {f1 (imp / 10.0)} kWh/yr | unmet {f1 (unmet / 10.0)} kWh/yr on {f1 (unmetDays.toFloat / 10.0)} days/yr | cold hours {f1 (cold.toFloat / 10.0)}/yr | lowest 250L {f1 low0} kWh, 180L {f1 low1} kWh | grid heat {f1 (bs / 10.0)}"

def main : IO Unit := do
  let some home := homeNamed "mine" | IO.println "no home"
  let timer : StaticParams :=
    { windows := #[{ heatStart := 12, heatHours := 7 }, { heatStart := 10, heatHours := 7 }], dischargeFrom := 14, flexStart := 14 }
  IO.println "Fixed timer. 'sensor' = thermostat cuts in at half level at any hour. 'no sensor' = heat only in the timer window, and from 20:00 if not full that day."
  for (cv, name) in [(0.25, "normal days"), (0.5, "very variable days")] do
    for (scale, sname) in [(1.0, "usual use"), (1.3, "30% more use")] do
      report s!"sensor,    {name}, {sname}" (variant home 0.5 cv scale) timer
      report s!"no sensor, {name}, {sname}" (variant home 0.0 cv scale) timer
