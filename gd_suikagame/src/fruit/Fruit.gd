extends RigidBody2D
# ===============================================
# フルーツオブジェクト.
# ===============================================
class_name Fruit

# -----------------------------------------------
# const.
# -----------------------------------------------
const TIMER_HIT = 0.5 # ヒット時の点滅時間.
const TIMER_SCALE = 0.3 # 出現時のスケール.
# ライン超えのリミット.
# (_progress()で減算されるので実質3秒)
const TIMER_GAMEOVER = 3.0 * 2

## フルーツの種類.
## このIDの並び＝進化テーブル
enum eFruit {
	c1,
	c2,
	c3,
	c4,
	small_hiyoko,
	hiyoko,
}

## 名前テーブル.
const NAMES = {
	eFruit.c1: "c1",
	eFruit.c2: "c2",
	eFruit.c3: "c3",
	eFruit.c4: "c4",
	eFruit.small_hiyoko: "s_hiyoko",
	eFruit.hiyoko: "hiyoko",
}

## テクスチャテーブル.
const TEXTURES = {
	eFruit.c1: "res://assets/images/fruits/c1.png",
	eFruit.c2: "res://assets/images/fruits/c2.png",
	eFruit.c3: "res://assets/images/fruits/c3.png",
	eFruit.c4: "res://assets/images/fruits/c4.png",
	eFruit.small_hiyoko: "res://assets/images/fruits/small_hiyoko.png",
	eFruit.hiyoko: "res://assets/images/fruits/hiyoko.png",
}


const FRUIT_ORDER = [
	eFruit.c1, eFruit.c2, eFruit.c3, eFruit.c4, eFruit.small_hiyoko,eFruit.hiyoko
]

# -----------------------------------------------
# export.
# -----------------------------------------------
## フルーツID.
@export var id:eFruit

# -----------------------------------------------
# onready.
# -----------------------------------------------
@onready var _spr = $Sprite

# -----------------------------------------------
# var.
# -----------------------------------------------
var _base_scale:Vector2
var _gameover_timer = 0.0 # ゲームオーバータイマー.
var _hit_count = 0 # 他のオブジェクトと衝突した回数.
var _scale_timer = 0.0 # 拡大縮小タイマー.

# -----------------------------------------------
# static functions.
# -----------------------------------------------
## フルーツの名前を取得.
static func get_fruit_name(id:eFruit) -> String:
	return NAMES[id]

## フルーツの画像を取得.
static func get_fruit_tex(id:eFruit) -> Texture:
	return load(TEXTURES[id])

# -----------------------------------------------
# public functions.
# -----------------------------------------------
## スプライトのスケール値を取得する.
func get_sprite_scale() -> Vector2:
	return _spr.scale

## 一度でもヒットしたかどうか.
func is_hit_even_once() -> bool:
	return _hit_count > 0

## 出現時のスケール開始.
func start_scale() -> void:
	_scale_timer = TIMER_SCALE

## ゲームオーバーのラインを超えているかどうか.
func check_gameover(y:float, delta:float) -> bool:
	if is_hit_even_once() == false:
		return false # ヒットしていなければ対象外.
		
	if position.y < y:
		# ライン超えしている
		# 猶予時間.
		_gameover_timer += (delta * 2)
		if _gameover_timer > TIMER_GAMEOVER:
			# ライン超え.
			return true
	
	# セーフ.
	return false

## ライン超え時間の割合 (0.0〜1.0)
func get_gameover_timer_rate() -> float:
	return _gameover_timer / (TIMER_GAMEOVER)

# -----------------------------------------------
# private functions.
# -----------------------------------------------
## 開始.
func _ready() -> void:
	# 基準のスケール値を保存.
	_base_scale = get_sprite_scale()

## 更新.
func _physics_process(delta: float) -> void:
	
	# 拡大縮小演出.
	_spr.scale = _base_scale
	if _scale_timer > 0:
		_scale_timer -= delta
		var rate = _scale_timer / TIMER_SCALE
		rate = 1 + 0.1 * Ease.back_out(1 - rate)
		_spr.scale *= Vector2(rate, rate)
	
	# ゲームオーバー赤点滅演出.
	_spr.modulate = Color.WHITE
	if _gameover_timer > 0:
		var rate = 1 - (_gameover_timer / TIMER_HIT)
		_gameover_timer -= delta
		var color = Color.RED
		_spr.modulate = color.lerp(Color.WHITE, rate)
		
# -----------------------------------------------
# signal.
# -----------------------------------------------

## 他の剛体と衝突した.
func _on_body_entered(body: Node) -> void:
	# ヒット回数をカウント.
	_hit_count += 1
	
	if not body is Fruit:
		return # フルーツでない
	if self.is_queued_for_deletion():
		return # すでに破棄要求されている.
	if body.is_queued_for_deletion():
		return # すでに破棄要求されている.

	# フルーツとヒットした場合の処理
	var other = body as Fruit

	# 両方のフルーツのIDが一致しない場合、何もしない
	if self.id != other.id:
		return

	var currentIndex = FRUIT_ORDER.find(self.id)
	if currentIndex == -1 or currentIndex == FRUIT_ORDER.size() - 1:
		return # 現在のフルーツがリストにない、または最後のフルーツの場合、何もしない

	var nextFruitID = FRUIT_ORDER[currentIndex + 1]
	var pos = (position + other.position) / 2
	var is_deferred = true
	var fruit = Common.create_fruit(nextFruitID, is_deferred, pos)
	fruit.position = pos
	fruit.start_scale()

	# お互いに消滅する
	queue_free()
	other.queue_free()
		
	# # フルーツとヒットした.
	# var other = body as Fruit
	# if id != other.id:
	# 	return # 一致していないので何も起こらない.
	
	# # IDが一致していたら合成可能.
	# if id < eFruit.small_hiyoko:
	# 	# とりあえず中間地点にフルーツを生成する.
	# 	var pos = (position + other.position)/2
	# 	# このシグナル内で生成する場合は
	# 	# 遅延処理をしなければならない.
	# 	var is_deferred = true
	# 	# 進化するのでid+1
	# 	var fruit = Common.create_fruit(id+1, is_deferred, pos)
	# 	fruit.position = pos
	# 	fruit.start_scale()
	# else:
	# 	# XBox同士は消せない.
	# 	return
	
	# # お互いに消滅する.
	# queue_free()
	# other.queue_free()
