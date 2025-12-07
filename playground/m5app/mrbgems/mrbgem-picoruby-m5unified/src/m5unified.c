#if defined(PICORB_VM_MRUBY)

// mruby implementation (future support)

#elif defined(PICORB_VM_MRUBYC)

#include <mrubyc.h>

// Forward declarations of C++ wrapper functions
extern void m5unified_begin(void);
extern void m5unified_update(void);
extern int m5unified_btnA_wasPressed(void);
extern int m5unified_btnA_isPressed(void);
extern int m5unified_btnB_wasPressed(void);
extern int m5unified_btnB_isPressed(void);
extern int m5unified_btnC_wasPressed(void);
extern int m5unified_btnC_isPressed(void);
extern void m5unified_display_print(const char* text);
extern void m5unified_display_println(const char* text);
extern void m5unified_display_clear(void);

static mrbc_class *c_M5;
static mrbc_class *c_M5_BtnA;
static mrbc_class *c_M5_BtnB;
static mrbc_class *c_M5_BtnC;
static mrbc_class *c_M5_Display;

/**
 * M5.begin()
 * Initialize M5Stack device
 */
static void
mrbc_m5_begin(mrbc_vm *vm, mrbc_value *v, int argc)
{
  m5unified_begin();
  SET_RETURN(mrbc_nil_value());
}

/**
 * M5.update()
 * Update M5Stack state
 */
static void
mrbc_m5_update(mrbc_vm *vm, mrbc_value *v, int argc)
{
  m5unified_update();
  SET_RETURN(mrbc_nil_value());
}

/**
 * M5.BtnA.wasPressed?
 */
static void
mrbc_m5_btnA_wasPressed(mrbc_vm *vm, mrbc_value *v, int argc)
{
  int result = m5unified_btnA_wasPressed();
  SET_RETURN(mrbc_bool_value(result));
}

/**
 * M5.BtnA.isPressed?
 */
static void
mrbc_m5_btnA_isPressed(mrbc_vm *vm, mrbc_value *v, int argc)
{
  int result = m5unified_btnA_isPressed();
  SET_RETURN(mrbc_bool_value(result));
}

/**
 * M5.BtnB.wasPressed?
 */
static void
mrbc_m5_btnB_wasPressed(mrbc_vm *vm, mrbc_value *v, int argc)
{
  int result = m5unified_btnB_wasPressed();
  SET_RETURN(mrbc_bool_value(result));
}

/**
 * M5.BtnB.isPressed?
 */
static void
mrbc_m5_btnB_isPressed(mrbc_vm *vm, mrbc_value *v, int argc)
{
  int result = m5unified_btnB_isPressed();
  SET_RETURN(mrbc_bool_value(result));
}

/**
 * M5.BtnC.wasPressed?
 */
static void
mrbc_m5_btnC_wasPressed(mrbc_vm *vm, mrbc_value *v, int argc)
{
  int result = m5unified_btnC_wasPressed();
  SET_RETURN(mrbc_bool_value(result));
}

/**
 * M5.BtnC.isPressed?
 */
static void
mrbc_m5_btnC_isPressed(mrbc_vm *vm, mrbc_value *v, int argc)
{
  int result = m5unified_btnC_isPressed();
  SET_RETURN(mrbc_bool_value(result));
}

/**
 * M5.Display.print(text)
 */
static void
mrbc_m5_display_print(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc >= 1 && v[1].tt == MRBC_TT_STRING) {
    const char* text = mrbc_string_cstr(&v[1]);
    m5unified_display_print(text);
  }
  SET_RETURN(mrbc_nil_value());
}

/**
 * M5.Display.println(text)
 */
static void
mrbc_m5_display_println(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc >= 1 && v[1].tt == MRBC_TT_STRING) {
    const char* text = mrbc_string_cstr(&v[1]);
    m5unified_display_println(text);
  }
  SET_RETURN(mrbc_nil_value());
}

/**
 * M5.Display.clear()
 */
static void
mrbc_m5_display_clear(mrbc_vm *vm, mrbc_value *v, int argc)
{
  m5unified_display_clear();
  SET_RETURN(mrbc_nil_value());
}

/**
 * M5Unified gem initialization
 * Called automatically when gem is loaded
 */
void
mrbc_mrbgem_picoruby_m5unified_gem_init(mrbc_vm *vm)
{
  // Define M5 class
  c_M5 = mrbc_define_class(vm, "M5", mrbc_class_object);
  mrbc_define_method(vm, c_M5, "begin", mrbc_m5_begin);
  mrbc_define_method(vm, c_M5, "update", mrbc_m5_update);

  // Define M5.BtnA class
  c_M5_BtnA = mrbc_define_class(vm, "BtnA", mrbc_class_object);
  mrbc_define_method(vm, c_M5_BtnA, "wasPressed?", mrbc_m5_btnA_wasPressed);
  mrbc_define_method(vm, c_M5_BtnA, "isPressed?", mrbc_m5_btnA_isPressed);

  // Define M5.BtnB class
  c_M5_BtnB = mrbc_define_class(vm, "BtnB", mrbc_class_object);
  mrbc_define_method(vm, c_M5_BtnB, "wasPressed?", mrbc_m5_btnB_wasPressed);
  mrbc_define_method(vm, c_M5_BtnB, "isPressed?", mrbc_m5_btnB_isPressed);

  // Define M5.BtnC class
  c_M5_BtnC = mrbc_define_class(vm, "BtnC", mrbc_class_object);
  mrbc_define_method(vm, c_M5_BtnC, "wasPressed?", mrbc_m5_btnC_wasPressed);
  mrbc_define_method(vm, c_M5_BtnC, "isPressed?", mrbc_m5_btnC_isPressed);

  // Define M5.Display class
  c_M5_Display = mrbc_define_class(vm, "Display", mrbc_class_object);
  mrbc_define_method(vm, c_M5_Display, "print", mrbc_m5_display_print);
  mrbc_define_method(vm, c_M5_Display, "println", mrbc_m5_display_println);
  mrbc_define_method(vm, c_M5_Display, "clear", mrbc_m5_display_clear);
}

#endif
