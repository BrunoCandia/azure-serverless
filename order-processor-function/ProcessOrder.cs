using System;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace order_processor_function;

public class ProcessOrder
{
    private readonly ILogger<ProcessOrder> _logger;

    public ProcessOrder(ILogger<ProcessOrder> logger)
    {
        _logger = logger;
    }

    [Function(nameof(ProcessOrder))]
    public async Task Run(
        [ServiceBusTrigger("notification-queue", Connection = "ServiceBusConnection")]
        ServiceBusReceivedMessage message,
        ServiceBusMessageActions messageActions)
    {
        _logger.LogInformation("Message ID: {id}", message.MessageId);
        _logger.LogInformation("Message Body: {body}", message.Body);
        _logger.LogInformation("Message Content-Type: {contentType}", message.ContentType);

        // Message serialization
        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        };

        var orderInfo = JsonSerializer.Deserialize<OrderModel>(message.Body.ToString(), options);

        if (orderInfo is null)
        {
            _logger.LogError("Failed to deserialize order information from message ID: {id}", message.MessageId);
            await messageActions.DeadLetterMessageAsync(message, null, "DeserializationFailed", "Order payload could not be deserialized");
            return;
        }

        var orderDetailInfo = $"Order Details: \n" +
            $"Customer Name: {orderInfo.CustomerName} \n" +
            $"Email: {orderInfo.Email} \n" +
            $"Order Date: {orderInfo.OrderDate} \n" +
            $"Order Amount: {orderInfo.OrderAmount} \n" +
            $"Items: \n";

        foreach (var item in orderInfo.Items)
        {
            orderDetailInfo += $" - Product ID: {item.ProductId}, Quantity: {item.Quantity}\n";
        }

        // Upload to the blob storage
        var blobContainerName = Environment.GetEnvironmentVariable("BlobContainerName");
        var connectionString = Environment.GetEnvironmentVariable("ReceiptsStorageConnection");

        var blobServiceClient = new BlobServiceClient(connectionString);
        var blobContainerClient = blobServiceClient.GetBlobContainerClient(blobContainerName);
        await blobContainerClient.CreateIfNotExistsAsync();

        var blobName = $"order-{orderInfo.CustomerName}-{DateTime.UtcNow:yyyyMMddHHmmss}.txt";
        var blobClient = blobContainerClient.GetBlobClient(blobName);
        
        using (var stream = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(orderDetailInfo)))
        {
            await blobClient.UploadAsync(stream, overwrite: true);
        }

        // Complete the message
        await messageActions.CompleteMessageAsync(message);
    }
}