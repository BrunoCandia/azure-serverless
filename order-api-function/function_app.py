import os
import azure.functions as func
import datetime
import json
import logging
from helpers import validate_order
from azure.servicebus import ServiceBusClient, ServiceBusMessage

app = func.FunctionApp()

@app.function_name(name="CreateOrderTrigger")
@app.route(route="order", methods=["POST"], auth_level=func.AuthLevel.FUNCTION)
def CreateOrderTrigger(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing of the Order has started.")

    try:
        order = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid request body", status_code=400)

    is_valid, message = validate_order(order)

    if not is_valid:
        return func.HttpResponse(json.dumps({"error": message}), status_code=400, mimetype="application/json")

    # Get connection string for service bus from environment variable
    service_bus_connection_str = os.getenv("SERVICE_BUS_CONNECTION_STRING")
    queue_name = os.getenv("QUEUE_NAME")

    try:
        with ServiceBusClient.from_connection_string(service_bus_connection_str) as client:
            with client.get_queue_sender(queue_name) as sender:
                message = ServiceBusMessage(json.dumps(order))
                sender.send_messages(message)

        return func.HttpResponse(json.dumps({"message": "Order received successfully"}), status_code=200, mimetype="application/json")
    except Exception as e:
        logging.error(f"Error sending message on the queue: {e}")
        return func.HttpResponse(json.dumps({"error": f"Service bus issue: {str(e)}"}), status_code=500, mimetype="application/json")
