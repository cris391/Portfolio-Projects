using System;
using Microsoft.EntityFrameworkCore;
using DatabaseService;
using System.Collections.Generic;
using Microsoft.Extensions.Logging;

namespace DatabaseService
{
  public class NorthwindContext : DbContext
  {

    public static readonly ILoggerFactory MyLoggerFactory
      = LoggerFactory.Create(builder => { builder.AddConsole(); });

    public DbSet<Category> Categories { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderDetails> OrderDetails { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
      optionsBuilder
        .UseLoggerFactory(MyLoggerFactory)
        .UseNpgsql(connectionString: "host=localhost;db=northwind;uid=postgres;pwd=root");
    }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
      modelBuilder.CreateMap("Id", "Name");
      modelBuilder.Entity<OrderDetails>().HasKey(m => new { m.OrderId, m.ProductId });
      // modelBuilder.Entity<Category>().ToTable("categories");
      // modelBuilder.Entity<Category>().Property(m => m.Id).HasColumnName("categoryid");
      // modelBuilder.Entity<Category>().Property(m => m.Name).HasColumnName("categoryname");

      // modelBuilder.Entity<Product>().ToTable("products");
      // modelBuilder.Entity<Product>().Property(m => m.Id).HasColumnName("productid");
      // modelBuilder.Entity<Product>().Property(m => m.Name).HasColumnName("productname");
      // modelBuilder.Entity<Product>().Property(m => m.CategoryId).HasColumnName("categoryid");
      // modelBuilder.Entity<Product>().Property(m => m.QuantityPerUnit).HasColumnName("quantityperunit");
      // modelBuilder.Entity<Product>().Property(m => m.UnitPrice).HasColumnName("unitprice");
      // modelBuilder.Entity<Product>().Property(m => m.UnitsInStock).HasColumnName("unitsinstock");

      // modelBuilder.Entity<Order>().ToTable("orders");
      // modelBuilder.Entity<Order>().Property(m => m.Id).HasColumnName("orderid");
      // modelBuilder.Entity<Order>().Property(m => m.Date).HasColumnName("orderdate");
      // modelBuilder.Entity<Order>().Property(m => m.Required).HasColumnName("requireddate");
      // modelBuilder.Entity<Order>().Property(m => m.ShipName).HasColumnName("shipname");
      // modelBuilder.Entity<Order>().Property(m => m.ShipCity).HasColumnName("shipcity");

      // modelBuilder.Entity<OrderDetails>().ToTable("orderdetails");
      // modelBuilder.Entity<OrderDetails>().Property(m => m.OrderId).HasColumnName("orderid");
      // modelBuilder.Entity<OrderDetails>().Property(m => m.ProductId).HasColumnName("productid");
      // modelBuilder.Entity<OrderDetails>().Property(m => m.UnitPrice).HasColumnName("unitprice");
      // modelBuilder.Entity<OrderDetails>().Property(m => m.Quantity).HasColumnName("quantity");
      // modelBuilder.Entity<OrderDetails>().Property(m => m.Discount).HasColumnName("discount");

    }
  }

  static class ModelBuilderExtensions
  {
    public static void CreateMap(
        this ModelBuilder modelBuilder,
        params string[] names)
    {
      foreach (var entityType in modelBuilder.Model.GetEntityTypes())
      {
        var dict = new List<string>(names);
        entityType.SetTableName(entityType.GetTableName().ToLower());
        foreach (var property in entityType.GetProperties())
        {
          var propertyName = property.Name.ToLower();
          var entityName = "";

          if (dict.Contains(property.Name))
          {
            entityName = entityType.ClrType.Name.ToLower();
          }


          property.SetColumnName(entityName + propertyName);
        }

      }
    }
  }
}
