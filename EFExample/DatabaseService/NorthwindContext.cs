using System;
using Microsoft.EntityFrameworkCore;
using DatabaseService;

namespace DatabaseService
{
  public class NorthwindContext : DbContext
  {
    public DbSet<Category> Categories { get; set; }
    public DbSet<Product> Products { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
      optionsBuilder.UseNpgsql(connectionString: "host=localhost;db=northwind;uid=postgres;pwd=root");
    }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
      modelBuilder.Entity<Category>().ToTable("categories");
      modelBuilder.Entity<Category>().Property(m => m.Id).HasColumnName("categoryid");
      modelBuilder.Entity<Category>().Property(m => m.Name).HasColumnName("categoryname");

      modelBuilder.Entity<Product>().ToTable("products");
      modelBuilder.Entity<Product>().Property(m => m.Id).HasColumnName("productid");
      modelBuilder.Entity<Product>().Property(m => m.Name).HasColumnName("productname");
      modelBuilder.Entity<Product>().Property(m => m.CategoryId).HasColumnName("categoryid");

    }
  }
}
