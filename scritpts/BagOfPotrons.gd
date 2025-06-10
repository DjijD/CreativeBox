extends Node3D

# Vieglās munīcijas daudzums
var light_ammunition = 0
# Smagās munīcijas daudzums
var heavy_ammunition = 0

# MP5 ierocim pašreizējais un maksimālais munīcijas daudzums
var mp5_current_ammo: int = 30
var mp5_max_ammo: int = 30
# MP5 izmanto vieglo munīciju
var mp5_ammo_type: String = "light_ammunition"

# VECTOR ierocim pašreizējais un maksimālais munīcijas daudzums
var vector_current_ammo: int = 17
var vector_max_ammo: int = 17
# VECTOR izmanto vieglo munīciju
var vector_ammo_type: String = "light_ammunition"
