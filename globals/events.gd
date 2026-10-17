extends Node

@warning_ignore_start('unused_signal')
signal ingredient_added(ingredient)
signal cauldron_emptied()
signal potion_served(result: Dictionary)
signal customer_arrived(customer)
signal customer_left(customer, served: bool)
signal customer_paid(amount: int, quality: Cons.QUALITY)
signal money_changed(amount: int)
signal debuff_started(type, duration)
signal debuff_ended(type)
signal book_updated(potion_id)
signal game_over()
