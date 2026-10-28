cmake_minimum_required(VERSION 3.24)

project(harfbuzzy_harfbuzz LANGUAGES C CXX)

include(FetchContent)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_FRAMEWORK OFF CACHE BOOL "" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(HB_BUILD_UTILS OFF CACHE BOOL "" FORCE)
set(HB_BUILD_SUBSET ON CACHE BOOL "" FORCE)
set(HB_BUILD_RASTER OFF CACHE BOOL "" FORCE)
set(HB_BUILD_VECTOR OFF CACHE BOOL "" FORCE)
set(HB_BUILD_GPU OFF CACHE BOOL "" FORCE)
set(HB_HAVE_CAIRO OFF CACHE BOOL "" FORCE)
set(HB_HAVE_CORETEXT OFF CACHE BOOL "" FORCE)
set(HB_HAVE_DIRECTWRITE OFF CACHE BOOL "" FORCE)
set(HB_HAVE_FREETYPE OFF CACHE BOOL "" FORCE)
set(HB_HAVE_GDI OFF CACHE BOOL "" FORCE)
set(HB_HAVE_GLIB OFF CACHE BOOL "" FORCE)
set(HB_HAVE_GOBJECT OFF CACHE BOOL "" FORCE)
set(HB_HAVE_GRAPHITE2 OFF CACHE BOOL "" FORCE)
set(HB_HAVE_ICU OFF CACHE BOOL "" FORCE)
set(HB_HAVE_INTROSPECTION OFF CACHE BOOL "" FORCE)
set(HB_HAVE_UNISCRIBE OFF CACHE BOOL "" FORCE)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
foreach(config Debug Release RelWithDebInfo MinSizeRel)
  string(TOUPPER "${config}" config_upper)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${config_upper} "${CMAKE_BINARY_DIR}/lib")
endforeach()

FetchContent_Declare(
  harfbuzz
  URL https://github.com/harfbuzz/harfbuzz/releases/download/14.2.0/harfbuzz-14.2.0.tar.xz
  URL_HASH SHA256=94017020f96d025bb66ae91574e4cf334bcad23e8175a8a40565b3721bc2eaff
  DOWNLOAD_EXTRACT_TIMESTAMP FALSE
)

FetchContent_MakeAvailable(harfbuzz)

# Upstream Nim bindings include <harfbuzz/hb.h>, matching an installed tree.
file(GLOB public_headers "${harfbuzz_SOURCE_DIR}/src/hb*.h")
file(COPY ${public_headers} DESTINATION "${CMAKE_BINARY_DIR}/include/harfbuzz")

# The core amalgamation already defines these helpers. Resolve the subset's
# references through its core dependency rather than defining them twice.
get_target_property(subset_sources harfbuzz-subset SOURCES)
list(REMOVE_ITEM subset_sources
  "${harfbuzz_SOURCE_DIR}/src/hb-number.cc"
  "${harfbuzz_SOURCE_DIR}/src/hb-ot-cff1-table.cc"
  "${harfbuzz_SOURCE_DIR}/src/hb-ot-cff2-table.cc"
  "${harfbuzz_SOURCE_DIR}/src/hb-static.cc"
)
set_property(TARGET harfbuzz-subset PROPERTY SOURCES ${subset_sources})

if(NOT HARFBUZZY_NO_FRIBIDI)
# FriBidi's upstream build generates its Unicode tables and public headers.
# Use that build instead of maintaining a second list of C sources here.
find_program(MESON_EXECUTABLE meson REQUIRED)
find_program(NINJA_EXECUTABLE ninja REQUIRED)
include(ExternalProject)
FetchContent_Declare(
  fribidi
  URL https://github.com/fribidi/fribidi/releases/download/v1.0.16/fribidi-1.0.16.tar.xz
  URL_HASH SHA256=1b1cde5b235d40479e91be2f0e88a309e3214c8ab470ec8a2744d82a5a9ea05c
  DOWNLOAD_EXTRACT_TIMESTAMP FALSE
)
FetchContent_MakeAvailable(fribidi)

# Meson must use the same compiler and target flags as HarfBuzz, especially
# when GCC is also on PATH in an MSVC Developer shell.
function(meson_quote output value)
  string(REPLACE "\\" "\\\\" value "${value}")
  string(REPLACE "'" "\\'" value "${value}")
  set(${output} "'${value}'" PARENT_SCOPE)
endfunction()
meson_quote(meson_cc "${CMAKE_C_COMPILER}")
meson_quote(meson_ar "${CMAKE_AR}")
separate_arguments(fribidi_cflags NATIVE_COMMAND "${CMAKE_C_FLAGS}")
if(APPLE)
  if(CMAKE_OSX_SYSROOT)
    list(APPEND fribidi_cflags -isysroot "${CMAKE_OSX_SYSROOT}")
  endif()
  if(CMAKE_OSX_DEPLOYMENT_TARGET)
    list(APPEND fribidi_cflags "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
  endif()
  foreach(arch IN LISTS CMAKE_OSX_ARCHITECTURES)
    list(APPEND fribidi_cflags -arch "${arch}")
  endforeach()
endif()
set(meson_cargs "")
foreach(flag IN LISTS fribidi_cflags)
  meson_quote(quoted_flag "${flag}")
  string(APPEND meson_cargs "${quoted_flag}, ")
endforeach()
# FriBidi links native Unicode-table generators during its build. Compiler
# driver flags such as -fsanitize and -arch must also reach those link steps.
# MSVC invokes link.exe directly, which takes linker flags rather than cl flags.
separate_arguments(fribidi_link_flags NATIVE_COMMAND "${CMAKE_EXE_LINKER_FLAGS}")
if(NOT MSVC)
  list(PREPEND fribidi_link_flags ${fribidi_cflags})
endif()
set(meson_link_args "")
foreach(flag IN LISTS fribidi_link_flags)
  meson_quote(quoted_flag "${flag}")
  string(APPEND meson_link_args "${quoted_flag}, ")
endforeach()
file(WRITE "${CMAKE_BINARY_DIR}/fribidi-native.ini"
  "[binaries]\nc = ${meson_cc}\nar = ${meson_ar}\n"
  "[built-in options]\nc_args = [${meson_cargs}]\n"
  "c_link_args = [${meson_link_args}]\n")

set(fribidi_runtime "")
if(MSVC)
  if(CMAKE_MSVC_RUNTIME_LIBRARY STREQUAL "MultiThreaded")
    set(fribidi_runtime -Db_vscrt=mt)
  elseif(CMAKE_MSVC_RUNTIME_LIBRARY STREQUAL "MultiThreadedDLL")
    set(fribidi_runtime -Db_vscrt=md)
  else()
    message(FATAL_ERROR "Static FriBidi requires a Release MSVC runtime: MultiThreaded or MultiThreadedDLL")
  endif()
endif()
# Meson uses libfoo.a for static archives even with MSVC; the contents are COFF.
set(fribidi_archive libfribidi.a)

ExternalProject_Add(fribidi-native
  SOURCE_DIR "${fribidi_SOURCE_DIR}"
  BINARY_DIR "${CMAKE_BINARY_DIR}/fribidi-build"
  INSTALL_DIR "${CMAKE_BINARY_DIR}/fribidi-install"
  DOWNLOAD_COMMAND ""
  UPDATE_COMMAND ""
  CONFIGURE_COMMAND "${CMAKE_COMMAND}" -E env "NINJA=${NINJA_EXECUTABLE}"
    "${MESON_EXECUTABLE}" setup <BINARY_DIR> <SOURCE_DIR>
    --native-file "${CMAKE_BINARY_DIR}/fribidi-native.ini" --backend=ninja
    --prefix=<INSTALL_DIR> --libdir=lib --buildtype=release --default-library=static
    --wrap-mode=nofallback -Ddocs=false -Dbin=false -Dtests=false
    -Db_staticpic=true ${fribidi_runtime}
  BUILD_COMMAND "${CMAKE_COMMAND}" -E env "NINJA=${NINJA_EXECUTABLE}"
    "${MESON_EXECUTABLE}" compile -C <BINARY_DIR> -j "${HARFBUZZY_BUILD_JOBS}"
  INSTALL_COMMAND "${MESON_EXECUTABLE}" install -C <BINARY_DIR> --no-rebuild
  BUILD_BYPRODUCTS "${CMAKE_BINARY_DIR}/fribidi-install/lib/${fribidi_archive}"
)

endif()
