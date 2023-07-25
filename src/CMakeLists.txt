# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(xphasepro_library VERSION 0.0.1 LANGUAGES C)

LINK_DIRECTORIES("libs/${ANDROID_ABI}")

add_library(xphasepro SHARED IMPORTED GLOBAL)
set_target_properties(xphasepro PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI}/libPanoMaker.so)
target_link_libraries(xphasepro)
#target_compile_definitions(xphasepro PUBLIC DART_SHARED_LIB)
