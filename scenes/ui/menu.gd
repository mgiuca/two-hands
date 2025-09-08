class_name Menu
extends Control

func _ready() -> void:
  if OS.has_feature('mobile') or OS.has_feature('web'):
    # Doesn't make sense to "quit" on mobile or web.
    # (Especially web, which just crashes.)
    (%BtnQuit as Control).hide()
  set_process_unhandled_input(false)

func _unhandled_input(event: InputEvent) -> void:
  if event.is_action_pressed('ui_cancel'):
    resume.call_deferred()  # Don't know why I have to defer this.
  elif event.is_action_pressed('menu'):
    resume.call_deferred()  # Don't know why I have to defer this.

func show_menu() -> void:
  get_tree().paused = true
  show()
  InputManager.mouse_visible = true
  set_process_unhandled_input(true)
  (%BtnResume as Control).grab_focus()

func resume() -> void:
  hide()
  get_tree().paused = false
  InputManager.mouse_visible = false
  set_process_unhandled_input(false)

func _on_btn_resume_pressed() -> void:
  resume()

func _on_btn_settings_pressed() -> void:
  ($TopLevel as Control).hide()
  set_process_unhandled_input(false)
  (%Settings as Settings).show_dialog()

func _on_settings_closed() -> void:
  ($TopLevel as Control).show()
  set_process_unhandled_input(true)
  (%BtnResume as Control).grab_focus()

func _on_btn_restart_pressed() -> void:
  get_tree().paused = false
  Globals.main.reload_current_scene()

func _on_btn_quit_pressed() -> void:
  get_tree().paused = false
  LevelManager.quit_to_main_menu()
