import azure.functions as func
import datetime
import json
import logging
from helpers import validate_order

app = func.FunctionApp()

@app.function_name(name="CreateOrderTrigger")
@app.route(route="order", methods=["POST"], auth_level=func.AuthLevel.ANONYMOUS)
def CreateOrderTrigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing of the Order has started.")

    try:
        order = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid request body", status_code=400)

    is_valid, message = validate_order(order)

    if not is_valid:
        return func.HttpResponse(json.dumps({"error": message}), status_code=400, mimetype="application/json")

    return func.HttpResponse(json.dumps({"message": "Order received successfully"}), status_code=200, mimetype="application/json")