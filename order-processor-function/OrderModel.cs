public class OrderModel
{
    public string CustomerName { get; set; }
    public string Email { get; set; }
    public string OrderDate { get; set; }
    public double OrderAmount { get; set; }
    public OrderItemModel[] Items { get; set; }
}