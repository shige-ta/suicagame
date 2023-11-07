extends Control

var ad_view : AdView
var ad_listener := AdListener.new()
var adPosition := AdPosition.Values.TOP

var rewarded_ad : RewardedAd
var on_user_earned_reward_listener := OnUserEarnedRewardListener.new()
var rewarded_ad_load_callback := RewardedAdLoadCallback.new()
var full_screen_content_callback := FullScreenContentCallback.new()

func popup_show() -> void:
	# ポップアップを表示する
	self.visible = true
	# ゲームを一時停止する
	get_tree().paused = true
	# Labelノードのテキストを設定する
	$Label.text = "test"


# Called when the node enters the scene tree for the first time.
func _ready():
	ad_listener.on_ad_failed_to_load = _on_ad_failed_to_load
	ad_listener.on_ad_clicked = _on_ad_clicked
	ad_listener.on_ad_closed = _on_ad_closed
	ad_listener.on_ad_impression = _on_ad_impression
	ad_listener.on_ad_loaded = _on_ad_loaded
	ad_listener.on_ad_opened = _on_ad_opened
	_on_load_banner_pressed()

	on_user_earned_reward_listener.on_user_earned_reward = on_user_earned_reward
	
	rewarded_ad_load_callback.on_ad_failed_to_load = on_rewarded_ad_failed_to_load
	rewarded_ad_load_callback.on_ad_loaded = on_rewarded_ad_loaded

	full_screen_content_callback.on_ad_clicked = func() -> void:
		print("on_ad_clicked")
	full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		print("on_ad_dismissed_full_screen_content")
		destroy()
		
	full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(ad_error : AdError) -> void:
		print("on_ad_failed_to_show_full_screen_content")
	full_screen_content_callback.on_ad_impression = func() -> void:
		print("on_ad_impression")
	full_screen_content_callback.on_ad_showed_full_screen_content = func() -> void:
		print("on_ad_showed_full_screen_content")
	if not $Button.button_down.is_connected(_on_button_button_down):
		$Button.button_down.connect(_on_button_button_down)
		$Button.disabled = true
	_on_load_interstitial_pressed()
	$Window.hide()
	$HTTPRequest.request("https://1.1.1.1")
	$HTTPRequest.connect("request_completed", Callable(self, "_on_request_completed"))

func _on_load_interstitial_pressed() -> void:
	var unit_id : String
	if OS.get_name() == "Android":
		unit_id = "ca-app-pub-3940256099942544/5224354917"
	elif OS.get_name() == "iOS":
		unit_id = "ca-app-pub-3940256099942544/1712485313"
	else:
		$Button.disabled = false
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), rewarded_ad_load_callback)
func on_rewarded_ad_failed_to_load(adError : LoadAdError) -> void:
	print(adError.message)
	
func on_rewarded_ad_loaded(rewarded_ad : RewardedAd) -> void:
	print("rewarded ad loaded" + str(rewarded_ad._uid))
	rewarded_ad.full_screen_content_callback = full_screen_content_callback

	var server_side_verification_options := ServerSideVerificationOptions.new()
	server_side_verification_options.custom_data = "TEST PURPOSE"
	server_side_verification_options.user_id = "user_id_test"
	rewarded_ad.set_server_side_verification_options(server_side_verification_options)

	self.rewarded_ad = rewarded_ad
	_on_show_pressed()

func _on_show_pressed():
	if rewarded_ad:
		rewarded_ad.show(on_user_earned_reward_listener)

func on_user_earned_reward(rewarded_item : RewardedItem):
	print("on_user_earned_reward, rewarded_item: rewarded", rewarded_item.amount, rewarded_item.type)
	$Button.disabled = false

func _on_video_completed():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):
# 	pass
func _on_destroy_pressed():
	destroy()

func destroy():
	if rewarded_ad:
		rewarded_ad.destroy()
		rewarded_ad = null #need to load again

func _on_button_button_down():
	get_tree().change_scene_to_file("res://Main.tscn")
	ad_view.hide()

func show_popup():
	$Window.title = "Network Error"
	$Window.size = Vector2(500, 400)
	$Window.position = Vector2(100, 100)
	# WindowDialogにLabelノードを追加する
	var label = Label.new()
	label.text = """No network connection. 
	Please connect to the network and restart the app.
	
	
	ネットが接続していないので
	接続してアプリを再起動してください
	"""
	$Window.add_child(label)
	# ポップアップを表示する
	$Window.popup()
	
func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		# ポップアップを表示する
		show_popup()
		#$Button.disabled = false
		# リクエストが成功した場合、ボタンを有効化する
		# $Button.disabled = false
		# TODO ポップアップでネットに接続してゲームを再起動してください。

var time_since_last_ad = 0.0


func _process(delta):
	
	time_since_last_ad += delta
	
	if time_since_last_ad >= 5.0:
		$Button.disabled = true
		_on_load_interstitial_pressed()
		time_since_last_ad = 0.0

	
	
func _on_load_banner_pressed() -> void:
	if ad_view:
		ad_view.destroy() #always try to destroy the ad_view if won't use anymore to clear memory

	var adSizecurrent_orientation := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	print("adSizecurrent_orientation: ", adSizecurrent_orientation.width, ", ", adSizecurrent_orientation.height)
	var adSizeportrait := AdSize.get_portrait_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	print("adSizeportrait: ", adSizeportrait.width, ", ", adSizeportrait.height)
	var adSizelandscape := AdSize.get_landscape_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	print("adSizelandscape: ", adSizelandscape.width, ", ", adSizelandscape.height)
	var adSizesmart := AdSize.get_smart_banner_ad_size()
	print("adSizesmart: ", adSizesmart.width, ", ",adSizesmart.height)
	ad_view = AdView.new("ca-app-pub-3940256099942544/2934735716", adSizecurrent_orientation, adPosition)
	ad_view.ad_listener = ad_listener
	var ad_request := AdRequest.new()
	var vungle_mediation_extras := VungleInterstitialMediationExtras.new()
	vungle_mediation_extras.all_placements = ["placement1", "placement2"]
	vungle_mediation_extras.sound_enabled = true
	vungle_mediation_extras.user_id = "testuserid"
	
	var ad_colony_mediation_extras := AdColonyMediationExtras.new()
	ad_colony_mediation_extras.show_post_popup = false
	ad_colony_mediation_extras.show_pre_popup = true
	ad_request.mediation_extras.append(vungle_mediation_extras)
	ad_request.mediation_extras.append(ad_colony_mediation_extras)
	ad_request.keywords.append("21313")
	ad_request.extras["ID"] = "value"

	ad_view.load_ad(ad_request)

func _on_destroy_banner_pressed() -> void:
	if ad_view:
		ad_view.destroy()
		ad_view = null

func _on_show_banner_pressed() -> void:
	if ad_view:
		ad_view.show()

func _on_hide_banner_pressed() -> void:
	if ad_view:
		ad_view.hide()

func _on_get_width_pressed() -> void:
	if ad_view:
		print(ad_view.get_width(), ", ", ad_view.get_height(), ", ", ad_view.get_width_in_pixels(), ", ", ad_view.get_height_in_pixels())

func _on_ad_failed_to_load(load_ad_error : LoadAdError) -> void:
	print("_on_ad_failed_to_load: " + load_ad_error.message)
	
func _on_ad_clicked() -> void:
	print("_on_ad_clicked")
	
func _on_ad_closed() -> void:
	print("_on_ad_closed")
	
func _on_ad_impression() -> void:
	print("_on_ad_impression")
	
func _on_ad_loaded() -> void:
	print("_on_ad_loaded")
	
func _on_ad_opened() -> void:
	print("_on_ad_opened")


func _on_top_pressed():
	adPosition = AdPosition.Values.TOP


func _on_bottom_pressed():
	adPosition = AdPosition.Values.BOTTOM


func _on_left_pressed():
	adPosition = AdPosition.Values.LEFT


func _on_right_pressed():
	adPosition = AdPosition.Values.RIGHT


func _on_top_left_pressed():
	adPosition = AdPosition.Values.TOP_LEFT


func _on_top_right_pressed():
	adPosition = AdPosition.Values.TOP_RIGHT


func _on_bottom_left_pressed():
	adPosition = AdPosition.Values.BOTTOM_LEFT


func _on_bottom_right_pressed():
	adPosition = AdPosition.Values.BOTTOM_RIGHT


func _on_center_pressed():
	adPosition = AdPosition.Values.CENTER
