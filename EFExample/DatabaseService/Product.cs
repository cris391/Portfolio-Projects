using System.ComponentModel.DataAnnotations.Schema;

namespace DatabaseService
{
  public class Product
  {
    public int Id { get; set; }
    public string Name { get; set; }
    [Column("productname")]
    public string ProductName { get; set; }
    public double UnitPrice { get; set; }
    public string QuantityPerUnit { get; set; }
    public double UnitsInStock { get; set; }

    public int CategoryId { get; set; }
    public Category Category { get; set; }

  }
}