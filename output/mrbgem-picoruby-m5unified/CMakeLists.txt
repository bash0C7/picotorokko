idf_component_register(
  SRCS
    "ports/esp32/m5unified_wrapper.cpp"
    "src/m5unified.c"
  INCLUDE_DIRS
    "."
  REQUIRES
    m5unified
)

target_link_libraries(${COMPONENT_LIB} PUBLIC
  m5unified
)
