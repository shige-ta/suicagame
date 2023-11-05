extends Control


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
	$HTTPRequest.request("https://google.com")
	$HTTPRequest.connect("request_completed", Callable(self, "_on_request_completed"))

func _on_load_interstitial_pressed() -> void:
	var unit_id : String
	if OS.get_name() == "Android":
		unit_id = "ca-app-pub-3940256099942544/5224354917"
	elif OS.get_name() == "iOS":
		unit_id = "ca-app-pub-3940256099942544/1712485313"

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
	$Button.disabled = false

func _on_show_pressed():
	if rewarded_ad:
		rewarded_ad.show(on_user_earned_reward_listener)

func on_user_earned_reward(rewarded_item : RewardedItem):
	print("on_user_earned_reward, rewarded_item: rewarded", rewarded_item.amount, rewarded_item.type)

func _on_video_completed():
	$Button.disabled = false
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
		_on_load_interstitial_pressed()
		time_since_last_ad = 0.0
