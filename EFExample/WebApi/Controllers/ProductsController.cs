using DatabaseService;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WebApi.Controllers
{
  [ApiController]
  [Route("api/products")]
  public class ProductsController : ControllerBase
  {
    IDataService _dataService;
    public ProductsController(IDataService dataService)
    {
      _dataService = dataService;
    }

    [HttpGet]
    public IList<Category> GetCategories()
    {
      return _dataService.GetCategories();
    }

    [HttpGet("{productId}")]
    public ActionResult<Category> GetProduct(int productId)
    {
      var product = _dataService.GetProduct(productId);

      if (product == null) return NotFound();

      return Ok(product);
    }

    [HttpGet("category/{categoryId}")]
    public ActionResult<Category> GetProductByCategory(int categoryId)
    {
      var product = _dataService.GetProductByCategory(categoryId);
      if (product.Count == 0) return NotFound(product);

      return Ok(product);
    }

    [HttpGet("name/{name}")]
    public ActionResult<Category> GetProductByName(string name)
    {
      var product = _dataService.GetProductByName(name);
      if (product.Count == 0) return NotFound(product);

      return Ok(product);
    }

    // [HttpPost]
    // public ActionResult CreateCategory([FromBody] Category category)
    // {
    //   var cat = _dataService.CreateCategory(category.Name, category.Description);

    //   return Created("post", cat);
    // }

    // [HttpPut("{categoryId}")]
    // public ActionResult PutCategory([FromBody] Category category, int categoryId)
    // {
    //   var cat = _dataService.PutCategory(categoryId, category.Name, category.Description);
    //   if (cat == false)
    //   {
    //     return NotFound();
    //   }

    //   return Ok(cat);
    // }

    // [HttpDelete("{categoryId}")]
    // public ActionResult<Category> DeleteCategory(int categoryId)
    // {
    //   // var category = _dataService.DeleteCategory(categoryId);

    //   if (_dataService.DeleteCategory(categoryId) == false)
    //   {
    //     return NotFound();
    //   }

    //   return Ok();
    // }
  }
}
