# 🌿 12 Years Later (12 Năm Sau — Mộc Thành)

Một tựa game kết hợp giữa **Urban Life-Sim** (Stardew Valley / Persona) và **Điều Tra Ký Ức Đa Tầng** (A Space for the Unbound) trên nền tảng **Godot Engine 4.7**.

> **"Sau 12 năm, nơi này còn phải là 'nhà' của mình không?"**

### 🎮 Khởi Chạy Game Chính Thức
- **Scene chính:** [`res://scenes/main/moc_thanh_game.tscn`](file:///d:/00.gamedev/new-city-game/new-city/scenes/main/moc_thanh_game.tscn)
- **Script điều khiển chính:** [`res://scenes/main/moc_thanh_game.gd`](file:///d:/00.gamedev/new-city-game/new-city/scenes/main/moc_thanh_game.gd)
- **Tài liệu thiết kế kiến trúc (GDD):** [`twelve_years_later_game_design.md`](file:///C:/Users/admin/.gemini/antigravity-ide/brain/426316e6-8cae-43f9-b571-2a7f993eb3a1/twelve_years_later_game_design.md)

### 🕹️ Bảng Phím Tắt Điều Khiển
| Phím | Hành Động | Chi Tiết |
|---|---|---|
| **`W`, `A`, `S`, `D` / Mũi tên** | Di chuyển 8 hướng | Di chuyển nhân vật / Lái xe tuần tra với gia tốc và quán tính mượt mà |
| **`Shift`** | Chạy nhanh / Tăng tốc | Đi bộ nhanh hơn hoặc nhấn ga xe chạy với tốc độ cao |
| **`E` / `Space`** | Tương tác / Nói chuyện | Trò chuyện với bạn cũ, mua sắm, nhận manh mối, giải mã bí mật |
| **`M`** | **Sổ Tay Điều Tra** | Mở/Đóng bảng ghim manh mối (`Rumor -> Memory -> Evidence -> Truth`) |
| **`K`** | **Ký Ức 12 Năm Trước** | Kích hoạt hiệu ứng hoài niệm Flashback tuổi 17 trên cùng không gian bản đồ |
| **`F`** | Lên / Xuống xe | Lên xe cảnh sát tuần tra (nổ máy, còi hú) hoặc rời xe đi bộ |
| **`H`** | Bóp còi xe (Car Horn) | Phát âm thanh còi xe thực tế đôi âm |
| **`G`** | Bật / Tắt còi hú Siren | Kích hoạt còi hú khẩn cấp tuần tra |
| **`R`** | Về Nhà Cũ | Đưa nhân vật và xe về Căn nhà cũ phủ bụi |
| **Cuộn chuột** | Zoom Camera | Thu phóng góc nhìn thành phố Mộc Thành |

---

## 📑 Mục Lục
1. [Hệ Thống NPC (Nhân Vật)](#-hệ-thống-npc-nhân-vật)
   * [Kiến Trúc Hướng Đối Tượng NPC](#-kiến-trúc-hướng-đối-tượng-npc)
   * [Cách Thêm NPC Mới Chỉ Bằng Tên Và Ảnh](#-cách-thêm-npc-mới-chỉ-bằng-tên-và-ảnh)
   * [Test Scene & Phím Tắt Điều Khiển NPC](#-test-scene--phím-tắt-điều-khiển-npc)
   * [Danh Mục 44 NPC](#-danh-mục-44-npc-hiện-có-trong-game)
2. [Hệ Thống Phương Tiện (Vehicles)](#-hệ-thống-phương-tiện-vehicles)
   * [Kiến Trúc Hướng Đối Tượng Xe & Phân Cấp Lớp](#-kiến-trúc-hướng-đối-tượng-xe--phân-cấp-lớp)
   * [Xử Lý Hình Xe To Nhỏ & Frame Khác Nhau](#-xử-lý-hình-xe-to-nhỏ--frame-khác-nhau)
   * [Chế Độ Còi Đèn Khẩn Cấp (Siren Mode)](#-chế-độ-còi-đèn-khẩn-cấp-siren-mode)
   * [Cách Thêm Phương Tiện Mới Chỉ Bằng Tên Và Ảnh](#-cách-thêm-phương-tiện-mới-chỉ-bằng-tên-và-ảnh)
   * [Vehicle Test Scene & Phím Tắt](#-vehicle-test-scene--phím-tắt)
   * [Danh Mục 25 Phương Tiện](#-danh-mục-25-phương-tiện-hiện-có-trong-game)
3. [Hệ Thống Tòa Nhà & Hoạt Ảnh Cửa (Buildings)](#-hệ-thống-tòa-nhà--hoạt-ảnh-cửa-buildings)
   * [Kiến Trúc Hướng Đối Tượng Tòa Nhà](#-kiến-trúc-hướng-đối-tượng-tòa-nhà)
   * [Danh Sách Tòa Nhà 2 Cửa & Biến Thể Màu](#-danh-sách-tòa-nhà-2-cửa--biến-thể-màu)
   * [Building Test Scene & Phím Tắt](#-building-test-scene--phím-tắt)
   * [Danh Mục 45 Tòa Nhà](#-danh-mục-45-tòa-nhà-hiện-có-trong-game)
4. [Hệ Thống Tileset Terrain & Xây Dựng Bản Đồ (Map & Terrains)](#-hệ-thống-tileset-terrain--xây-dựng-bản-đồ-map--terrains)
   * [Tổng Quan Đồ Họa & Cấu Trúc Lưới 16x16](#-tổng-quan-đồ-họa--cấu-trúc-lưới-16x16)
   * [Hệ Thống Terrain Sets & Autotiling 3x3](#-hệ-thống-terrain-sets--autotiling-3x3)
   * [Lớp Dữ Liệu Tùy Chỉnh (Custom Data Layers)](#-lớp-dữ-liệu-tùy-chỉnh-custom-data-layers)
   * [Bộ Quản Lý Bản Đồ CityMapManager API](#-bộ-quản-lý-bản-đồ-citymapmanager-api)
   * [Map Test Scene & Phím Tắt Điều Khiển](#-map-test-scene--phím-tắt-điều-khiển)
5. [Cấu Trúc Thư Mục Dự Án](#-cấu-trúc-thư-mục-dự-án)

---

# 🚶 Hệ Thống NPC (Nhân Vật)

## 🏛️ Kiến Trúc Hướng Đối Tượng NPC

Hệ thống NPC được thiết kế phân tách rõ ràng giữa **Dữ liệu (Data/Model)**, **Thực thể điều khiển (Controller/Entity)** và **Quản lý trung tâm (Registry/Factory)**:

### 1. `NPCData` (`res://scripts/npcs/NPCData.gd`) — Model / Resource
* Kế thừa từ `Resource`, đóng gói toàn bộ dữ liệu tĩnh của nhân vật:
  * **Thông tin định danh:** `id` (`StringName`), `display_name` (`String`), `role` (`StringName`), `gender` (`StringName`), `description` (`String`).
  * **Dữ liệu hình ảnh:** `sprite_frames` (`SpriteFrames`), `spritesheet_path` (`String`).
  * **Chỉ số Gameplay:** `move_speed` (`float`), `wander_radius` (`float`), `min_idle_time`, `max_idle_time`.
  * **Hội thoại & Tương tác:** `interaction_type`, `dialogues` (`Array[String]`), `tags` (`PackedStringArray`).
* Cung cấp các phương thức nghiệp vụ: `get_random_dialogue()`, `has_tag()`, `is_valid()`.
* **Static Factory Methods:** `create_from_texture()`, `build_sprite_frames_from_texture()`, `save_to_tres()`.

### 2. `NPCBase` (`res://scenes/characters/npc_base.gd`) — Base Controller Entity
* Kế thừa từ `CharacterBody2D`, đóng gói toàn bộ logic vật lý và hoạt ảnh 2.5D:
  * **Máy trạng thái (State Machine):** `IDLE`, `WANDER`, `NAVIGATE`, `TALKING`, `DISABLED`.
  * **Bộ ánh xạ hoạt ảnh 2.5D:** Tự động điều phối 8 animation (`idle` và `walk` x 4 hướng: `front_right`, `front_left`, `back_right`, `back_left`).
  * **Thuộc tính Inspector:** `@export_enum("front_right", "front_left", "back_right", "back_left") var facing_direction_name`: Chọn hướng quay mặt trực tiếp trong Inspector của Godot.
  * **Phương thức ảo cho lớp con ghi đè (Polymorphic Virtual Hooks):**
    * `_setup_npc()`: Tùy biến khởi tạo riêng của từng loại NPC.
    * `_on_interact(initiator)`: Hành vi khi được tương tác (mặc định xoay mặt và mở hội thoại).
    * `_get_dialogue()`: Trả về câu thoại tương ứng.
    * `_on_behavior_tick(delta)`: Xử lý logic mỗi khung hình vật lý.
    * `_on_state_changed(old_state, new_state)`: Phản hồi khi đổi trạng thái.
  * **Signals (Decoupling):** `interacted`, `dialogue_spoken`, `state_changed`, `destination_reached`.
  * **Y-Sorting:** Gốc toạ độ `(0, 0)` tại bàn chân nhân vật (`Visual.position = Vector2(0, -20)`, `BodyCollision.position = Vector2(0, -4)`), đảm bảo xếp lớp độ sâu tự nhiên khi di chuyển.

### 3. Các lớp kế thừa chuyên biệt (Inheritance & Polymorphism)
* **`CivilianNPC` (`res://scripts/npcs/civilian_npc.gd`):** Người dân thành thị, tự do đi dạo và chào hỏi thân thiện.
* **`PoliceNPC` (`res://scripts/npcs/police_npc.gd`):** Cảnh sát tuần tra an ninh, kiểm tra trật tự khu vực.
* **`ServiceNPC` (`res://scripts/npcs/service_npc.gd`):** NPC ngành nghề (Bác sĩ, Đầu bếp, Thợ xây, Cứu hỏa...) với câu thoại nghiệp vụ.

### 4. `NPCRegistry` (`res://scripts/npcs/npc_registry.gd`) — Central Registry & Factory
* Đăng ký làm **Autoload Singleton** trong `project.godot`.
* Tự động quét và lập chỉ mục toàn bộ file `.tres` trong thư mục `res://data/npcs/`.
* Cho phép tra cứu theo ID (`&"001"`..`&"044"`), tên tài nguyên (`&"police_male_01"`), hoặc lọc theo `role` / `gender`.
* **Factory Method:** `NPCRegistry.spawn_npc(id, spawn_position, parent)` tạo ngay 1 NPC vào màn chơi.

---

## 🚀 Cách Thêm NPC Mới Chỉ Bằng Tên Và Ảnh

### Quy chuẩn file ảnh Spritesheet
* **Định dạng:** Ảnh `.png` nền trong suốt (RGBA).
* **Kích thước tổng:** `512 x 96` pixel.
* **Bố cục khung hình (16 cột x 2 hàng, mỗi ô 32x48 px):**
  * **Hàng 0 (y = 0, cao 48px - Trạng thái Đứng IDLE):**
    * Cột 0..3 (x = 0, 32, 64, 96): `idle_front_left` (Nhìn trước - trái)
    * Cột 4..7 (x = 128, 160, 192, 224): `idle_front_right` (Nhìn trước - phải)
    * Cột 8..11 (x = 256, 288, 320, 352): `idle_back_right` (Nhìn sau - phải)
    * Cột 12..15 (x = 384, 416, 448, 480): `idle_back_left` (Nhìn sau - trái)
  * **Hàng 1 (y = 48, cao 48px - Trạng thái Đi bộ WALK):**
    * Cột 0..3 (x = 0, 32, 64, 96): `walk_front_left`
    * Cột 4..7 (x = 128, 160, 192, 224): `walk_front_right`
    * Cột 8..11 (x = 256, 288, 320, 352): `walk_back_right`
    * Cột 12..15 (x = 384, 416, 448, 480): `walk_back_left`

### 🌟 Cách 1: Tự Động Quét & Thêm Hàng Loạt (Auto-Sync)
1. Thả file ảnh `.png` mới vào: `res://assets/spritesheets/characters/`
2. Mở terminal và chạy:
   ```bash
   python tools/add_npc.py --sync
   ```

### ⚡ Cách 2: Thêm Bằng 1 Dòng Lệnh CLI
```bash
python tools/add_npc.py Security-Guard.png "Bảo Vệ Ca Đêm" police male 60
```

### 🛠️ Cách 3: Tạo Bằng GDScript
```gdscript
var tex = load("res://assets/spritesheets/characters/Hero.png")
var hero_data = NPCData.create_from_texture(tex, &"hero_01", "Hiệp Sĩ", &"police", &"male")
hero_data.save_to_tres()
```

---

## 🎮 Test Scene & Phím Tắt Điều Khiển NPC

* **Đường dẫn Scene:** `res://scenes/test/npc_test_scene.tscn` (Mặc định khi ấn **F5**).
* **Phím tắt:**
  * **WASD / Mũi tên:** Di chuyển góc nhìn Camera.
  * **Giữ Chuột giữa / Chuột phải:** Kéo rê (Pan) Camera.
  * **Cuộn chuột:** Phóng to / Thu nhỏ (Zoom).
  * **Phím R:** Xoay vòng hướng (Trước-Phải -> Trước-Trái -> Sau-Phải -> Sau-Trái).
  * **Phím 1, 2, 3, 4:** Đặt nhanh hướng tương ứng.
  * **Phím Space:** Bật/Tắt chế độ tự do đi dạo (`Auto-Wander AI`).
  * **Click chuột trái vào NPC:** Trò chuyện.

---

## 📋 Danh Mục 44 NPC Hiện Có Trong Game

| ID | File `.tres` | Tên hiển thị | Vai trò | Giới tính | Spritesheet nguồn |
| :---: | :--- | :--- | :--- | :---: | :--- |
| **001** | `police_male_01.tres` | Cảnh Sát Nam | `police` | Nam | `City-Characters_09.png` |
| **002** | `police_female_01.tres` | Cảnh Sát Nữ | `police` | Nữ | `City-Characters_10.png` |
| **003** | `construction_male_01.tres` | Thợ Xây Nam | `construction` | Nam | `City-Characters_11.png` |
| **004** | `construction_female_01.tres` | Thợ Xây Nữ | `construction` | Nữ | `City-Characters_12.png` |
| **005** | `doctor_male_01.tres` | Bác Sĩ Nam | `doctor` | Nam | `City-Characters_13.png` |
| **006** | `doctor_female_01.tres` | Bác Sĩ Nữ | `doctor` | Nữ | `City-Characters_14.png` |
| **007** | `chef_male_01.tres` | Đầu Bếp Nam | `chef` | Nam | `City-Characters_15.png` |
| **008** | `chef_female_01.tres` | Đầu Bếp Nữ | `chef` | Nữ | `City-Characters_16.png` |
| **009** | `office_male_01.tres` | Nhân Viên Văn Phòng Nam | `office` | Nam | `City-Characters_17.png` |
| **010** | `office_female_01.tres` | Nhân Viên Văn Phòng Nữ | `office` | Nữ | `City-Characters_18.png` |
| **011** | `sanitation_male_01.tres` | Nhân Viên Môi Trường Nam | `sanitation` | Nam | `City-Characters_19.png` |
| **012** | `sanitation_female_01.tres` | Nhân Viên Môi Trường Nữ | `sanitation` | Nữ | `City-Characters_20.png` |
| **013** | `delivery_male_01.tres` | Nhân Viên Giao Hàng Nam | `delivery` | Nam | `City-Characters_21.png` |
| **014** | `delivery_female_01.tres` | Nhân Viên Giao Hàng Nữ | `delivery` | Nữ | `City-Characters_22.png` |
| **015** | `senior_male_01.tres` | Cụ Ông | `senior` | Nam | `City-Characters_23.png` |
| **016** | `senior_female_01.tres` | Cụ Bà | `senior` | Nữ | `City-Characters_24.png` |
| **017** | `firefighter_male_01.tres` | Lính Cứu Hỏa Nam | `firefighter` | Nam | `City-Characters_25.png` |
| **018** | `firefighter_female_01.tres` | Lính Cứu Hỏa Nữ | `firefighter` | Nữ | `City-Characters_26.png` |
| **019** | `executive_male_01.tres` | Doanh Nhân Nam | `executive` | Nam | `City-Characters_27.png` |
| **020** | `executive_female_01.tres` | Doanh Nhân Nữ | `executive` | Nữ | `City-Characters_28.png` |
| **021** | `citizen_male_01.tres` | Cư Dân Nam Áo Xanh | `civilian` | Nam | `City-Characters_01.png` |
| **022** | `citizen_female_01.tres` | Cư Dân Nữ Áo Tím | `civilian` | Nữ | `City-Characters_02.png` |
| **023** | `citizen_male_02.tres` | Cư Dân Nam Áo Xám | `civilian` | Nam | `City-Characters_03.png` |
| **024** | `citizen_female_02.tres` | Cư Dân Nữ Áo Nâu | `civilian` | Nữ | `City-Characters_04.png` |
| **025** | `citizen_male_03.tres` | Cư Dân Nam Áo Rêu | `civilian` | Nam | `City-Characters_05.png` |
| **026** | `citizen_female_03.tres` | Cư Dân Nữ Áo Hồng | `civilian` | Nữ | `City-Characters_06.png` |
| **027** | `citizen_male_04.tres` | Cư Dân Nam Áo Hoodie | `civilian` | Nam | `City-Characters_07.png` |
| **028** | `citizen_female_04.tres` | Cư Dân Nữ Áo Ngọc | `civilian` | Nữ | `City-Characters_08.png` |
| **029** | `resident_male_01.tres` | Thanh Niên Nam Áo Khoác Bò | `civilian` | Nam | `Character-Variation-1_01.png` |
| **030** | `resident_female_01.tres` | Thanh Niên Nữ Áo Đỏ Cam | `civilian` | Nữ | `Character-Variation-1_02.png` |
| **031** | `resident_male_02.tres` | Thanh Niên Nam Áo Lam Nón Vàng | `civilian` | Nam | `Character-Variation-1_03.png` |
| **032** | `resident_female_02.tres` | Thanh Niên Nữ Áo Xanh Biển | `civilian` | Nữ | `Character-Variation-1_04.png` |
| **033** | `resident_male_03.tres` | Thanh Niên Nam Cardigan Xám | `civilian` | Nam | `Character-Variation-1_05.png` |
| **034** | `resident_female_03.tres` | Thanh Niên Nữ Đồ Thể Thao | `civilian` | Nữ | `Character-Variation-1_06.png` |
| **035** | `resident_male_04.tres` | Thanh Niên Nam Đồ Thể Thao Lam | `civilian` | Nam | `Character-Variation-1_07.png` |
| **036** | `resident_female_04.tres` | Thanh Niên Nữ Áo Cam Đất | `civilian` | Nữ | `Character-Variation-1_08.png` |
| **037** | `resident_male_05.tres` | Thanh Niên Nam Áo Sơ Mi Nâu | `civilian` | Nam | `Character-Variation-1_09.png` |
| **038** | `resident_female_05.tres` | Thanh Niên Nữ Áo Tím Oải Hương | `civilian` | Nữ | `Character-Variation-1_10.png` |
| **039** | `resident_male_06.tres` | Thanh Niên Nam Áo Choàng Đỏ | `civilian` | Nam | `Character-Variation-1_11.png` |
| **040** | `resident_female_06.tres` | Thanh Niên Nữ Áo Hồng Phấn | `civilian` | Nữ | `Character-Variation-1_12.png` |
| **041** | `resident_male_07.tres` | Thanh Niên Nam Bomber Xanh Đậm | `civilian` | Nam | `Character-Variation-1_13.png` |
| **042** | `resident_female_07.tres` | Thanh Niên Nữ Áo Xanh Cốm | `civilian` | Nữ | `Character-Variation-1_14.png` |
| **043** | `resident_male_08.tres` | Thanh Niên Nam Áo Khoác Xanh Xám | `civilian` | Nam | `Character-Variation-1_15.png` |
| **044** | `resident_female_08.tres` | Thanh Niên Nữ Áo Cam Pastel | `civilian` | Nữ | `Character-Variation-1_16.png` |

---

# 🚗 Hệ Thống Phương Tiện (Vehicles)

Hệ thống phương tiện được thiết kế theo mô hình Hướng đối tượng (OOP) tương tự NPC, nhưng giải quyết bài toán đặc thù: **Kích thước xe to nhỏ khác biệt lớn (từ xe con 96x96 px đến phà khổng lồ 352x352 px)**, cấu trúc hàng/cột animation đa dạng và chế độ còi đèn khẩn cấp (Siren).

---

## 🏛️ Kiến Trúc Hướng Đối Tượng Xe & Phân Cấp Lớp

### 1. `VehicleData` (`res://scripts/vehicles/VehicleData.gd`) — Model / Resource
* Kế thừa từ `Resource`, định nghĩa:
  * **Kích thước thích ứng:** `frame_size: Vector2i` (kích thước từng frame của xe), `visual_offset: Vector2` (độ dời visual để bánh xe chạm đất `(0, 0)`), `collision_size: Vector2` (hộp va chạm tương ứng kích cỡ xe).
  * **Thông số vận hành:** `max_speed`, `acceleration`, `deceleration`, `turn_speed`.
  * **Phân loại & Trang bị:** `vehicle_type` (`car`, `emergency`, `bus`, `truck`, `heavy`, `air`, `water`, `shop`), `category` (`land`, `air`, `water`, `static`), `passenger_capacity`, `has_siren: bool`.
  * **Factory Methods:** `create_from_texture()`, `build_sprite_frames_from_texture()`, `save_to_tres()`.

### 2. `VehicleBase` (`res://scenes/vehicles/vehicle_base.gd` & `VehicleBase.tscn`) — Base Controller Entity
* Kế thừa từ `CharacterBody2D`, cung cấp:
  * **Tự động thích ứng kích thước:** Khi gán `data`, node tự động chỉnh `CollisionShape2D.shape.size = data.collision_size` và `Visual.position = data.visual_offset`.
  * **Điều phối hướng 2.5D:** `@export_enum("front_right", "front_left", "back", "front") var facing_direction_name`.
  * **Hệ thống Siren:** `@export var siren_active: bool`. Khi bật, tự động chuyển đổi giữa bộ animation `drive_*` và `siren_*`.
  * **Tương tác:** Click chuột trái hoặc bấm E để bật/tắt còi Siren hoặc vào xe.

### 3. Phân Cấp Lớp Chuyên Biệt (Inheritance & Polymorphism)
* **`CarVehicle` (`res://scripts/vehicles/car_vehicle.gd`):** Ô tô thông dụng, taxi, xe con đô thị.
* **`EmergencyVehicle` (`res://scripts/vehicles/emergency_vehicle.gd`):** Xe khẩn cấp (Cảnh sát, Cứu thương, Cứu hỏa) với logic đèn chớp, còi hú và quyền ưu tiên giao thông.
* **`LargeVehicle` (`res://scripts/vehicles/large_vehicle.gd`):** Xe cỡ lớn & hạng nặng (Xe buýt, Máy ủi, Xe tải ẩm thực) với góc cua rộng và quán tính lớn.
* **`WaterVehicle` (`res://scripts/vehicles/water_vehicle.gd`):** Phương tiện đường thủy (Thuyền nhỏ, Tàu hàng, Phà) với hiệu ứng bồng bềnh mặt nước (`bobbing_amplitude`, `bobbing_speed`).

### 4. `VehicleRegistry` (`res://scripts/vehicles/vehicle_registry.gd`) — Autoload Singleton
* Đăng ký tự động trong `project.godot` (`VehicleRegistry`).
* Quét và lập chỉ mục toàn bộ file `.tres` trong `res://data/vehicles/`.
* Cung cấp các hàm tiện ích:
  * `VehicleRegistry.get_vehicle_data(id)`
  * `VehicleRegistry.get_by_category("land" | "air" | "water")`
  * `VehicleRegistry.get_by_type("emergency" | "car" | ...)`
  * `VehicleRegistry.spawn_vehicle(id, position, parent)`

---

## 📐 Xử Lý Hình Xe To Nhỏ & Frame Khác Nhau

Các spritesheet trong thư mục `assets/spritesheets/vehicles/` có kích thước rất đa dạng:

| Phân Loại | Kích thước Frame | Hàng x Cột | Animation Tương Ứng | Danh Sách Xe Áp Dụng |
| :--- | :---: | :---: | :--- | :--- |
| **Xe Ô Tô Nhỏ** | `96 x 96` px | 4 hàng x 4 cột | `drive_front_right`, `drive_front_left`, `drive_back`, `drive_front` | Ô tô Đen, Xanh Đậm, Xám, Cam, Hồng, Trắng |
| **Xe Tiêu Chuẩn & Taxi** | `112 x 112` px | 4 hàng x 4 cột | `drive_front_right`, `drive_front_left`, `drive_back`, `drive_front` | Ô tô Xanh Dương, Xanh Lá, Đỏ, Taxi Vàng, Taxi Đô Thị, Xe Đẩy Đồ Ăn |
| **Xe Khẩn Cấp (Siren)** | `112x112`, `160x160`, `176x176` | **8 hàng** x 4 cột | Hàng 0..3: `drive_*`<br>Hàng 4..7: `siren_*` (chớp đèn) | Cảnh Sát (112x112), Cứu Thương (160x160), Cứu Hỏa (176x176) |
| **Xe Hạng Nặng & Buýt** | `160x160`, `176x176` | 4 hàng x 4 cột | `drive_front_right`, `drive_front_left`, `drive_back`, `drive_front` | Xe Buýt (176x176), Xe Ủi (160x160), Xe Tải Foodtruck (160x160) |
| **Quầy Hàng Lưu Động** | `136 x 96` px | 1 hàng x 2 cột | `idle` (quầy bán tại chỗ) | Food truckshop (Cố định) |
| **Trực Thăng** | `192 x 128` px | 2 hàng x 4 cột | `fly_right` (Hàng 0), `fly_left` (Hàng 1) | Trực thăng Dân dụng, Trực thăng Cứu hộ |
| **Thuyền & Tàu Nhỏ** | `80 x 80` px | 4 hàng x 4 cột | `drive_front_right`, `drive_front_left`, `drive_back`, `drive_front` | Thuyền Nhỏ Đường Sông |
| **Tàu Hàng Thương Mại** | `192 x 192` px | 4 hàng x 4 cột | `drive_front_right`, `drive_front_left`, `drive_back`, `drive_front` | Tàu Chở Hàng Bến Cảng |
| **Phà Lớn Chở Khách** | `352 x 352` px | 4 hàng x 4 cột | `drive_front_right`, `drive_front_left`, `drive_back`, `drive_front` | Phà Lớn 2 Bờ Sông |

### Công Thức Tự Động Căn Chỉnh:
* **Hộp va chạm bánh xe (Collision Box):**
  $$\text{Width} = \text{Frame Width} \times 0.45, \quad \text{Height} = \text{Frame Height} \times 0.22$$
* **Độ dời Visual (Visual Offset):**
  $$\text{Offset Y} = -\text{Frame Height} \times 0.35$$
  *(Đảm bảo phần bánh xe hoặc đáy thuyền tiếp xúc chính xác tại toạ độ gốc `(0, 0)` giúp Y-Sorting hoạt động hoàn hảo).*

---

## 🚨 Chế Độ Còi Đèn Khẩn Cấp (Siren Mode)

* Các xe khẩn cấp (`Police car`, `Ambulance`, `Firetruck`) có 8 hàng trong spritesheet:
  * **Hàng 0..3:** Hoạt ảnh di chuyển thông thường (`drive_front_right`, `drive_front_left`, `drive_back`, `drive_front`).
  * **Hàng 4..7:** Hoạt ảnh di chuyển kèm còi đèn khẩn cấp chớp nháy (`siren_front_right`, `siren_front_left`, `siren_back`, `siren_front`).
* Có thể bật/tắt bằng cách:
  * Trong Inspector: Tick chọn thuộc tính `@export var siren_active: bool`.
  * Trong Code: `veh.siren_active = true`.
  * Trong Test Scene: Bấm phím **S** hoặc click chuột trái vào xe.

---

## 🚀 Cách Thêm Phương Tiện Mới Chỉ Bằng Tên Và Ảnh

### 🌟 Cách 1: Tự Động Quét & Thêm Hàng Loạt (Auto-Sync)
1. Thả ảnh spritesheet xe `.png` vào: `res://assets/spritesheets/vehicles/`
2. Mở terminal và chạy:
   ```bash
   python tools/add_vehicle.py --sync
   ```
* Script tự động đọc header ảnh PNG để xác định kích thước pixel thực tế, trích xuất kích cỡ frame từ tên file (nếu có dạng `(112x112)`) hoặc tự chia tỷ lệ theo số hàng/cột, thiết lập hộp va chạm và tạo file `.tres` hoàn chỉnh.

### ⚡ Cách 2: Thêm Bằng CLI Kèm Tham Số
```bash
python tools/add_vehicle.py "SportsCar-(96x96)Sheet.png" "Xe Thể Thao Đua" car land 96 96 160 false
```
* **Cú pháp:**
  `python tools/add_vehicle.py <file_ảnh> <tên_hiển_thị> [loại_xe] [danh_mục] [frame_w] [frame_h] [tốc_độ] [có_siren]`

### 🛠️ Cách 3: Tạo Bằng GDScript
```gdscript
var tex = load("res://assets/spritesheets/vehicles/SuperCar.png")
var veh_data = VehicleData.create_from_texture(
    tex, 
    &"super_car_01", 
    "Siêu Xe Thể Thao", 
    Vector2i(96, 96), 
    &"car", 
    &"land", 
    180.0, 
    false
)
veh_data.save_to_tres()
```

---

## 🎮 Vehicle Test Scene & Phím Tắt

* **Đường dẫn Scene:** `res://scenes/test/vehicle_test_scene.tscn`
* **Bố trí:** Đủ 24 phương tiện xếp thành lưới 6 cột x 4 hàng với nhãn tên, kích thước frame và cờ Siren.
* **Phím tắt điều khiển:**
  * **`W`, `A`, `S`, `D` / Mũi tên:** Di chuyển góc nhìn Camera.
  * **Giữ Chuột giữa / Chuột phải:** Kéo rê (Pan) Camera tự do.
  * **Cuộn con lăn Chuột:** Thu phóng (Zoom in / Zoom out).
  * **Phím `R`:** Xoay vòng hướng toàn bộ xe (`Trước-Phải` -> `Trước-Trái` -> `Phía Sau` -> `Phía Trước`).
  * **Phím `1`, `2`, `3`, `4`:** Đổi nhanh hướng của tất cả xe.
  * **Phím `Space` hoặc `E`:** Bật / Tắt còi đèn Siren đồng loạt cho các xe khẩn cấp.
  * **Phím `F`:** Đặt lại góc quay Camera về mặc định.
  * **Click Chuột trái vào xe:** Xem bảng thông số chi tiết (Kích thước frame, va chạm, tốc độ, sức chứa, mô tả).

---

## 📋 Danh Mục 25 Phương Tiện Hiện Có Trong Game

| ID | File `.tres` | Tên hiển thị | Loại xe | Frame (px) | Tốc độ | Còi Siren | Spritesheet nguồn |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **veh_001** | `car_black_01.tres` | Xe Ô Tô Đen | `car` | 96x96 | 120 | Không | `Black Car-(96x96)Sheet.png` |
| **veh_002** | `car_dark_blue_01.tres` | Xe Ô Tô Xanh Đậm | `car` | 96x96 | 120 | Không | `Dark Blue Car-(96x96)Sheet.png` |
| **veh_003** | `car_grey_01.tres` | Xe Ô Tô Xám | `car` | 96x96 | 120 | Không | `Grey Car-(96x96)Sheet.png` |
| **veh_004** | `car_orange_01.tres` | Xe Ô Tô Cam | `car` | 96x96 | 125 | Không | `Orange Car-Sheet.png` |
| **veh_005** | `car_pink_01.tres` | Xe Ô Tô Hồng | `car` | 96x96 | 120 | Không | `Pink Car-(96x96)Sheet.png` |
| **veh_006** | `car_white_01.tres` | Xe Ô Tô Trắng | `car` | 96x96 | 120 | Không | `White Car-(96x96)Sheet.png` |
| **veh_007** | `car_blue_01.tres` | Xe Ô Tô Xanh Dương | `car` | 112x112 | 125 | Không | `Blue car-Sheet(112x112).png` |
| **veh_008** | `car_green_01.tres` | Xe Ô Tô Xanh Lá | `car` | 112x112 | 125 | Không | `Green car-Sheet(112x112).png` |
| **veh_009** | `car_red_01.tres` | Xe Ô Tô Đỏ Thể Thao | `car` | 112x112 | 135 | Không | `Red car-Sheet(112x112).png` |
| **veh_010** | `taxi_standard_01.tres` | Xe Taxi Đô Thị | `taxi` | 112x112 | 130 | Không | `Taxi-Sheet(112x112).png` |
| **veh_011** | `taxi_yellow_01.tres` | Xe Taxi Vàng | `taxi` | 112x112 | 130 | Không | `Taxi Yellow(112x112)t.png` |
| **veh_012** | `food_cart_01.tres` | Xe Đẩy Đồ Ăn Đường Phố | `cart` | 112x112 | 45 | Không | `FoodCart-Sheet(112x112).png` |
| **veh_013** | `police_car_01.tres` | Xe Cảnh Sát Tuần Tra | `emergency` | 112x112 | 150 | **CÓ** | `Police car-Sheet(112x112).png` |
| **veh_014** | `ambulance_01.tres` | Xe Cứu Thương Y Tế | `emergency` | 160x160 | 140 | **CÓ** | `Ambulance-Sheet(160x160).png` |
| **veh_015** | `firetruck_01.tres` | Xe Cứu Hỏa | `emergency` | 176x176 | 130 | **CÓ** | `Firetruck (176x176)-Sheet.png` |
| **veh_016** | `bus_city_01.tres` | Xe Buýt Công Cộng | `bus` | 176x176 | 95 | Không | `Bus-Sheet(176x176).png` |
| **veh_017** | `bulldozer_01.tres` | Xe Ủi Đất Công Trình | `heavy` | 160x160 | 60 | Không | `BullDozer-Sheet(160x160).png` |
| **veh_018** | `foodtruck_moving_01.tres` | Xe Tải Ẩm Thực Lưu Động | `truck` | 160x160 | 90 | Không | `Foodtruck-Sheet.png` |
| **veh_019** | `food_truck_shop_01.tres` | Quầy Rơ-Moóc Ẩm Thực | `shop` | 114x96 | 0 | Không | `Food truckshop-Sheet.png` (Trái) |
| **veh_020** | `helicopter_civilian_01.tres` | Trực Thăng Dân Dụng | `air` | 192x128 | 200 | Không | `Helicopter sheet.png` |
| **veh_021** | `helicopter_rescue_01.tres` | Trực Thăng Cứu Hộ / Tuần Tra | `air` | 192x128 | 210 | **CÓ** | `Helicopter sheet1.png` |
| **veh_022** | `boat_small_01.tres` | Thuyền Nhỏ Đường Sông | `water` | 80x80 | 85 | Không | `Small Boat(80x80)-Sheet.png` |
| **veh_023** | `ship_trade_01.tres` | Tàu Chở Hàng Thương Mại | `water` | 192x192 | 70 | Không | `Trade Ship-Sheet(192x192).png` |
| **veh_024** | `ship_ferry_01.tres` | Phà Lớn Chở Khách | `water` | 352x352 | 65 | Không | `Ferry(352x352)-Sheet.png` |
| **veh_025** | `food_truck_shop_02.tres` | Xe Tải Ẩm Thực Mở Quầy | `shop` | 154x96 | 0 | Không | `Food truckshop-Sheet.png` (Phải) |

---

# 🏢 Hệ Thống Tòa Nhà & Hoạt Ảnh Cửa (Buildings)

Hệ thống tòa nhà đô thị được thiết kế theo mô hình **OOP & Data-Driven**, hỗ trợ đầy đủ các tính năng đặc thù:
* **Tòa nhà 2 cửa độc lập:** Mở/đóng riêng biệt Cửa Trái và Cửa Phải (hoặc Cửa Đi Bộ và Cửa Cuốn Gara Xe).
* **Cùng loại khác màu chung 1 ảnh:** Tách các hàng biến thể màu (Beachhouse xanh/vàng/hồng) thành các tài nguyên độc lập.
* **Tương tác trực tiếp:** Click chuột vào từng cánh cửa hoặc bước vào khu vực cửa để kích hoạt mở/đóng với tính năng tự đóng sau thời gian chờ (`auto_close_delay`).

---

## 🏛️ Kiến Trúc Hướng Đối Tượng Tòa Nhà

### 1. `BuildingData` (`res://scripts/buildings/BuildingData.gd`) — Model / Resource
* Kế thừa từ `Resource`, đóng gói:
  * **Thông tin định danh:** `id`, `display_name`, `building_type` (`commercial`, `public`, `emergency`, `residential`, `industrial`, `amenity`), `description`.
  * **Cấu trúc cửa:** `door_count: int` (1 hoặc 2), `door_names: Array[String]`, `color_variant: String`.
  * **Hình ảnh & Va chạm:** `frame_size: Vector2i`, `collision_size: Vector2`, `collision_offset: Vector2`, `door_positions: Array[Vector2]`.
  * **Bộ hoạt ảnh `sprite_frames`:**
    * Cửa đơn: `door_closed`, `door_open`, `door_opened`, `door_close`, `door_cycle`.
    * Hai cửa (Trái & Phải): `door_left_closed`, `door_left_open`, `door_left_opened`, `door_left_close`, `door_right_closed`, `door_right_open`, `door_right_opened`, `door_right_close`.

### 2. `BuildingBase` (`res://scenes/buildings/building_base.gd` & `BuildingBase.tscn`) — Controller Entity
* Kế thừa từ `StaticBody2D` (vật thể tĩnh có va chạm vật lý và xếp lớp Y-Sort).
* **Phương thức điều khiển cửa:**
  * `open_door(door_index)` / `close_door(door_index)` / `toggle_door(door_index)`.
  * `open_all_doors()` / `close_all_doors()` / `toggle_all_doors()`.
* **Inspector Preview:** Cho phép bật/tắt `@export var door_0_open` và `door_1_open` trực tiếp trong 2D Editor để xem trước trạng thái cửa!
* **Tự động đóng cửa:** `@export var auto_close_delay: float = 3.5` giây sau khi mở.

### 3. Phân Cấp Lớp Chuyên Biệt (Inheritance & Polymorphism)
* **`CommercialBuilding` (`res://scripts/buildings/commercial_building.gd`):** Cửa hàng, quán ăn, siêu thị, ngân hàng với chuông báo khách mở cửa.
* **`EmergencyBuilding` (`res://scripts/buildings/emergency_building.gd`):** Trạm cứu hỏa và đồn cảnh sát, tích hợp lệnh báo động khẩn cấp và mở cửa cuốn gara cho xe xuất kích (`dispatch_vehicle()`).
* **`ResidentialBuilding` (`res://scripts/buildings/residential_building.gd`):** Khu dân cư, nhà ở, nhà bãi biển đa màu sắc.
* **`PublicBuilding` (`res://scripts/buildings/public_building.gd`):** Công trình công cộng (Thư viện, Nhà tù, Bệnh viện, Nhà vệ sinh Nam/Nữ).

### 4. `BuildingRegistry` (`res://scripts/buildings/building_registry.gd`) — Autoload Singleton
* Đăng ký tự động trong `project.godot` (`BuildingRegistry`).
* Cung cấp các phương thức: `get_building_data(id)`, `get_two_door_buildings()`, `get_by_type(type)`, `spawn_building(id, pos, parent)`.

---

## 🚪 Danh Sách Tòa Nhà 2 Cửa & Biến Thể Màu

### 1. Tòa Nhà 2 Cửa Đóng Mở Độc Lập
| ID | Tòa Nhà | Kích Thước | Cửa 1 (Trái / Bộ) | Cửa 2 (Phải / Gara) |
| :---: | :--- | :---: | :--- | :--- |
| **bld_001** | Trạm Cứu Hỏa Thành Phố | 304x224 | Cửa Nhân Viên | Cửa Cuốn Gara Xuất Xe |
| **bld_002** | Đồn Cảnh Sát Thành Phố | 224x160 | Cửa Văn Phòng Kính | Cửa Cuốn Gara Xe Tuần Tra |
| **bld_003** | Thư Viện Trung Tâm | 224x160 | Cửa Cánh Trái | Cửa Cánh Phải |
| **bld_004** | Trại Giam / Nhà Tù | 272x176 | Cổng Thép An Ninh Trái | Cổng Thép An Ninh Phải |
| **bld_005** | Nhà Vệ Sinh Công Cộng | 112x96 | Cửa Nam (Trái) | Cửa Nữ (Phải) |

### 2. Tòa Nhà Biến Thể Nhiều Màu (Chung 1 Ảnh)
* **`Beachhouseblue Animation.png` (3 hàng = 3 màu):**
  * `bld_006`: Nhà Bãi Biển Xanh Dương (`blue`)
  * `bld_007`: Nhà Bãi Biển Vàng Kem (`yellow`)
  * `bld_008`: Nhà Bãi Biển Hồng Pastel (`pink`)
* **`Small Beach House-Sheet.png` (3 hàng = 3 màu):**
  * `bld_009`: Nhà Gỗ Bãi Biển Vàng (`yellow`)
  * `bld_010`: Nhà Gỗ Bãi Biển Đỏ (`red`)
  * `bld_011`: Nhà Gỗ Bãi Biển Xanh (`blue`)

---

## 🎮 Building Test Scene & Phím Tắt

* **Đường dẫn Scene:** `res://scenes/test/building_test_scene.tscn`
* **Bố trí:** Đủ **45 tòa nhà** xếp thành lưới 9 cột x 5 hàng với nhãn tên, kích cỡ, cờ `[2 CỬA]`.
* **Phím tắt điều khiển:**
  * **`W`, `A`, `S`, `D` / Mũi tên:** Di chuyển góc nhìn Camera.
  * **Giữ Chuột giữa / Chuột phải:** Kéo rê (Pan) Camera tự do.
  * **Cuộn con lăn Chuột:** Thu phóng (Zoom in / Zoom out).
  * **Phím `Space` hoặc `E`:** Mở / Đóng đồng loạt toàn bộ cửa của 45 tòa nhà.
  * **Phím `1`:** Mở Cửa 1 (Cửa Trái) của các tòa nhà.
  * **Phím `2`:** Mở Cửa 2 (Cửa Phải / Cửa Gara) của các tòa nhà 2 cửa.
  * **Phím `3` hoặc `C`:** Đóng toàn bộ cửa.
  * **Phím `F`:** Đặt lại góc quay Camera về mặc định.
  * **Click Chuột trái vào cửa:** Đóng/mở cửa tương ứng và hiển thị bảng thông số chi tiết.

---

## 📋 Danh Mục 45 Tòa Nhà Hiện Có Trong Game

| ID | File `.tres` | Tên hiển thị | Loại | Kích thước | Cửa | Biến thể màu |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: |
| **bld_001** | `firestation_01.tres` | Trạm Cứu Hỏa Thành Phố | `emergency` | 304x224 | **2 CỬA** | Mặc định |
| **bld_002** | `police_station_01.tres` | Đồn Cảnh Sát Thành Phố | `emergency` | 224x160 | **2 CỬA** | Mặc định |
| **bld_003** | `library_city_01.tres` | Thư Viện Trung Tâm | `public` | 224x160 | **2 CỬA** | Mặc định |
| **bld_004** | `prison_city_01.tres` | Trại Giam / Nhà Tù | `public` | 272x176 | **2 CỬA** | Mặc định |
| **bld_005** | `restroom_public_01.tres` | Nhà Vệ Sinh Công Cộng | `amenity` | 112x96 | **2 CỬA** | Mặc định |
| **bld_006** | `beachhouse_blue_01.tres` | Nhà Bãi Biển Xanh Dương | `residential` | 176x176 | 1 Cửa | Xanh Dương |
| **bld_007** | `beachhouse_yellow_01.tres` | Nhà Bãi Biển Vàng Kem | `residential` | 176x176 | 1 Cửa | Vàng Kem |
| **bld_008** | `beachhouse_pink_01.tres` | Nhà Bãi Biển Hồng Pastel | `residential` | 176x176 | 1 Cửa | Hồng Pastel |
| **bld_009** | `small_beachhouse_yellow_01.tres` | Nhà Gỗ Bãi Biển Vàng | `residential` | 128x144 | 1 Cửa | Vàng |
| **bld_010** | `small_beachhouse_red_01.tres` | Nhà Gỗ Bãi Biển Đỏ | `residential` | 128x144 | 1 Cửa | Đỏ |
| **bld_011** | `small_beachhouse_blue_01.tres` | Nhà Gỗ Bãi Biển Xanh | `residential` | 128x144 | 1 Cửa | Xanh Biển |
| **bld_012** | `bakery_standard_01.tres` | Tiệm Bánh Mì Cổ Điển | `commercial` | 112x160 | 1 Cửa | Mặc định |
| **bld_013** | `bakery_clean_01.tres` | Tiệm Bánh Mì Hiện Đại | `commercial` | 112x144 | 1 Cửa | Mặc định |
| **bld_014** | `bank_central_01.tres` | Ngân Hàng Trung Tâm | `commercial` | 208x208 | 1 Cửa | Mặc định |
| **bld_015** | `bar_pub_01.tres` | Quán Rượu / Bar Phố | `commercial` | 96x144 | 1 Cửa | Mặc định |
| **bld_016** | `bar_clean_01.tres` | Quán Bar Hiện Đại Clean | `commercial` | 96x144 | 1 Cửa | Mặc định |
| **bld_017** | `barbershop_01.tres` | Tiệm Cắt Tóc Barbershop | `commercial` | 144x128 | 1 Cửa | Mặc định |
| **bld_018** | `barbershop_clean_01.tres` | Tiệm Cắt Tóc Hiện Đại | `commercial` | 144x128 | 1 Cửa | Mặc định |
| **bld_019** | `brick_building_01.tres` | Tòa Nhà Gạch Nâu | `residential` | 112x208 | 1 Cửa | Mặc định |
| **bld_020** | `burgershop_01.tres` | Tiệm Bánh Burger | `commercial` | 176x128 | 1 Cửa | Mặc định |
| **bld_021** | `cafe_shop_01.tres` | Quán Cà Phê Phố | `commercial` | 144x112 | 1 Cửa | Mặc định |
| **bld_022** | `cafe_clean_01.tres` | Quán Cà Phê Hiện Đại | `commercial` | 144x112 | 1 Cửa | Mặc định |
| **bld_023** | `campus_building_01.tres` | Tòa Giảng Đường Campus | `public` | 112x208 | 1 Cửa | Mặc định |
| **bld_024** | `cinema_theater_01.tres` | Rạp Chiếu Phim Cinema | `commercial` | 208x224 | 1 Cửa | Mặc định |
| **bld_025** | `convenient_store_01.tres` | Cửa Hàng Tiện Lợi 24/7 | `commercial` | 160x160 | 1 Cửa | Mặc định |
| **bld_026** | `convenient_store_clean_01.tres` | Cửa Hàng Tiện Lợi Clean | `commercial` | 160x160 | 1 Cửa | Mặc định |
| **bld_027** | `fast_food_restaurant_01.tres` | Nhà Hàng Thức Ăn Nhanh | `commercial` | 176x128 | 1 Cửa | Mặc định |
| **bld_028** | `gas_station_01.tres` | Trạm Xăng Đô Thị | `commercial` | 208x160 | 1 Cửa | Mặc định |
| **bld_029** | `green_brick_building_01.tres` | Tòa Nhà Gạch Xanh Lá | `residential` | 112x192 | 1 Cửa | Mặc định |
| **bld_030** | `hospital_city_01.tres` | Bệnh Viện Đa Khoa | `emergency` | 144x320 | 1 Cửa | Mặc định |
| **bld_031** | `hotel_grand_01.tres` | Khách Sạn Grand Hotel | `commercial` | 192x192 | 1 Cửa | Mặc định |
| **bld_032** | `inn_hotel_01.tres` | Quán Trọ Lữ Hành Inn | `commercial` | 144x176 | 1 Cửa | Mặc định |
| **bld_033** | `japanese_restaurant_01.tres` | Nhà Hàng Nhật Bản | `commercial` | 160x112 | 1 Cửa | Mặc định |
| **bld_034** | `lightblue_building_01.tres` | Tòa Nhà Xanh Nhạt | `residential` | 144x224 | 1 Cửa | Mặc định |
| **bld_035** | `lighthouse_01.tres` | Ngọn Hải Đăng Cảng Biển | `public` | 128x288 | 1 Cửa | Mặc định |
| **bld_036** | `mall_shopping_01.tres` | Trung Tâm Thương Mại Mall | `commercial` | 224x304 | 1 Cửa | Mặc định |
| **bld_037** | `motel_lodge_01.tres` | Nhà Nghỉ Ven Đường Motel | `commercial` | 208x176 | 1 Cửa | Mặc định |
| **bld_038** | `pizza_shop_01.tres` | Tiệm Pizza Ý | `commercial` | 144x128 | 1 Cửa | Mặc định |
| **bld_039** | `pizza_shop_clean_01.tres` | Tiệm Pizza Hiện Đại | `commercial` | 144x128 | 1 Cửa | Mặc định |
| **bld_040** | `portable_office_01.tres` | Văn Phòng Di Động | `industrial` | 128x112 | 1 Cửa | Mặc định |
| **bld_041** | `portable_toilet_01.tres` | Nhà Vệ Sinh Lưu Động | `amenity` | 32x96 | 1 Cửa | Mặc định |
| **bld_042** | `ramen_stand_01.tres` | Quán Mì Ramen Nhật | `commercial` | 128x128 | 1 Cửa | Mặc định |
| **bld_043** | `supermarket_city_01.tres` | Siêu Thị Đô Thị Supermarket | `commercial` | 304x176 | 1 Cửa | Mặc định |
| **bld_044** | `wood_building_01.tres` | Tòa Nhà Gỗ Truyền Thống | `residential` | 112x176 | 1 Cửa | Mặc định |
| **bld_045** | `yellow_building_01.tres` | Tòa Nhà Màu Vàng | `residential` | 112x192 | 1 Cửa | Mặc định |

# 🗺️ Hệ Thống Tileset Terrain & Xây Dựng Bản Đồ (Map & Terrains)

Hệ thống Tileset và Địa hình được thiết kế chuẩn mực theo kiến trúc **TileMapLayer** của **Godot 4.3+ / 4.7**, phục vụ việc xây dựng thế giới mở đô thị với khả năng tự động nối viền (Autotiling/Terrains), nhận diện bề mặt di chuyển và phân làn giao thông thông minh.

---

## 🎨 Tổng Quan Đồ Họa & Cấu Trúc Lưới 16x16

* **Tệp ảnh nguồn:** `res://assets/tilesets/GroundTiles.png` (và alias `res://tilesets/GroundTiles.png`)
* **Kích thước ảnh:** `976 x 880` pixel
* **Kích thước ô chuẩn (Tile Size):** `16 x 16` pixel
* **Số lượng ô lưới:** `61 cột x 55 hàng` = `3.355 ô` (Trong đó có **3.059 ô chứa dữ liệu đồ họa** hợp lệ).
* **Tài nguyên TileSet tạo sẵn:** `res://data/tilesets/city_tileset.tres` (và alias `res://tilesets/city_tileset.tres`).

### Các phân vùng chức năng trên Spritesheet:
1. **Giao Lộ Trung Tâm 4 Ngả (4-Way Intersection):**
   * Mặt đường nhựa cao cấp (Dark asphalt) với các vạch phân làn đứt nét và vạch liền.
   * Vạch qua đường cho người đi bộ (Zebra crossings) ở cả 4 nhánh Bắc - Nam - Đông - Tây.
   * Bờ vỉa hè bo góc lượn và bờ đá vây quanh mặt đường.
2. **Khu Vực Bãi Đỗ Xe (Parking Bays):**
   * Các ô đỗ xe kẻ vạch trắng có chữ ký hiệu **"P"** chuẩn đô thị.
3. **Làn Xe Buýt Chuyên Dụng (Bus Lane):**
   * Mặt đường màu xanh lá đặc trưng với dòng chữ **"BUS LANE"** màu trắng.
4. **Hệ Thống Mũi Tên Chỉ Hướng (Road Arrows):**
   * Mũi tên rẽ trái, rẽ phải, đi thẳng, quay đầu xe (U-turn) và mũi tên ngã ba.
5. **Vỉa Hè Đa Dạng (Sidewalks & Pavements):**
   * Đá lát xám (Grey Cobblestone), Gạch nung nâu đỏ (Terracotta Brick), Đá phiến đen (Dark Slate Pavers), Đá hoa mosaic sáng màu.
6. **Địa Hình Tự Nhiên (Natural Terrain):**
   * Bãi cỏ xanh mướt (Grass) kèm các cụm hoa dại vàng/đỏ trang trí.
   * Bãi cát bờ biển / đất cát vàng (Sand Shore).
   * Đường mòn đất nâu (Dirt Path).
   * Vùng nước tự nhiên và hồ bơi nhân tạo (Water / Ponds / Pools) có viền bờ và gợn sóng.
7. **Công Trình Tiện Ích Đô Thị (Plazas & Sports):**
   * Sân bóng rổ (Basketball Court) đầy đủ vạch kẻ sân và khu vực ném rổ.
   * Bục nâng cao có bậc thang (Elevated platforms with stairs).
   * Nắp cống thoát nước (Drainage grates) và miệng cống ngầm.

---

## 🧩 Hệ Thống Terrain Sets & Autotiling 3x3

Godot 4 sử dụng cơ chế **Terrain Sets** để người thiết kế màn chơi chỉ cần dùng cọ vẽ (Connect brush) là hệ thống tự động chọn đúng ô góc, ô cạnh và ô lõi:

### 1. `Terrain Set 0` — Mode: `Match Corners and Sides` (Blob Autotile 3x3)
Hỗ trợ đầy đủ 8 hướng tiếp giáp (4 cạnh + 4 góc chéo) cho các mảng địa hình tự nhiên và bo góc:
* **Terrain 0 (`Grass`):** Cỏ xanh tự nhiên (Khối 3x3 tại cột 55..57, hàng 7..9 và hàng 12..14).
* **Terrain 1 (`Dirt`):** Đường mòn đất nâu (Khối 3x3 tại cột 52..54, hàng 7..9 và cột 46..48, hàng 12..14).
* **Terrain 2 (`Sand`):** Bãi cát ven biển / đất vàng (Khối 3x3 tại cột 49..51, hàng 12..14).
* **Terrain 3 (`Water`):** Mặt nước hồ, ao sâu (Khối 3x3 tại cột 40..45, hàng 12..14 và cột 46..48, hàng 7..9).
* **Terrain 4 (`Sidewalk_Stone`):** Vỉa hè đá xám (Khối 3x3 tại cột 43..45, hàng 7..9).
* **Terrain 5 (`Sidewalk_Brick`):** Vỉa hè gạch nâu đỏ (Vùng chữ thập tại cột 6..12 và 19..25).
* **Terrain 6 (`Sidewalk_Dark`):** Lối đi đá đen than (Khối 3x3 tại cột 58..60, hàng 7..9 và cột 52..54, hàng 12..14).
* **Terrain 7 (`Road_Asphalt`):** Mặt đường nhựa đô thị & giao lộ.
* **Terrain 8 (`Platform_Stone`):** Bục đá nâng cao / sân thượng (Khối 3x3 tại cột 40..42, hàng 7..9).

### 2. `Terrain Set 1` — Mode: `Match Sides` (Autotile 4 Cạnh)
Tương thích 9 loại địa hình tương tự, khớp theo 4 hướng chính (Bắc - Nam - Đông - Tây), vẽ các đường đi nhanh chóng không bị lỗi góc.

---

## 🏷️ Lớp Dữ Liệu Tùy Chỉnh (Custom Data Layers)

Mỗi ô trong tổng số 3.059 ô tile đều được gán metadata phục vụ logic game:

| Tên Lớp Dữ Liệu | Kiểu Dữ Liệu | Ý Nghĩa & Ứng Dụng |
| :--- | :--- | :--- |
| `surface_type` | `String` | Loại bề mặt: `"road"`, `"sidewalk"`, `"grass"`, `"dirt"`, `"sand"`, `"water"`, `"court"`, `"platform"` |
| `speed_multiplier` | `float` | Hệ số tốc độ: `1.0x` (Đường nhựa / Vỉa hè), `0.8x` (Cỏ), `0.75x` (Đất), `0.6x` (Cát), `0.0x` (Nước) |
| `is_road` | `bool` | `true` nếu là đường dành cho xe cộ lưu thông (Traffic AI / Vehicle routing) |
| `is_sidewalk` | `bool` | `true` nếu là vỉa hè người đi bộ (NPC Pedestrian wander zone) |
| `is_water` | `bool` | `true` nếu là mặt nước (Chỉ tàu thuyền `WaterVehicle` mới đi được) |
| `is_crosswalk` | `bool` | `true` nếu là vạch sang đường (Ưu tiên người đi bộ qua đường) |
| `is_parking` | `bool` | `true` nếu là vị trí bãi đỗ xe chữ P |

### Hệ Thống Vật Lý (Physics Layer 0):
* Tất cả các ô nước sâu (`surface_type == "water"`) và vật cản được cấu hình sẵn **Hộp va chạm Collision Polygon 16x16** trên Layer 1, ngăn chặn người chơi, NPC và xe trên bờ đi xuyên xuống nước.

---

## 🗺️ Bộ Quản Lý Bản Đồ CityMapManager API

Tệp script: `res://scripts/world/city_map_manager.gd` (kế thừa `Node2D`):

```gdscript
# Chuyển đổi tọa độ
var tile_pos: Vector2i = map_manager.world_to_tile(player.global_position)
var world_pos: Vector2 = map_manager.tile_to_world(tile_pos)

# Truy vấn thông tin mặt đất tại chân nhân vật / xe cộ
var surface: String = map_manager.get_surface_type(pos) # "road", "grass", "water", v.v.
var speed: float = map_manager.get_speed_multiplier(pos) # 1.0, 0.8, v.v.

# Kiểm tra cờ khu vực
if map_manager.is_road(pos):
    print("Xe đang chạy trên đường nhựa hợp lệ")
if map_manager.is_sidewalk(pos):
    print("NPC đang đi trên vỉa hè")
if map_manager.is_crosswalk(pos):
    print("Người đi bộ đang qua đường tại vạch kẻ")
if map_manager.is_water(pos):
    print("Khu vực nước cấm xe đường bộ!")
```

---

## 🎮 Map Test Scene & Phím Tắt Điều Khiển

Tệp scene: `res://scenes/test/map_test_scene.tscn`

Scene hoàn chỉnh mẫu 60x60 ô (960x960 px) kết hợp:
* **GroundLayer:** Thảm cỏ xanh bao la, ao nước sâu, bãi cát ven hồ, đường đất uốn lượn, sân bóng rổ.
* **RoadLayer:** Ngã tư đường nhựa lớn 4 hướng, vạch qua đường ở 4 nhánh, bãi đỗ xe ô tô chữ P, làn xe buýt xanh.
* **DecorationLayer:** Mũi tên chỉ hướng phân làn, cụm hoa dại điểm xuyết trên cỏ.
* **Entities (Y-Sort):** Tòa nhà Trạm cứu hỏa (`bld_001` - mở cửa khi lại gần), Xe cảnh sát/công cộng (`veh_016` đỗ ở bãi xe), NPC người dân dạo bước trên vỉa hè (`npc_001`).

### Phím tắt & Thao tác điều khiển:
| Phím / Chuột | Thao Tác |
| :--- | :--- |
| **W, A, S, D** hoặc **Mũi tên** | Cuộn Camera mượt mà khắp bản đồ |
| **Chuột phải (Giữ & Kéo)** | Kéo rê (Pan) camera tự do |
| **Con lăn chuột (Scroll Wheel)** | Phóng to / Thu nhỏ camera (0.5x - 5.0x) |
| **Hover Chuột** | Thanh tra ô tile: Hiển thị thời gian thực tọa độ, loại bề mặt, tốc độ và cờ |
| **Bật / Tắt Checkbox trên UI** | Ẩn hiện độc lập các lớp: `Ground`, `Roads`, `Decorations`, `Entities` |
| **Nút "🎯 Đặt lại Camera"** | Đưa góc nhìn về trung tâm ngã tư thành phố |
| **Nút "🔄 Vẽ lại bản đồ mẫu"** | Xóa và tạo mới lại toàn bộ lớp bản đồ |

### Kiểm tra tự động bằng lệnh CLI:
```bash
# Kiểm tra tự động toàn bộ 8 tiêu chí kiểm định Tileset & Terrain
& 'D:\Godot_v4.7.2-stable_win64.exe' --headless -s tools/verify_tileset_terrain.gd

# Chạy trực tiếp scene kiểm thử bản đồ
& 'D:\Godot_v4.7.2-stable_win64.exe' scenes/test/map_test_scene.tscn
```

---

## 📁 Cấu Trúc Thư Mục Dự Án

```text
new-city/
├── assets/
│   ├── fonts/
│   │   └── LiberationSans.ttf     # Font chữ mặc định hệ thống
│   ├── spritesheets/
│   │   ├── characters/            # Chứa 44 file ảnh NPC .png
│   │   ├── vehicles/              # Chứa 24 file ảnh phương tiện .png
│   │   └── buildings/
│   │       └── Building Door Animations/ # Chứa 41 file ảnh tòa nhà hoạt ảnh cửa
│   └── tilesets/
│       └── GroundTiles.png        # Spritesheet bản đồ 976x880 (16x16 tiles)
├── data/
│   ├── npcs/                      # 44 file tài nguyên NPCData (.tres)
│   ├── vehicles/                  # 25 file tài nguyên VehicleData (.tres)
│   ├── buildings/                 # 45 file tài nguyên BuildingData (.tres)
│   ├── tilesets/
│   │   └── city_tileset.tres      # Tài nguyên TileSet hoàn chỉnh (9 Terrains, 7 Custom Data Layers)
│   └── asset_registry.json        # Manifest JSON tổng hợp NPC, Xe & Tòa Nhà
├── scenes/
│   ├── characters/
│   │   ├── NPCBase.tscn           # Scene gốc của NPC
│   │   └── npc_base.gd            # Script bộ điều khiển NPCBase
│   ├── vehicles/
│   │   ├── VehicleBase.tscn       # Scene gốc của Xe
│   │   └── vehicle_base.gd        # Script bộ điều khiển VehicleBase
│   ├── buildings/
│   │   ├── BuildingBase.tscn      # Scene gốc của Tòa Nhà
│   │   └── building_base.gd       # Script bộ điều khiển BuildingBase
│   └── test/
│       ├── npc_test_scene.tscn    # Scene kiểm thử 44 NPC
│       ├── npc_test_scene.gd      # Bộ điều khiển Test Scene NPC
│       ├── vehicle_test_scene.tscn# Scene kiểm thử 25 Phương Tiện
│       ├── vehicle_test_scene.gd  # Bộ điều khiển Test Scene Xe & Siren
│       ├── building_test_scene.tscn# Scene kiểm thử 45 Tòa Nhà
│       ├── building_test_scene.gd # Bộ điều khiển Test Scene Tòa Nhà & Cửa
│       ├── map_test_scene.tscn    # Scene kiểm thử Bản Đồ TileMapLayer & Terrains
│       └── map_test_scene.gd      # Bộ điều khiển Test Scene Bản Đồ & Tile Inspector
├── scripts/
│   ├── npcs/
│   │   ├── NPCData.gd             # Model dữ liệu NPCData
│   │   ├── npc_registry.gd        # Autoload Singleton NPCRegistry
│   │   └── ...                    # Các lớp con NPC
│   ├── vehicles/
│   │   ├── VehicleData.gd         # Model dữ liệu VehicleData
│   │   ├── vehicle_registry.gd    # Autoload Singleton VehicleRegistry
│   │   └── ...                    # Các lớp con Phương tiện
│   ├── buildings/
│   │   ├── BuildingData.gd        # Model dữ liệu BuildingData (Hỗ trợ 2 cửa & đa màu)
│   │   ├── building_registry.gd   # Autoload Singleton BuildingRegistry
│   │   └── ...                    # Các lớp con Tòa Nhà
│   └── world/
│       └── city_map_manager.gd    # Bộ quản lý bản đồ CityMapManager API
├── tools/
│   ├── add_npc.py                 # Tool thêm & sync NPC tự động
│   ├── add_vehicle.py             # Tool thêm & sync Phương tiện tự động
│   ├── add_building.py            # Tool thêm & sync Tòa nhà tự động
│   ├── generate_city_tileset.gd   # Bộ sinh tài nguyên TileSet tự động
│   ├── build_map_test_scene.gd    # Bộ sinh Scene kiểm thử bản đồ
│   ├── verify_tileset_terrain.gd  # Bộ kiểm tra tự động hệ thống Tileset & Terrains
│   ├── test_npc_system.gd         # Bộ kiểm tra tự động hệ thống NPC
│   ├── verify_vehicles.gd         # Bộ kiểm tra tự động hệ thống Phương Tiện
│   └── verify_buildings.gd        # Bộ kiểm tra tự động hệ thống Tòa Nhà
├── project.godot                  # Cấu hình Godot 4 (Autoload 3 Registries & Custom Font)
└── README.md                      # Tài liệu hướng dẫn toàn diện
```
