idf_component_register(
  SRCS
    "ports/esp32/m5unified_wrapper.cpp"
    "src/m5unified.c"
  INCLUDE_DIRS
    "."
  REQUIRES
    m5unified
)

# Link Arduino framework (required by M5Unified)
# Note: Assumes Arduino-ESP32 is installed as ESP-IDF component
target_link_libraries(${COMPONENT_LIB} PUBLIC
  m5unified
)
