extends Node

# แจ้งว่าผู้เล่นกดปุ่มยิง
signal fire_pressed
# แจ้งเมื่อ Zombie ถูกกำจัด
signal zombie_died

# แจ้งเมื่อผู้เล่นตาย
signal player_died

# แจ้งจำนวนเงินที่ได้รับ โดยส่งจำนวนเงินผ่าน amount
signal money_added(amount : int)

signal wave_passed    # จบ wave ทั่วไป -> main โชว์ปุ่ม shop / GameManager บวกเลข wave
signal level_passed   # จบ wave สุดท้าย -> ฉากจบเกม (ไม่บวกเลข wave)
