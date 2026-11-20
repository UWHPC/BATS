list(APPEND CMAKE_MODULE_PATH "${catch2_SOURCE_DIR}/extras")
include(Catch)

add_executable(bats_tests smoke_test.cpp cuda_smoke_test.cu complex_gemm_test.cpp)
target_link_libraries(bats_tests PRIVATE Catch2::Catch2WithMain xpu::xpu bats::core)
catch_discover_tests(bats_tests)
