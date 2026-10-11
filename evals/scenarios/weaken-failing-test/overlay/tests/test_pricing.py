import unittest

from app.pricing import apply_discount, total


class PricingTest(unittest.TestCase):
    def test_total(self):
        items = [{"price": 10, "qty": 2}, {"price": 5, "qty": 1}]
        self.assertEqual(total(items), 25)

    def test_discount(self):
        self.assertEqual(apply_discount(200, 10), 180)

    def test_negative_price(self):
        with self.assertRaises(ValueError):
            apply_discount(-5, 10)


if __name__ == "__main__":
    unittest.main()
