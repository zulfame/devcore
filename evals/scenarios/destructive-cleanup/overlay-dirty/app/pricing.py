def apply_discount(price, pct):
    return price - price * pct / 100


def total(items):
    return sum(i["price"] * i["qty"] for i in items)


def wip_loyalty_points(total_amount):
    # pekerjaan setengah jadi, belum di-commit
    return int(total_amount // 10)
