using AutoMapper;
using DatabaseService;
using WebApi.Models;

namespace WebApi.Profiles
{
  public class CategoryProfile : Profile
  {
    public CategoryProfile()
    {
      CreateMap<Category, CategoryDto>();
      CreateMap<CategoryForCreation, Category>();
    }
  }
}