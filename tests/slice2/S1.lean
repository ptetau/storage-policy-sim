import tests.slice.Harness
import StoragePolicySim.Scenario
import StoragePolicySim.PhysWeather

open StoragePolicySim

def lat : Float := -41.3

def lt (a b : Float) : Bool := a < b
def le (a b : Float) : Bool := a ≤ b
def ge (a b : Float) : Bool := a ≥ b

def mkTest (name : String) (checks : List (Bool × String)) : Harness.Test :=
  { name := name, run := pure (Harness.firstFail checks) }

def sumF (xs : Array Float) : Float :=
  xs.foldl (fun (a b : Float) => a + b) 0.0

/-- Mean of `xs` from index `a` to index `b`, both included. -/
def meanRange (xs : Array Float) (a b : Nat) : Float := Id.run do
  let mut s := 0.0
  for i in [a:b+1] do
    s := s + xs[i]!
  return s / (b + 1 - a).toFloat

/-- Pearson correlation of two arrays of the same size. -/
def corr (xs ys : Array Float) : Float := Id.run do
  let n := xs.size
  let nf := n.toFloat
  let mx := sumF xs / nf
  let my := sumF ys / nf
  let mut sxy := 0.0
  let mut sxx := 0.0
  let mut syy := 0.0
  for i in [0:n] do
    let dx := xs[i]! - mx
    let dy := ys[i]! - my
    sxy := sxy + dx * dy
    sxx := sxx + dx * dx
    syy := syy + dy * dy
  return sxy / Float.sqrt (sxx * syy)

def flatArray : PanelArray := { kw := 5.0, direction := 0.0, tilt := 0.0 }
def northArray : PanelArray := { kw := 5.0, direction := 0.0, tilt := 30.0 }
def southArray : PanelArray := { kw := 5.0, direction := 180.0, tilt := 30.0 }

/-- Clearness of seed 7 and of seed 8 over a year, and the clearness of the days. -/
def cl7 : Array Float := clearness lat 7 365
def cl7b : Array Float := clearness lat 7 365
def cl8 : Array Float := clearness lat 8 365
def dc7 : Array Float := dayClearness lat 7 365

/-- Index of the highest step of day `d`, the first one on a tie. -/
def peakStep (d : Nat) : Nat := Id.run do
  let mut best := 0
  let mut bv := clearSkyWm2 lat d 0
  for s in [1:96] do
    let v := clearSkyWm2 lat d s
    if v > bv then
      best := s
      bv := v
  return best

def peakValue (d : Nat) : Float := clearSkyWm2 lat d (peakStep d)

def tests : List Harness.Test := [
  mkTest "test_002_S1_R1_haurwitz_sun_straight_up"
    (let v := haurwitzWm2 1.0
     [(Harness.near v 1035.1 0.1, s!"haurwitzWm2 1.0 = {v}, want 1035.1")]),
  mkTest "test_002_S1_R1_haurwitz_cos_half"
    (let v := haurwitzWm2 0.5
     [(Harness.near v 487.9 0.1, s!"haurwitzWm2 0.5 = {v}, want 487.9")]),
  mkTest "test_002_S1_R1_haurwitz_sun_down_is_zero"
    (let a := haurwitzWm2 0.0
     let b := haurwitzWm2 (-0.3)
     [(Harness.near a 0.0 0.000000001, s!"haurwitzWm2 0.0 = {a}, want 0"),
      (Harness.near b 0.0 0.000000001, s!"haurwitzWm2 (-0.3) = {b}, want 0")]),
  mkTest "test_002_S1_R1_clear_sky_midnight_zero_and_peak_at_noon"
    (let v0 := clearSkyWm2 lat 0 0
     let p := peakStep 0
     [(Harness.near v0 0.0 0.000000001, s!"clearSkyWm2 step 0 = {v0}, want 0"),
      (p == 47 || p == 48, s!"peak step of day 0 is {p}, want 47 or 48")]),
  mkTest "test_002_S1_R1_summer_noon_beats_winter_noon"
    (let a := peakValue 0
     let b := peakValue 171
     [(lt b a, s!"noon of day 0 = {a}, noon of day 171 = {b}, want day 0 higher")]),

  mkTest "test_002_S1_R2_clearness_has_35040_values_in_range"
    (let n := cl7.size
     let bad := cl7.foldl (fun (c : Nat) (x : Float) => if ge x 0.15 && le x 1.0 then c else c + 1) 0
     [(n == 35040, s!"size {n}, want 35040"),
      (bad == 0, s!"{bad} values outside 0.15 to 1.0")]),
  mkTest "test_002_S1_R2_same_seed_same_values"
    (let same := Id.run do
       let mut diff := 0
       for i in [0:cl7.size] do
         if cl7[i]! != cl7b[i]! then diff := diff + 1
       return diff
     [(cl7.size == cl7b.size, s!"sizes {cl7.size} and {cl7b.size}"),
      (same == 0, s!"{same} values differ for the same seed")]),
  mkTest "test_002_S1_R2_other_seed_differs_in_1000_values"
    (let diff := Id.run do
       let mut c := 0
       for i in [0:cl7.size] do
         if cl7[i]! != cl8[i]! then c := c + 1
       return c
     [(cl8.size == 35040, s!"seed 8 size {cl8.size}, want 35040"),
      (diff ≥ 1000, s!"seed 8 differs in {diff} values, want at least 1000")]),
  mkTest "test_002_S1_R2_day_to_day_correlation"
    (let n := dc7.size
     let c := corr (dc7.extract 0 (n - 1)) (dc7.extract 1 n)
     [(n == 365, s!"dayClearness size {n}, want 365"),
      (ge c 0.4 && le c 0.8, s!"day to day correlation {c}, want 0.4 to 0.8")]),
  mkTest "test_002_S1_R2_summer_mean_above_winter_mean"
    (let a := meanRange dc7 0 89
     let b := meanRange dc7 152 242
     [(lt b a, s!"mean days 0-89 = {a}, mean days 152-242 = {b}, want first above second")]),
  mkTest "test_002_S1_R2_step_to_step_correlation"
    (let n := cl7.size
     let c := corr (cl7.extract 0 (n - 1)) (cl7.extract 1 n)
     [(lt 0.5 c, s!"step to step correlation {c}, want above 0.5")]),

  mkTest "test_002_S1_R3_diffuse_share_clear"
    (let v := diffuseShare 1.0
     [(Harness.near v 0.1831 0.0005, s!"diffuseShare 1.0 = {v}, want 0.1831")]),
  mkTest "test_002_S1_R3_diffuse_share_dull"
    (let v := diffuseShare 0.2
     [(Harness.near v 0.9865 0.0005, s!"diffuseShare 0.2 = {v}, want 0.9865")]),
  mkTest "test_002_S1_R3_flat_panel_gets_flat_sunlight"
    (let worst := Id.run do
       let mut w := 0.0
       for s in [0:96] do
         let p := panelWm2 lat flatArray 0 s 0.7
         let e := clearSkyWm2 lat 0 s * 0.7
         let d := (p - e).abs
         if d > w then w := d
       return w
     [(le worst 0.001, s!"largest gap between flat panel light and 0.7 times clear sky: {worst}")]),
  mkTest "test_002_S1_R3_clear_day_north_panel_beats_south_panel"
    (let n := panelWm2 lat northArray 0 48 1.0
     let s := panelWm2 lat southArray 0 48 1.0
     [(lt s n, s!"north {n}, south {s}, want north more")]),
  mkTest "test_002_S1_R3_dull_day_north_and_south_almost_equal"
    (let n := panelWm2 lat northArray 0 48 0.15
     let s := panelWm2 lat southArray 0 48 0.15
     let big := if n > s then n else s
     [(lt 0.0 big, s!"larger light is {big}, want above 0"),
      (lt (Float.abs (n - s)) (0.15 * big), s!"north {n}, south {s}, want a gap under 15% of the larger")]),

  mkTest "test_002_S1_R4_array_output_cell_25"
    (let v := arrayKw flatArray 1000.0 (-6.25)
     [(Harness.near v 4.5 0.001, s!"arrayKw 5 kW, 1000 W/m2, cell 25 = {v}, want 4.5")]),
  mkTest "test_002_S1_R4_array_output_cell_45"
    (let c := cellTempC 20.0 800.0
     let v := arrayKw flatArray 800.0 20.0
     [(Harness.near c 45.0 0.001, s!"cellTempC 20 800 = {c}, want 45"),
      (Harness.near v 3.312 0.001, s!"arrayKw 5 kW, 800 W/m2, air 20 = {v}, want 3.312")]),
  mkTest "test_002_S1_R4_hotter_cell_gives_less"
    (let cold := arrayKw flatArray 600.0 5.0
     let hot := arrayKw flatArray 600.0 35.0
     [(lt hot cold, s!"output at air 5 = {cold}, at air 35 = {hot}, want hot below cold")]),
  mkTest "test_002_S1_R4_no_light_gives_zero"
    (let v := arrayKw flatArray 0.0 20.0
     [(Harness.near v 0.0 0.000000001, s!"arrayKw with no light = {v}, want 0")]),

  mkTest "test_002_S1_R5_air_temperature_midsummer_afternoon"
    (let v := airTempC lat 15 60 1.0
     [(Harness.near v 21.0 0.01, s!"air day 15 at 15:00 = {v}, want 21.0")]),
  mkTest "test_002_S1_R5_air_temperature_midsummer_night"
    (let v := airTempC lat 15 12 1.0
     [(Harness.near v 14.0 0.01, s!"air day 15 at 03:00 = {v}, want 14.0")]),
  mkTest "test_002_S1_R5_air_temperature_midwinter_afternoon"
    (let v := airTempC lat 197 60 1.0
     [(Harness.near v 12.0 0.01, s!"air day 197 at 15:00 = {v}, want 12.0")]),
  mkTest "test_002_S1_R5_dull_day_is_one_degree_lower"
    (let a := airTempC lat 15 60 1.0
     let b := airTempC lat 15 60 0.5
     [(Harness.near (a - b) 1.0 0.01, s!"clear {a}, clearness 0.5 {b}, want a drop of 1.0")]),
  mkTest "test_002_S1_R5_afternoon_warmer_than_early_morning"
    (let a := airTempC lat 100 60 0.8
     let b := airTempC lat 100 20 0.8
     [(lt b a, s!"15:00 = {a}, 05:00 = {b}, want 15:00 warmer")]),
  mkTest "test_002_S1_R5_inlet_temperature_day_45"
    (let v := inletTempC lat 45
     [(Harness.near v 17.0 0.01, s!"inletTempC day 45 = {v}, want 17.0")]),
  mkTest "test_002_S1_R5_inlet_temperature_day_227"
    (let v := inletTempC lat 227
     [(Harness.near v 11.0 0.05, s!"inletTempC day 227 = {v}, want 11.0")]),
  mkTest "test_002_S1_R5_inlet_lags_the_air"
    (let airPeak := airTempC lat 15 60 1.0
     let inletAtAirPeak := inletTempC lat 15
     let inletLater := inletTempC lat 45
     [(lt inletAtAirPeak inletLater, s!"inlet day 15 = {inletAtAirPeak}, inlet day 45 = {inletLater}, want day 45 higher"),
      (lt 0.0 airPeak, s!"air peak {airPeak}")])
]

def main (args : List String) : IO UInt32 := Harness.run tests args
