extends Node

signal fire_pressed
signal zombie_died

signal player_died

signal money_added(amount : int)

signal wave_passed    # จบ wave ทั่วไป -> main โชว์ปุ่ม shop / GameManager บวกเลข wave
signal level_passed   # จบ wave สุดท้าย -> ฉากจบเกม (ไม่บวกเลข wave)
