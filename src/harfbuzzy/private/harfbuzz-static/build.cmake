cmake_minimum_required(VERSION 3.24)

# Hold one lock across configuration, source download, and archive generation.
file(MAKE_DIRECTORY "${HARFBUZZY_BUILD_DIR}")
file(LOCK "${HARFBUZZY_BUILD_DIR}/harfbuzzy-build.lock"
  GUARD PROCESS TIMEOUT 900 RESULT_VARIABLE lock_result)
if(NOT lock_result STREQUAL "0")
  message(FATAL_ERROR "Cannot lock the HarfBuzz build cache: ${lock_result}")
endif()

separate_arguments(extra_args NATIVE_COMMAND "${HARFBUZZY_EXTRA_ARGS}")
if(HARFBUZZY_MSVC_RUNTIME)
  list(APPEND runtime_args "-DCMAKE_MSVC_RUNTIME_LIBRARY=${HARFBUZZY_MSVC_RUNTIME}")
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" -S "${HARFBUZZY_SOURCE_DIR}" -B "${HARFBUZZY_BUILD_DIR}"
    -DCMAKE_BUILD_TYPE=Release "-DHARFBUZZY_BUILD_JOBS=${HARFBUZZY_BUILD_JOBS}"
    "-DHARFBUZZY_NO_FRIBIDI=${HARFBUZZY_NO_FRIBIDI}" ${runtime_args} ${extra_args}
  RESULT_VARIABLE configure_result
)
if(NOT configure_result STREQUAL "0")
  message(FATAL_ERROR "HarfBuzz configuration failed: ${configure_result}")
endif()

set(build_targets harfbuzz harfbuzz-subset)
if(NOT HARFBUZZY_NO_FRIBIDI)
  list(APPEND build_targets fribidi-native)
endif()

execute_process(
  COMMAND "${CMAKE_COMMAND}" --build "${HARFBUZZY_BUILD_DIR}" --config Release
    --target ${build_targets} --parallel "${HARFBUZZY_BUILD_JOBS}"
  RESULT_VARIABLE build_result
)
if(NOT build_result STREQUAL "0")
  message(FATAL_ERROR "HarfBuzz compilation failed: ${build_result}")
endif()
