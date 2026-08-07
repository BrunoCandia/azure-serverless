def validate_order(order):
    required_fields = ['customerName', 'email', 'items', 'totalAmount', 'orderDate']

    for field in required_fields:
        if field not in order:
            return False, f"Missing required field: {field}"
            # raise ValueError(f"Missing required field: {field}")

    if not isinstance(order['items'], list) or len(order['items']) == 0:
        return False, "Items must be a non-empty list"
        # raise ValueError("Items must be a non-empty list")

    for item in order['items']:
        if "productId" not in item or "quantity" not in item:
            return False, "Each item must have 'productId' and 'quantity' fields"
            # raise ValueError("Each item must have 'productId' and 'quantity' fields")

        if not isinstance(item['quantity'], int) or item['quantity'] <= 0:
            return False, "Item quantity must be a positive integer"
            #raise ValueError("Item quantity must be a positive integer")

    return True, "Order is valid"