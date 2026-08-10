const { app } = require('@azure/functions');
const { CosmosClient } = require('@azure/cosmos')

const cosmosClient = new CosmosClient(process.env.CosmosDbConnection);
const db = cosmosClient.database(process.env.CosmosDbDatabaseName);
const container = db.container(process.env.CosmosContainerName);

app.eventGrid('OrderTrackerLogger', {
    handler: async (event, context) => {
        context.log('Event grid function processed event:', event);

        if (event.eventType === "Microsoft.Storage.BlobCreated") {
            const blobUrl = event.data.blobUrl;
            const timestamp = event.eventTime;

            const orderRecordDoc = {
                id: `record-${Date.now()}`,
                recordUrl: blobUrl,
                status: "Completed",
                timestamp: timestamp
            }

            try {
                await container.items.create(orderRecordDoc);
                context.log('Record added');
            } catch (error) {
                context.log('Error adding record: ', error);
            }
        } else {
            context.log('Unhandled event type: ', event.eventType)
        }
    }
});
