#include <catch2/catch_test_macros.hpp>

// Checks that Catch2 is built and discovered by CTest.
TEST_CASE("Test framework runs", "[smoke]") { CHECK(2 + 2 == 4); }
