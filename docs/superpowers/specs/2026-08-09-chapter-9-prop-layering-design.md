# Chapter 9 Prop Layering Design

## เป้าหมาย

พร็อพทั้ง 4 ชิ้นใน `Chapter9Props` ได้แก่ `FireTowerA`, `FireTowerB`, `DarkTowerA` และ `DarkTowerB` ต้องแสดงอยู่เหนือพระรามและทศกัณฐ์เสมอเมื่อภาพซ้อนกัน

## แนวทาง

กำหนดลำดับการวาดให้ `Chapter9Props` ผ่าน `chapter_9.gd` โดยตั้ง `z_index` ของกลุ่มพร็อพให้สูงกว่า `YSortRoot` ซึ่งเป็นกลุ่มของพระรามและทศกัณฐ์ วิธีนี้ทำให้พร็อพทุกชิ้นในกลุ่มใช้กฎเดียวกัน และไม่ต้องแก้ตำแหน่งหรือโครงสร้างใน `chapter_9.tscn`

การเปลี่ยนแปลงจะไม่กระทบ Background, Collision, UI, บอสบาร์, การต่อสู้ หรือระบบกล้อง Chapter 9

## การตรวจสอบ

- เพิ่ม regression test ตรวจว่า Chapter 9 กำหนดเลเยอร์ของ `Chapter9Props` สูงกว่า `YSortRoot`
- รัน Chapter 9 regression tests และชุดทดสอบทั้งหมด
- ตรวจว่า `scenes/chapter_9/chapter_9.tscn` และ `scenes/chapter_2/chapter_2.tscn` ที่ผู้ใช้แก้ค้างไว้ไม่ถูก stage หรือเขียนทับ
