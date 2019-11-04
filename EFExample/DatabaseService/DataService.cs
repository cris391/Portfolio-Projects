using System;
using System.Collections.Generic;
using System.Linq;
using DatabaseService;
using Microsoft.EntityFrameworkCore;

namespace DatabaseService
{

  public class DataService : IDataService
  {
    // public IList<Category> GetCategories()
    public IList<Category> GetCategories(PagingAttributes pagingAttributes)
    {
      using var db = new NorthwindContext();
      return db.Categories
                .Skip(pagingAttributes.Page * pagingAttributes.PageSize)
                .Take(pagingAttributes.PageSize)
                .ToList();
    }
    public int NumberOfCategories()
    {
      using var db = new NorthwindContext();
      return db.Categories.Count();
    }


    public Category GetCategory(int id)
    {
      using var db = new NorthwindContext();
      return db.Categories.Find(id);
    }

    public Category CreateCategory(Category category)
    {
      using var DB = new NorthwindContext();
      var nextId = DB.Categories.Max(x => x.Id) + 1;
      var newCategory = new Category
      {
        Id = nextId,
        Name = category.Name,
        Description = category.Description
      };
      DB.Categories.Add(newCategory);
      DB.SaveChanges();
      return GetCategory(newCategory.Id);
    }

    public bool DeleteCategory(int id)
    {
      using var db = new NorthwindContext();
      var category = GetCategory(id);
      try
      {
        db.Categories.Remove(category);
        db.SaveChanges();
      }
      catch (System.Exception e)
      {
        return false;
      }
      return true;
    }

    public bool UpdateCategory(int id, string name, string description)
    {
      try
      {
        using var db = new NorthwindContext();
        var category = GetCategory(id);
        category.Name = name;
        category.Description = description;
        db.Update(category);
        db.SaveChanges();
      }
      catch (System.Exception e)
      {
        return false;
      }
      return true;
    }
    public bool PutCategory(int id, string name, string description)
    {
      try
      {
        using var db = new NorthwindContext();
        var category = GetCategory(id);
        category.Name = name;
        category.Description = description;
        db.Update(category);
        db.SaveChanges();
      }
      catch (System.Exception e)
      {
        return false;
      }
      return true;
    }

    public Product GetProduct(int id)
    {
      using var db = new NorthwindContext();
      return db.Products
        .Where(p => p.Id == id)
        .Include(p => p.Category)
        .FirstOrDefault();
    }

    public List<Product> GetProductByCategory(int id)
    {
      using var db = new NorthwindContext();
      return db.Products
        .Where(p => p.CategoryId == id)
        .Include(p => p.Category)
        .ToList();
    }

    public List<Product> GetProductByName(string name)
    {
      using var db = new NorthwindContext();
      return db.Products
        .Where(p => p.Name.Contains(name))
        .ToList();
    }

    public Order GetOrder(int id)
    {
      using var db = new NorthwindContext();
      return db.Orders
        .Where(p => p.Id == id)
        .Include(p => p.OrderDetails)
        .ThenInclude(p => p.Product)
        .ThenInclude(p => p.Category)
        .FirstOrDefault();
    }

    public List<Order> GetOrders()
    {
      using var db = new NorthwindContext();
      return db.Orders.ToList();
    }

    public List<OrderDetails> GetOrderDetailsByOrderId(int id)
    {
      using var db = new NorthwindContext();
      return db.OrderDetails
      .Where(m => m.OrderId == id)
      .Include(m => m.Product)
      .ToList();
    }

    public List<OrderDetails> GetOrderDetailsByProductId(int id)
    {
      using var db = new NorthwindContext();
      return db.OrderDetails
      .Where(m => m.ProductId == id)
      .Include(m => m.Order)
      .ToList();
    }
  }
}