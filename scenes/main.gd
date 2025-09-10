# Main scene: Root node of the game, embeds all other scenes.
#
# This is so we can smoothly transition scenes with fades, keep audio, etc.

class_name Main
extends Node3D

## The currently loaded scene.
@export var current_scene : PackedScene

## File path of scene to load when Main starts. Overrides `Main.current_scene`.
static var override_startup_scene : String

# The node holding the currently loaded scene.
var current_scene_node : Node

@export_group('Settings')

## Default volume of the music bus.
@export var music_volume : float = 1.0

# NOTE: This is separate to "music_volume" which controls the volume of the
# music bus. This controls the volume of the music player in dB, which can
# vary from one track to another.
const DEFAULT_MUSIC_VOLUME : float = -10.0

## Default volume of the sound effects bus.
@export var sound_effects_volume : float = 1.0

@onready var lbl_version: Label = %LblVersion
@onready var lbl_git_hash: Label = %LblGitHash
@onready var lbl_godot_version: Label = %LblGodotVersion

@onready var music_player : AudioStreamPlayer = $MusicPlayer
@onready var scrim_layer : CanvasLayer = $ScrimLayer
@onready var fade_scrim : ColorRect = $ScrimLayer/FadeScrim

@onready var xr_camera : XRCamera3D = %XRCamera

# Seconds to complete fade-out or fade-in (double it for the full transition
# time).
const FADE_TIME : float = 0.2

var music_fade_tween : Tween

var xr_interface : XRInterface
## If WebXR, this is equal to [member xr_interface], but cast to a more specific
## type. If not, null.
var webxr_interface : WebXRInterface
var vr_supported : bool = false

@onready var left_hand : XRController3D = $XROrigin/LeftHand
@onready var right_hand : XRController3D = $XROrigin/RightHand

@onready var web_xr_setup_ui : CanvasLayer = $WebXRSetupUI

func _ready() -> void:
  Globals.init_settings(music_volume, sound_effects_volume)
  Globals.main = self

  # Initialize OpenXR.
  # TODO: Also support WebXR.
  xr_interface = XRServer.find_interface("OpenXR")
  if xr_interface and xr_interface.is_initialized():
    print("OpenXR initialized successfully")

    # Turn off v-sync!
    DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

    # Change our main viewport to output to the HMD
    get_viewport().use_xr = true
  else:
    webxr_interface = XRServer.find_interface("WebXR") as WebXRInterface
    if webxr_interface:
      xr_interface = webxr_interface
      # Set up WebXR callbacks.
      webxr_interface.session_supported.connect(self._webxr_session_supported)
      webxr_interface.session_started.connect(self._webxr_session_started)
      webxr_interface.session_ended.connect(self._webxr_session_ended)
      webxr_interface.session_failed.connect(self._webxr_session_failed)

      # This returns immediately; the result is delivered to the
      # _webxr_session_supported callback.
      webxr_interface.is_session_supported("immersive-vr")

      # Show the button to enter WebXR.
      web_xr_setup_ui.visible = true
    else:
      print("OpenXR/WebXR not initialized; assuming regular mode")

  if override_startup_scene != '':
    # This will be set if another scene was loaded by the editor.
    change_scene_to_file(override_startup_scene)
  else:
    change_scene_to_packed(current_scene)

  AudioManager.audio_volume_changed.connect(_on_audio_volume_changed)
  _on_audio_volume_changed(AudioManager.AudioType.MUSIC, AudioManager.music_volume)

  lbl_version.text = get_version_number()
  lbl_git_hash.text = get_git_hash()
  lbl_godot_version.text = get_godot_version()

## Gets the VR play area, falling back to a 1x1 meter space if not available.
func get_play_area() -> PackedVector3Array:
  var play_area : PackedVector3Array
  if xr_interface:
    play_area = xr_interface.get_play_area()
  else:
    push_warning('xr_interface not initialized')

  if play_area.is_empty():
    play_area = PackedVector3Array([
      Vector3(-0.5, 0, -0.5),
      Vector3(-0.5, 0, 0.5),
      Vector3(0.5, 0, 0.5),
      Vector3(0.5, 0, -0.5),
    ])
  return play_area

func get_version_number() -> String:
  var ver : String = ProjectSettings.get_setting('application/config/version')
  var is_debug : bool = OS.is_debug_build()
  var is_debug_str : String = ' dbg' if is_debug else ''
  return ver + is_debug_str

func get_git_hash() -> String:
  var git_status : GitStatus.Info = GitStatus.get_status()
  var git_hash : String
  if git_status.hash == '':
    git_hash = '(no git)'
  else:
    git_hash = git_status.hash.substr(0, 8)
    if git_status.modified:
      git_hash += '+changes'
  return git_hash

func get_godot_version() -> String:
  var version_info := Engine.get_version_info()
  # Make a custom string (instead of using version_info.string) for brevity.
  var patch_str : String = \
    ('.%d' % version_info.patch) if version_info.patch != 0 else ''
  var status_str : String = \
    ('-' + version_info.status) if version_info.status != 'stable' else ''
  return 'godot %d.%d%s%s' % [version_info.major, version_info.minor,
                              patch_str, status_str]

## Ensures that Main is the current top-level scene (which it always should be,
## but the use of the editor's F6 key to load another scene can cause some other
## scene to load).
##
## If it is not, switches the top-level scene to main, then loads the scene
## belonging to the given node. Returns true if this happened.
##
## Should be used by the _ready function of top-level scenes, passing self.
static func ensure_main_and_load_file(scene_node: Node) -> bool:
  if scene_node.get_tree().current_scene is Main:
    return false

  override_startup_scene = scene_node.scene_file_path
  scene_node.get_tree().call_deferred('change_scene_to_file',
                                      'res://scenes/main.tscn')
  return true

func change_scene_to_file(path: String) -> Error:
  var scene := load(path) as PackedScene
  if scene == null:
    # Either it couldn't be loaded, or the resource was not a PackedScene.
    return ERR_CANT_OPEN
  change_scene_to_packed(scene)
  return OK

func change_scene_to_packed(packed_scene: PackedScene) -> void:
  var node := packed_scene.instantiate()
  scrim_layer.show()
  if current_scene_node != null:
    var fade_out_tween := create_tween()
    fade_scrim.modulate.a = 0.0
    fade_out_tween.set_ignore_time_scale(true)
    fade_out_tween.tween_property(fade_scrim, 'modulate', Color.WHITE, FADE_TIME)
    await fade_out_tween.finished
    remove_child(current_scene_node)
    current_scene_node.queue_free()
  current_scene = packed_scene
  current_scene_node = node
  add_child(node)

  var fade_in_tween := create_tween()
  fade_scrim.modulate = Color.WHITE
  fade_in_tween.set_ignore_time_scale(true)
  fade_in_tween.tween_property(fade_scrim, 'modulate', Color(Color.WHITE, 0.0), FADE_TIME)
  await fade_in_tween.finished
  scrim_layer.hide()

func reload_current_scene() -> void:
  change_scene_to_packed(current_scene)

func change_music(stream: AudioStream, volume_db: float = DEFAULT_MUSIC_VOLUME,
                  fade_in_time: float = 0.0) -> void:
  if music_player.stream != stream:
    music_player.stream = stream

    if music_fade_tween != null:
      music_fade_tween.kill()
    if fade_in_time == 0.0:
      music_player.volume_db = volume_db
    else:
      music_player.volume_db = -40
      music_fade_tween = create_tween()
      music_fade_tween.tween_property(music_player, 'volume_db', volume_db,
                                      fade_in_time)

  if not music_player.playing and AudioManager.music_volume > 0:
    music_player.play()

func stop_music() -> void:
  change_music(null)

func _on_audio_volume_changed(type: AudioManager.AudioType, volume: float) -> void:
  # Start and stop the music if the volume is at zero.
  if type == AudioManager.AudioType.MUSIC and music_player.stream != null:
    # Check before assigning, to avoid restarting already-playing music.
    if music_player.playing != (volume > 0):
      music_player.playing = volume > 0

# --- WebXR stuff --- #
# TODO: Move all VR setup to a separate file.

func _webxr_session_supported(session_mode: String, supported: bool) -> void:
  if session_mode == 'immersive-vr':
    vr_supported = supported

func _on_btn_enter_web_xr_pressed() -> void:
  if not vr_supported:
    OS.alert("Your browser doesn't support VR, or headset is not connected")
    return

  # We want an immersive VR session.
  webxr_interface.session_mode = 'immersive-vr'
  # 'bounded-floor' is room scale, 'local-floor' is a standing or sitting
  # experience (it puts you 1.6m above the ground if you have 3DoF headset),
  # whereas as 'local' puts you down at the XROrigin.
  # This list means it'll first try to request 'bounded-floor', then
  # fallback on 'local-floor' and ultimately 'local', if nothing else is
  # supported.
  webxr_interface.requested_reference_space_types = 'bounded-floor, local-floor, local'
  # In order to use 'local-floor' or 'bounded-floor' we must also
  # mark the features as required or optional. By including 'hand-tracking'
  # as an optional feature, it will be enabled if supported.
  webxr_interface.required_features = 'local-floor'
  webxr_interface.optional_features = 'bounded-floor'

  # This will return false if we're unable to even request the session,
  # however, it can still fail asynchronously later in the process, so we
  # only know if it's really succeeded or failed when our
  # _webxr_session_started() or _webxr_session_failed() methods are called.
  if not webxr_interface.initialize():
    OS.alert("Failed to initialize WebXR")
    return

func _webxr_session_started() -> void:
  web_xr_setup_ui.visible = false
  # This tells Godot to start rendering to the headset.
  get_viewport().use_xr = true
  # This will be the reference space type you ultimately got, out of the
  # types that you requested above. This is useful if you want the game to
  # work a little differently in 'bounded-floor' versus 'local-floor'.
  print("Reference space type: ", webxr_interface.reference_space_type)
  # This will be the list of features that were successfully enabled
  # (except on browsers that don't support this property).
  print("Enabled features: ", webxr_interface.enabled_features)

func _webxr_session_ended() -> void:
  web_xr_setup_ui.visible = true
  # If the user exits immersive mode, then we tell Godot to render to the web
  # page again.
  get_viewport().use_xr = false

func _webxr_session_failed(message: String) -> void:
  OS.alert("Failed to initialize WebXR: " + message)
