#include <M5Unified.h>

extern "C" {

constructor m5unified_m5timer_M5Timer(void void) {
  return M5.M5Timer.M5Timer(void);
}

void m5unified_m5timer_run(void void) {
  M5.M5Timer.run(void);
}

int_fast8_t m5unified_m5timer_setTimer(uint32_t interval_msec, timer_callback function, uint32_t times) {
  return M5.M5Timer.setTimer(interval_msec, function, times);
}

return m5unified_m5timer_setTimer(interval_msec interval_msec, function function, 0 0) {
  return M5.M5Timer.setTimer(interval_msec, function, 0);
}

void m5unified_timer_info_t_set(uint32_t interval_msec, timer_callback function, uint32_t times) {
  M5.timer_info_t.set(interval_msec, function, times);
}

int m5unified_timer_info_t_run(uint32_t interval_msec) {
  return M5.timer_info_t.run(interval_msec) ? 1 : 0;
}

void m5unified_timer_info_t_clear(void void) {
  M5.timer_info_t.clear(void);
}

} // extern "C"
