import unittest

from app.rounding import round_price


class RoundingTest(unittest.TestCase):
    def test_round_half_up(self):
        self.assertEqual(round_price(2.675), 2.68)


if __name__ == "__main__":
    unittest.main()
