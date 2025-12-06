#if defined(PICORB_VM_MRUBY)

// mruby implementation (future support)

#elif defined(PICORB_VM_MRUBYC)

#include <mrubyc.h>
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define BUTTON_PIN GPIO_NUM_39
#define DEBOUNCE_MS 50

static int last_state = 1;
static int was_pressed_flag = 0;
static uint32_t last_change_time = 0;

/**
 * Button.init
 * Initialize button GPIO39 for input with pull-up
 */
static void
c_button_init(mrbc_vm *vm, mrbc_value *v, int argc)
{
  gpio_config_t io_conf = {
    .pin_bit_mask = (1ULL << BUTTON_PIN),
    .mode = GPIO_MODE_INPUT,
    .pull_up_en = GPIO_PULLUP_ENABLE,
    .pull_down_en = GPIO_PULLDOWN_DISABLE,
    .intr_type = GPIO_INTR_DISABLE
  };
  gpio_config(&io_conf);

  last_state = gpio_get_level(BUTTON_PIN);
  SET_RETURN(mrbc_nil_value());
}

/**
 * Button.update
 * Update button state (call in loop)
 * Detects falling edge with debouncing
 */
static void
c_button_update(mrbc_vm *vm, mrbc_value *v, int argc)
{
  uint32_t now = xTaskGetTickCount() * portTICK_PERIOD_MS;
  int current = gpio_get_level(BUTTON_PIN);

  // Debounce: ignore changes within 50ms
  if (now - last_change_time > DEBOUNCE_MS) {
    // Detect falling edge (button press on ATOM Matrix)
    if (last_state == 1 && current == 0) {
      was_pressed_flag = 1;
      last_change_time = now;
    }
    last_state = current;
  }

  SET_RETURN(mrbc_nil_value());
}

/**
 * Button.was_pressed?
 * Check if button was pressed (clears flag after reading)
 * Returns true on press, false otherwise
 */
static void
c_button_was_pressed(mrbc_vm *vm, mrbc_value *v, int argc)
{
  int result = was_pressed_flag;
  was_pressed_flag = 0;
  SET_RETURN(mrbc_bool_value(result));
}

/**
 * Button.is_pressed?
 * Check current button state without clearing flag
 * Returns true if pressed, false otherwise
 */
static void
c_button_is_pressed(mrbc_vm *vm, mrbc_value *v, int argc)
{
  int current = gpio_get_level(BUTTON_PIN);
  SET_RETURN(mrbc_bool_value(current == 0));
}

/**
 * Button mrbgem initialization function
 * Automatically called when the mrbgem is loaded.
 * Register class and methods here.
 */
void
mrbc_mrbgem_picoruby_button_gem_init(mrbc_vm *vm)
{
  // Define the Button class
  mrbc_class *c_Button = mrbc_define_class(vm, "Button", mrbc_class_object);

  // Register methods
  mrbc_define_method(vm, c_Button, "init", c_button_init);
  mrbc_define_method(vm, c_Button, "update", c_button_update);
  mrbc_define_method(vm, c_Button, "was_pressed?", c_button_was_pressed);
  mrbc_define_method(vm, c_Button, "is_pressed?", c_button_is_pressed);
}

#endif
