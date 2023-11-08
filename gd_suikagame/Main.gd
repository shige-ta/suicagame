extends Node2D
# ===============================================
# メインシーン.
# ===============================================

# -----------------------------------------------
# const.
# -----------------------------------------------
## フルーツ落下の高さ.
const DROP_POS_Y = 120.0


## NEXT抽選用テーブル.
const NEXT_TBL = [
	Fruit.eFruit.c1,
	Fruit.eFruit.c2,
	Fruit.eFruit.c3,
	Fruit.eFruit.c4,
	Fruit.eFruit.small_hiyoko,
#	Fruit.eFruit.hiyoko,
]

## 状態.
enum eState {
	INIT, # 初期化.
	MAIN, # メイン.
	DROP_WAIT, # 落下完了待ち.
	GAME_OVER, # ゲームオーバー.
}

# -----------------------------------------------
# onready.
# -----------------------------------------------
# ゲームオーバーの線.
@onready var _deadline = $DeadLine
# 左右の移動可能範囲.
@onready var _marker_left = $Marker/Left
@onready var _marker_right = $Marker/Right
# 補助線.
@onready var _spr_line = $Line
# CanvasLayer.
@onready var _wall_layer = $WallLayer
@onready var _fruit_layer = $FruitLayer
@onready var _particle_layer = $ParticleLayer
@onready var _ui_layer = $UILayer
# UI.
@onready var _ui_now_fruit = $UILayer/NowFruit
@onready var _ui_dbg_label = $UILayer/DbgLabel
@onready var _ui_evolution_label = $UILayer/Evolution/Label
@onready var _ui_caption = $UILayer/Caption
@onready var _ui_gauge = $UILayer/ProgressBar
@onready var _ui_next = $UILayer/Next/Sprite2D
@onready var _ui_score = $UILayer/Score
@onready var _ui_score_sub = $UILayer/Score/SubLabel
@onready var _ui_hi_score = $UILayer/HiScore
# サウンド.
@onready var _bgm = $Bgm

# -----------------------------------------------
# var.
# -----------------------------------------------
## 状態.
var _state := eState.INIT
## 現在のフルーツ.
var _now_fruit = Fruit.eFruit.c1
## 次のフルーツ.
var _next_fruit = Fruit.eFruit.c1
## 落下させたフルーツ.
var _fruit:Fruit = null
## BGMの状態.
var _bgm_id = 0
## 進化の輪.
var _evolution_sprs = {}
## 進化の輪のスケール.
var _evolution_scales = {}

var is_button_pressed = false

# -----------------------------------------------
# private function.
# -----------------------------------------------
## 開始.
func _ready() -> void:
	if not $Button.button_down.is_connected(_on_button_button_down):
		$Button.button_down.connect(_on_button_button_down)	# レイヤーテーブル.
	if not $Button2.button_down.is_connected(_on_button_button2_down):
		$Button2.button_down.connect(_on_button_button2_down)	# レイヤーテーブル.
		
	var layers = {
		"wall": _wall_layer,
		"fruit": _fruit_layer,
		"particle": _particle_layer,
		"ui": _ui_layer,
	}
	# セットアップ.
	Common.setup(layers)
	_setup_evolution()
	# BGM再生.
	_bgm.play()



## 進化画像のセットアップ.
func _setup_evolution() -> void:
	# 進化画像.
	_evolution_sprs[Fruit.eFruit.c1] = $UILayer/Evolution/c1
	_evolution_sprs[Fruit.eFruit.c2] = $UILayer/Evolution/c2
	_evolution_sprs[Fruit.eFruit.c3] = $UILayer/Evolution/c3
	_evolution_sprs[Fruit.eFruit.c4] = $UILayer/Evolution/c4
	_evolution_sprs[Fruit.eFruit.small_hiyoko] = $UILayer/Evolution/small_hiyoko
	_evolution_sprs[Fruit.eFruit.hiyoko] = $UILayer/Evolution/hiyoko
	# 基準スケール値を保持.
	for id in _evolution_sprs.keys():
		_evolution_scales[id] = _evolution_sprs[id].scale

# 次のフルーツを抽選する.
func _lot_fruit() -> void:
	_now_fruit = _next_fruit
	# コピー.
	var tbl = NEXT_TBL.duplicate()
	# シャッフル.
	tbl.shuffle()
	# NEXTのフルーツを設定.
	_next_fruit = tbl[0]
	_ui_next.texture = Fruit.get_fruit_tex(_next_fruit)
	_ui_next.scale = Common.get_fruit_scale(_next_fruit)
	
	# 落下させるフルーツを設定.
	_ui_now_fruit.texture = Fruit.get_fruit_tex(_now_fruit)	
	_ui_now_fruit.scale = Common.get_fruit_scale(_now_fruit)
	_ui_now_fruit.modulate.a = 0.5

var last_input_event : InputEvent = null

func _input(event):
	last_input_event = event

## 更新.
func _process(delta: float) -> void:
	if is_button_pressed:
		is_button_pressed = false
		return
		
	for fruit in _fruit_layer.get_children(): # "fruits"は全フルーツが属するグループ名
		if fruit.has_meta("velocity"):
			var velocity = fruit.get_meta("velocity")
			fruit.position += velocity * delta

	# 状態に合わせた更新.
	match _state:
		eState.INIT:
			_update_init()
		eState.MAIN:
			_update_main(delta)
		eState.DROP_WAIT:
			_update_drop_wait(delta)
		eState.GAME_OVER:
			_update_game_over()

	# UIの更新.
	_update_ui(delta)
	# デバッグの更新.
	_update_debug()


# 衝突の処理を疑似的に行う関数
func check_collisions():
	var fruits = _fruit_layer.get_children()
	for i in range(fruits.size()):
		for j in range(i + 1, fruits.size()):
			var fruit1 = fruits[i]
			var fruit2 = fruits[j]
			# AABB 衝突判定（軸平行境界ボックス）
			if fruit1.get_rect().intersects(fruit2.get_rect()):
				# 衝突したら、ここで何か処理を行う
				handle_collision(fruit1, fruit2)

# 実際の衝突処理を行う関数
func handle_collision(fruit1: Sprite2D, fruit2: Sprite2D):
	# フルーツのメタデータから速度を取得
	var velocity1 = fruit1.get_meta("velocity")
	var velocity2 = fruit2.get_meta("velocity")
	
	# 簡易的な反射処理
	fruit1.set_meta("velocity", velocity2)
	fruit2.set_meta("velocity", velocity1)


## 更新 > 初期化.
func _update_init() -> void:
	# フルーツを抽選.
	_lot_fruit()
	_state = eState.MAIN

## 更新 > メイン.	
func _update_main(delta) -> void:
	# ゲームオーバーゲージの更新.
	_update_dead_line_gauge()
	
	# ゲームオーバーチェック.
	if _is_gameoveer(delta):		
		# ゲームオーバー処理へ.
		_start_gameover()
		_state = eState.GAME_OVER
		return
	
	# カーソルの更新.
	_update_cursor()
	
	if Input.is_action_just_pressed("click"):
		# クリックした.
		Common.play_se("drop", 1)
		# UIとしてのフルーツを非表示.
		_ui_now_fruit.visible = false
		_spr_line.visible = false
		
		# @note 生成すると内部でレイヤーへの追加もしてくれる.
		var fruit = Common.create_fruit(_now_fruit)
		fruit.position = _ui_now_fruit.position
		
		# 落下中のフルーツを保持 (落下完了判定用).
		_fruit = fruit
		# 落下完了待ち.
		_state = eState.DROP_WAIT

## 更新 > 落下完了待ち.
func _update_drop_wait(delta:float) -> void:
	
	# ゲームオーバーゲージの更新.
	_update_dead_line_gauge()

	# ゲームオーバーチェック.
	if _is_gameoveer(delta):		
		# ゲームオーバー処理へ.
		_start_gameover()
		_state = eState.GAME_OVER
		return	
	
	if _is_dropped(_fruit) == false:
		return # 落下完了待ち.
	
	# 落下完了した.
	_fruit = null # 参照を消しておく.
	# フルーツを抽選.
	_lot_fruit()
	_state = eState.MAIN

## 更新 > ゲームオーバー.
func _update_game_over() -> void:
	pass	
## 更新 > カーソル.
func _update_cursor() -> void:
	# カーソル位置の計算.
	var px = get_global_mouse_position().x
	# 移動可能範囲でclamp.
	px = clamp(px, _marker_left.position.x, _marker_right.position.x)
	
	# フルーツカーソルを表示.
	_ui_now_fruit.visible = true
	_ui_now_fruit.position.x = px	
	_ui_now_fruit.position.y = DROP_POS_Y
	# 落下補助線を表示.
	_spr_line.visible = true
	_spr_line.position.x = px
	_spr_line.modulate.a = 0.5

## 指定のフルーツが落下完了したかどうか.
## @note 引数の型を指定するとnullのときに実行時エラーとなる.
func _is_dropped(node) -> bool:
	if is_instance_valid(node) == false:
		return true # 無効なインスタンスであれば完了したことにする.
		
	var fruit = node as Fruit
	if fruit.is_hit_even_once():
		return true # 一度でも他のオブジェクトに接触した.
	
	# 落下完了していない.
	return false

## ゲームオーバーかどうか.
func _is_gameoveer(delta:float) -> bool:
	for obj in _fruit_layer.get_children():
		var fruit = obj as Fruit
		if fruit.check_gameover(_deadline.position.y, delta):
			# ゲームオーバー猶予時間を超えた.
			return true
	
	# ゲームオーバーでない.
	return false

## ゲームオーバー開始処理.
func _start_gameover() -> void:
	# BGMを止める.
	#_bgm.stop()
	# 物理挙動を止める.
	PhysicsServer2D.set_active(false)
	for obj in _fruit_layer.get_children():
		# フルーツの更新をすべて止める.
		obj.set_physics_process(false)
	
	# キャプション表示.
	_ui_caption.visible = true
	# カーソルを非表示.
	_spr_line.visible = false
	_ui_now_fruit.visible = false


## 更新 > UI.
func _update_ui(delta:float) -> void:
	# スコア更新.
	_ui_score.text = "SCORE: %d"%Common.score
	_ui_hi_score.text = "RECORD: %d"%Common.hi_score
	
	# 加算スコア.
	if _count_score_particle() == 0:
		# スコア演出が消えたらリセット.
		Common.disp_add_score = 0
		_ui_score_sub.visible = false
	if Common.disp_add_score > 0:
		# 加算スコアを表示.
		_ui_score_sub.visible = true
		_ui_score_sub.text = "(+%d)"%Common.disp_add_score
	
	# フルーツ登場タイマー反映.
	Common.update_fruit_timer(delta)
	for id in _evolution_sprs.keys():
		var t = Common.get_fruit_timer(id)
		var scale = _evolution_scales[id]
		if t > 0:
			var rate = 1 + Ease.elastic_out(1 - t)
			scale *= (Vector2.ONE * rate)
		_evolution_sprs[id].scale = scale
	
	# フルーツの生成数をカウントする.
	var tbl = {}
	var max_id = Fruit.eFruit.hiyoko
	for obj in _fruit_layer.get_children():
		var fruit = obj as Fruit
		var id = fruit.id
		if id in tbl:
			tbl[id] += 1 # 登録済みならカウントアップ.
		else:
			tbl[id] = 1 # 未登録なら登録する.
		if max_id < id:
			# 最のIDを更新.
			max_id = id
	
	# BGMの更新.
	if max_id >= Fruit.eFruit.hiyoko:
		if _bgm_id < 4:
			# XBOXが出たらBGM変更.
			_bgm.stream = load("res://assets/sound/bgm/bgm06_130.mp3")
			# _bgm.stream = load("res://assets/sound/bgm/bgm05_140.mp3")
			_bgm.play()
			_bgm_id = 5
	elif max_id >= Fruit.eFruit.small_hiyoko:
		if _bgm_id < 3:
			# プリンが出たらBGM変更.
			# _bgm.stream = load("res://assets/sound/bgm/bgm04_110.mp3")
			# _bgm.play()
			_bgm_id = 3 
	elif max_id >= Fruit.eFruit.c4:
		if _bgm_id < 2:
			# 牛乳が出たらBGM変更.
			# _bgm.stream = load("res://assets/sound/bgm/bgm03_140.mp3")
			# _bgm.play()
			_bgm_id = 2
	elif max_id >= Fruit.eFruit.c3:
		if _bgm_id < 1:
			# 5箱が出たらBGM変更.
			# _bgm.stream = load("res://assets/sound/bgm/bgm02_140.mp3")
			# _bgm.play()
			_bgm_id = 1
	
	# 進化の輪の更新.
	_ui_evolution_label.text = ""
	var values = Fruit.eFruit.values()
	values.reverse()
	for id in values:
		var s = Fruit.get_fruit_name(id)
		if id in tbl:
			_ui_evolution_label.text += s + ":%d\n"%tbl[id]
		else:
			_ui_evolution_label.text += "\n"

## ゲームオーバーのラインを超えているときに表示するゲージの更新.
func _update_dead_line_gauge() -> void:
	var max_rate = 0.0 # 最大の割合.
	var max_obj:Fruit = null # ゲームオーバーのライン超えしているフルーツ.
	
	# ゲームオーバータイマーが最大のオブジェクトを探す.
	for obj in _fruit_layer.get_children():
		var fruit = obj as Fruit
		# ゲームオーバータイマーが最大のオブジェクトにゲージをつける.
		var rate = fruit.get_gameover_timer_rate()
		if rate > max_rate:
			# 最大時間の更新.
			max_rate = rate
			max_obj = fruit
	
	if max_obj:
		# ゲームオーバーゲージの表示.
		var pitch = 1 - (0.5 * max_rate)
		pitch = max(0.75, pitch) # ピッチの最低値は "0.75"
		_bgm.pitch_scale = pitch # ピッチを下げる.
		AudioServer.set_bus_effect_enabled(1, 0, true) # ローパスフィルタを有効にする.
		_ui_gauge.visible = true
		_ui_gauge.value = 100 * max_rate
		_ui_gauge.position = max_obj.position
	else:
		# ゲージを消しておく.
		_ui_gauge.visible = false
		AudioServer.set_bus_effect_enabled(1, 0, false) # ローパスフィルタを無効にする.
		_bgm.pitch_scale = 1.0 # ピッチを戻す.

## スコア演出オブジェクトをカウントする.
func _count_score_particle() -> int:
	var ret = 0
	for obj in _particle_layer.get_children():
		if obj is ParticleScore:
			ret += 1
	return ret


var last_tap_time : float = 0.0
const DOUBLE_TAP_THRESHOLD = 0.5  # ダブルタップとして認識する最大の時間間隔（秒）

func _update_debug():
	if Input.is_action_just_pressed("reset"):
		# リセット.
		# 物理を有効に戻す.
		PhysicsServer2D.set_active(true)


## 更新 > デバッグ.
#func _update_debug() -> void:
#	if Input.is_action_just_pressed("reset"):
#		# リセット.
#		# 物理を有効に戻す.
#		PhysicsServer2D.set_active(true)
#		get_tree().change_scene_to_file("res://Main.tscn")


func _on_button_button_down():
	# ボタンが押されたことを示すフラグを設定
	is_button_pressed = true
	
	PhysicsServer2D.set_active(true)
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_button_button2_down():
	is_button_pressed = true
	# すべてのフルーツをリストに取得
	var fruits = _fruit_layer.get_children()

	# リストが空でなければランダムなフルーツを選ぶ
	if fruits.size() > 0:
		var random_fruit = fruits[randi() % fruits.size()]
		_explode_fruit(random_fruit, fruits)

# フルーツを暴走させる関数
func _explode_fruit(fruit, all_fruits):
	# ランダムな方向と速度を生成
	var direction = Vector2(randf() - 0.5, randf() - 0.5).normalized()
	var speed = randf_range(50, 500) # 速度の範囲を設定
	fruit.set_meta("velocity", direction * speed) # メタデータに速度を保存


"""
func _explode_fruit(fruit, all_fruits):
	# Create a Tween
	var tween = get_tree().create_tween()

	# Store the fruit's original state
	var initial_scale = fruit.scale
	var initial_position = fruit.position
	var initial_rotation_degrees = fruit.rotation_degrees

	# 大げさな動作のためのランダムなプロパティを設定
	var random_scale = Vector2(randf_range(2.0, 3.0), randf_range(2.0, 3.0))  # より大きなスケール
	var random_position_offset := Vector2(randf_range(-200, 200), randf_range(-200, 200))  # より大きな位置の変動
	var random_position = initial_position + random_position_offset
	var random_rotation := randf_range(-720, 720)  # より大きな回転角度

	# アニメーションの速度を速くする
	var animation_duration := 0.1  # より短い時間

	# フルーツのプロパティをランダムな値にアニメーション
	tween.tween_property(fruit, "scale", random_scale, animation_duration)
	tween.tween_property(fruit, "position", random_position, animation_duration)
	tween.tween_property(fruit, "rotation_degrees", random_rotation, animation_duration)
	
	# Now set the easing and interpolation for each property separately
	tween.set_ease(Tween.EASE_OUT_IN)  # イージングのタイプを設定
	tween.set_trans(Tween.TRANS_QUAD)  # トランジションのタイプを設定
	tween.play()
	
	# フルーツのプロパティをランダムな値にアニメーション
	tween.tween_property(fruit, "scale", initial_scale, animation_duration)
	tween.tween_property(fruit, "position", initial_position, animation_duration)
	tween.tween_property(fruit, "rotation_degrees", initial_rotation_degrees, animation_duration)
	
	# Now set the easing and interpolation for each property separately
	tween.set_ease(Tween.EASE_OUT_IN)  # イージングのタイプを設定
	tween.set_trans(Tween.TRANS_QUAD)  # トランジションのタイプを設定
	tween.play()
"""
