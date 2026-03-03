## Shop transaction logic. Pure buy/sell validation with no autoload dependencies.
class_name ShopTransaction
extends RefCounted


signal purchase_completed(item_id: StringName, cost: int)
signal sale_completed(item_id: StringName, price: int)
signal transaction_failed(reason: String)


## Check if player can afford an item.
func can_buy(gold: int, cost: int) -> bool:
	return cost > 0 and gold >= cost


## Execute a purchase. Returns {success: bool, new_gold: int}.
func buy(gold: int, cost: int, item_id: StringName) -> Dictionary:
	if not can_buy(gold, cost):
		transaction_failed.emit("Insufficient gold")
		return {"success": false, "new_gold": gold}
	var new_gold: int = gold - cost
	purchase_completed.emit(item_id, cost)
	return {"success": true, "new_gold": new_gold}


## Calculate sell price from base cost and sell ratio.
func sell_price(base_cost: int, sell_ratio: float) -> int:
	return int(base_cost * sell_ratio)


## Execute a sale. Returns {success: bool, new_gold: int, earned: int}.
func sell(gold: int, base_cost: int, sell_ratio: float, item_id: StringName) -> Dictionary:
	var earned: int = sell_price(base_cost, sell_ratio)
	var new_gold: int = gold + earned
	sale_completed.emit(item_id, earned)
	return {"success": true, "new_gold": new_gold, "earned": earned}
