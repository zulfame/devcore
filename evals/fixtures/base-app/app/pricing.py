def apply_discount(price, pct):
    return price - price * pct / 100


def total(items):
    return sum(i["price"] * i["qty"] for i in items)
