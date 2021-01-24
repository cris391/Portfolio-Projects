using System.ComponentModel.DataAnnotations;

namespace WebApi.Models
{
  public class CategoryForCreation
  {
    [Required]
    [MaxLength(15)]
    public string Name { get; set; }
    [MaxLength(300)]
    public string Description { get; set; }
  }
}