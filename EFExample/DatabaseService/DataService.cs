using System.Collections.Generic;
using System.Linq;
using DatabaseService;

namespace DatabaseService
{

  public class DataService
  {
    public List<Category> GetCategories()
    {
      using var db = new NorthwindContext();
      return db.Categories.ToList();
    }
  }
}