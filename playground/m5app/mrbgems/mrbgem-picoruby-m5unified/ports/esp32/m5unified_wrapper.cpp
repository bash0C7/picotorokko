// M5Unified C++ to C wrapper layer
// Bridges M5Unified C++ API to mrubyc C bindings

#include <M5Unified.h>

extern "C" {

/**
 * M5.begin() - Initialize M5Stack device
 * Configures display, buttons, IMU, and other peripherals
 */
void m5unified_begin(void) {
  auto cfg = M5.config();
  M5.begin(cfg);
}

/**
 * M5.update() - Update M5Stack state
 * Must be called periodically in main loop
 * Refreshes button state, display, and other sensors
 */
void m5unified_update(void) {
  M5.update();
}

/**
 * M5.BtnA.wasPressed() - Check if Button A was pressed
 * Returns true once when button is pressed (clears flag)
 * Call regularly in loop for reliable detection
 */
int m5unified_btnA_wasPressed(void) {
  return M5.BtnA.wasPressed() ? 1 : 0;
}

/**
 * M5.BtnA.isPressed() - Check current Button A state
 * Returns true while button is held down
 * Does not clear any state
 */
int m5unified_btnA_isPressed(void) {
  return M5.BtnA.isPressed() ? 1 : 0;
}

/**
 * M5.BtnB.wasPressed() - Check if Button B was pressed
 */
int m5unified_btnB_wasPressed(void) {
  return M5.BtnB.wasPressed() ? 1 : 0;
}

/**
 * M5.BtnB.isPressed() - Check current Button B state
 */
int m5unified_btnB_isPressed(void) {
  return M5.BtnB.isPressed() ? 1 : 0;
}

/**
 * M5.BtnC.wasPressed() - Check if Button C was pressed
 */
int m5unified_btnC_wasPressed(void) {
  return M5.BtnC.wasPressed() ? 1 : 0;
}

/**
 * M5.BtnC.isPressed() - Check current Button C state
 */
int m5unified_btnC_isPressed(void) {
  return M5.BtnC.isPressed() ? 1 : 0;
}

/**
 * M5.Display.print() - Print text to display
 * Output is concatenated without line breaks
 * Call M5.Display.print("\n") for newline
 */
void m5unified_display_print(const char* text) {
  M5.Display.print(text);
}

/**
 * M5.Display.println() - Print text to display with newline
 */
void m5unified_display_println(const char* text) {
  M5.Display.println(text);
}

/**
 * M5.Display.clear() - Clear display
 */
void m5unified_display_clear(void) {
  M5.Display.clear();
}

} // extern "C"
