extends Node

signal fire_pressed
signal zombie_died

signal player_died

signal money_added(amount : int)

signal wave_passed    # จบ wave ทั่วไป -> main โชว์ปุ่ม shop / GameManager บวกเลข wave
signal level_passed   # จบ wave สุดท้าย -> ฉากจบเกม (ไม่บวกเลข wave)

# ---- Gambling ----
signal orb_rolled(outcome : Dictionary)                 # เก็บ Lucky Orb แล้ว -> HUD เริ่มหมุน
signal orb_applied(outcome : Dictionary, detail : String)  # ผลถูกใช้จริง -> HUD โชว์ผล
signal buffs_changed                                    # buff ชั่วคราวเปลี่ยน
