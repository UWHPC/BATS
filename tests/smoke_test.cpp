#include <catch2/catch_test_macros.hpp>

TEST_CASE("Test framework runs", "[smoke]") {
  CHECK(2 + 2 == 4);
}
