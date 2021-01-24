using System;
using System.Collections.Generic;

namespace DatabaseService
{
  public interface IDataService
  {
    Category CreateCategory(Category category);
    // Category CreateCategory(Category category);
    bool DeleteCategory(int id);
    IList<Category> GetCategories(PagingAttributes pagingAttributes);
    // IList<Category> GetCategories();
    int NumberOfCategories();
    Category GetCategory(int id);
    Order GetOrder(int id);
    List<OrderDetails> GetOrderDetailsByOrderId(int id);
    List<OrderDetails> GetOrderDetailsByProductId(int id);
    List<Order> GetOrders();
    Product GetProduct(int id);
    List<Product> GetProductByCategory(int id);
    List<Product> GetProductByName(string name);
    bool UpdateCategory(int id, string name, string description);
    bool PutCategory(int id, string name, string description);
  }
  // public interface IDataService
  // {
  // void CreateCategory(Category category);
  // IList<Category> GetCategories();
  // Category GetCategory(int categoryId);
  // bool DeleteCategory(int categoryId);
  // }
}