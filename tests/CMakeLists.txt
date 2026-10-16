find_package(Qt6 6.4 REQUIRED COMPONENTS Core Test)

add_executable(test_gpuinfo
  test_gpuinfo.cpp
  ${CMAKE_SOURCE_DIR}/src/gpuinfo.cpp
)
target_include_directories(test_gpuinfo PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(test_gpuinfo PRIVATE Qt6::Core Qt6::Test)
if(WIN32)
  target_link_libraries(test_gpuinfo PRIVATE dxgi dxguid)
endif()
add_test(NAME gpuinfo COMMAND test_gpuinfo)

add_executable(test_mix_transition_order
  test_mix_transition_order.cpp
  ${CMAKE_SOURCE_DIR}/src/models/mixtransitionorder.cpp
)
target_include_directories(test_mix_transition_order PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(test_mix_transition_order PRIVATE Qt6::Core Qt6::Test PkgConfig::mlt++)
add_test(NAME mix_transition_order COMMAND test_mix_transition_order)

add_executable(test_split_waveform_cache test_split_waveform_cache.cpp)
target_include_directories(test_split_waveform_cache PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(test_split_waveform_cache PRIVATE Qt6::Core Qt6::Test PkgConfig::mlt++)
add_test(NAME split_waveform_cache COMMAND test_split_waveform_cache)

add_executable(test_cutit_fonts test_cutit_fonts.cpp
  ${CMAKE_SOURCE_DIR}/src/qmltypes/cutitfonts.cpp
  ${CMAKE_SOURCE_DIR}/src/qmltypes/cutitfonts.h)
target_include_directories(test_cutit_fonts PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_compile_definitions(test_cutit_fonts PRIVATE CUTIT_TEST_FONTS="${CMAKE_SOURCE_DIR}/fonts")
target_link_libraries(test_cutit_fonts PRIVATE Qt6::Gui Qt6::Network Qt6::Test)
if(WIN32)
  target_link_libraries(test_cutit_fonts PRIVATE gdi32)
endif()
add_test(NAME cutit_fonts COMMAND test_cutit_fonts)

add_executable(test_background_preview_work test_background_preview_work.cpp)
target_include_directories(test_background_preview_work PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(test_background_preview_work PRIVATE Qt6::Core Qt6::Test)
add_test(NAME background_preview_work COMMAND test_background_preview_work)
