using System;
using System.Linq;
using DatabaseService;
using Microsoft.EntityFrameworkCore;

namespace ERExample
{
  class Program
  {
    static void Main(string[] args)
    {
      using var db = new NorthwindContext();

      // var nextId = db.Categories.Max(x => x.Id) + 1;
      //   var cat = new Category { Id = nextId, Name = "Testing", Description = "bla" };
 
      // var cat = db.Categories.Find(9);
    //   db.Remove(cat); 
      // db.SaveChanges();
 
      foreach (var category in db.Categories)
      {
        Console.WriteLine($"{category.Id}, {category.Name}");
      }

    }
  }
}
