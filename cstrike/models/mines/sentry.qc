/*
==============================================================================

QC script generated by Half-Life MDL Decompiler 1.2 
2003, Kratisto. Based on code from Valve's HL SDK.

sentry.mdl

Original internal name:
"DGF_sentryHL.mdl"

==============================================================================
*/

$modelname "sentry.mdl"
$cd ".\"
$cdtexture ".\"
$scale 1.0
$cliptotextures


$bbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$cbox 0.000000 0.000000 0.000000 0.000000 0.000000 0.000000
$eyeposition 0.000000 0.000000 0.000000


//reference mesh(es)
$body "DGF" "DGF_sentry_new"


// 2 attachment(s)
$attachment 0 "sentry_gun_main" 0.000000 -16.000000 1.500000
$attachment 1 "sentry_gun_main" 0.000000 0.000000 0.000000

// 2 bone controller(s)
$controller 0 "sentry_neck" YR 0.000000 360.000000
$controller 1 "sentry_gun_main" XR -60.000000 60.000000

// 8 hit box(es)
$hbox 0 "sentry_body" -7.810000 -3.760000 -8.440000 7.800000 4.370000 7.740000
$hbox 0 "sentry_neck" -4.890000 0.000000 -5.970000 7.650000 22.950001 5.630000
$hbox 0 "sentry_gun_main" -2.000000 -12.850000 -2.080000 1.990000 3.940000 3.220000
$hbox 0 "sentry_gun_barrel" -1.590000 -7.830000 -1.590000 1.580000 0.000000 1.580000
$hbox 0 "sentry_radar_main" -0.530000 -0.530000 -1.780000 6.680000 4.810000 1.730000
$hbox 0 "sentry_leg_1" -2.750000 -26.010000 -9.140000 2.780000 0.000000 0.970000
$hbox 0 "sentry_leg_2" -7.710000 -26.010000 -2.570000 2.550000 0.000000 7.620000
$hbox 0 "sentry_leg_3" -2.590000 -26.010000 -2.570000 7.670000 0.000000 7.620000

// 7 animation sequence(s)
$sequence "idle_off" "idle_off" fps 0 
$sequence "fire" "fire" fps 40 loop {
  { event 5001 5 "21" } 
  { event 5001 10 "21" } 
  { event 5001 15 "31" } 
  { event 5001 20 "21" } 
  { event 5001 25 "21" } 
  { event 5001 30 "31" } 
  { event 5001 35 "21" } 
  { event 5001 39 "21" } 
 }
$sequence "spin" "spin" fps 40 loop 
$sequence "deploy" "deploy" fps 50 
$sequence "retire" "retire" fps 25 
$sequence "die" "die" fps 50 
$sequence "Made by DGF" "Made by DGF" fps 0 

// End of QC script.
