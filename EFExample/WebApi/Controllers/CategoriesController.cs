using AutoMapper;
using DatabaseService;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WebApi.Models;

namespace WebApi.Controllers
{
  [ApiController]
  [Route("api/categories")]
  public class CategoriesController : ControllerBase
  {
    private IDataService _dataService;
    private IMapper _mapper;

    public CategoriesController(IDataService dataService, IMapper mapper)
    {
      _dataService = dataService;
      _mapper = mapper;
    }

    [HttpGet(Name = nameof(GetCategories))]
    public ActionResult GetCategories([FromQuery] PagingAttributes pagingAttributes)
    {
      var categories = _dataService.GetCategories(pagingAttributes);
      var result = CreateResult(categories, pagingAttributes);
      return Ok(result);
    }

    [HttpGet("{categoryId}", Name = nameof(GetCategory))]
    public ActionResult<Category> GetCategory(int categoryId)
    {
      var category = _dataService.GetCategory(categoryId);

      if (category == null) return NotFound();

      return Ok(CreateCategoryDto(category));
    }

    [HttpPost]
    public ActionResult CreateCategory(CategoryForCreation categoryDto)
    {
      // var cat = _dataService.CreateCategory(category.Name, category.Description);
      var category = _mapper.Map<Category>(categoryDto);
      _dataService.CreateCategory(category);
      return CreatedAtRoute(
          nameof(GetCategory),
          new { categoryId = category.Id },
          CreateCategoryDto(category));
    }

    [HttpPut("{categoryId}")]
    public ActionResult PutCategory([FromBody] Category category, int categoryId)
    {
      var cat = _dataService.PutCategory(categoryId, category.Name, category.Description);
      if (cat == false)
      {
        return NotFound();
      }

      return Ok(cat);
    }

    [HttpDelete("{categoryId}")]
    public ActionResult<Category> DeleteCategory(int categoryId)
    {
      // var category = _dataService.DeleteCategory(categoryId);

      if (_dataService.DeleteCategory(categoryId) == false)
      {
        return NotFound();
      }

      return Ok();
    }

    ///////////////////
    //
    // Helpers
    //
    //////////////////////

    private CategoryDto CreateCategoryDto(Category category)
    {
      var dto = _mapper.Map<CategoryDto>(category);
      dto.Link = Url.Link(
              nameof(GetCategory),
              new { categoryId = category.Id });
      return dto;
    }

    private object CreateResult(IEnumerable<Category> categories, PagingAttributes attr)
    {
      var totalItems = _dataService.NumberOfCategories();
      var numberOfPages = Math.Ceiling((double)totalItems / attr.PageSize);

      var prev = attr.Page > 0
          ? CreatePagingLink(attr.Page - 1, attr.PageSize)
          : null;
      var next = attr.Page < numberOfPages - 1
          ? CreatePagingLink(attr.Page + 1, attr.PageSize)
          : null;

      return new
      {
        totalItems,
        numberOfPages,
        prev,
        next,
        items = categories.Select(CreateCategoryDto)
      };
    }

    private string CreatePagingLink(int page, int pageSize)
    {
      return Url.Link(nameof(GetCategories), new { page, pageSize });
    }
  }
}
