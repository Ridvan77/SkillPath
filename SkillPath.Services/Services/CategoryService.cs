using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Services.DTOs.Category;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class CategoryService : ICategoryService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<CategoryService> _logger;

        public CategoryService(ApplicationDbContext context, ILogger<CategoryService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<CategoryDto>> GetAllAsync()
        {
            return await _context.Categories
                .Select(c => new CategoryDto(
                    c.Id,
                    c.Name,
                    c.Description,
                    c.Courses.Count(co => co.IsActive)
                ))
                .ToListAsync();
        }

        public async Task<CategoryDto> GetByIdAsync(int id)
        {
            var category = await _context.Categories
                .Where(c => c.Id == id)
                .Select(c => new CategoryDto(
                    c.Id,
                    c.Name,
                    c.Description,
                    c.Courses.Count(co => co.IsActive)
                ))
                .FirstOrDefaultAsync();

            if (category == null)
                throw new NotFoundException($"Category with ID {id} not found.");

            return category;
        }

        public async Task<CategoryDto> CreateAsync(CategoryCreateRequest request)
        {
            var category = new Category
            {
                Name = request.Name,
                Description = request.Description
            };

            _context.Categories.Add(category);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Category '{Name}' created with ID {Id}", category.Name, category.Id);

            return new CategoryDto(category.Id, category.Name, category.Description, 0);
        }

        public async Task<CategoryDto> UpdateAsync(int id, CategoryCreateRequest request)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
                throw new NotFoundException($"Category with ID {id} not found.");

            category.Name = request.Name;
            category.Description = request.Description;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Category '{Name}' (ID {Id}) updated", category.Name, category.Id);

            var coursesCount = await _context.Courses.CountAsync(c => c.CategoryId == id && c.IsActive);
            return new CategoryDto(category.Id, category.Name, category.Description, coursesCount);
        }

        public async Task DeleteAsync(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
                throw new NotFoundException($"Category with ID {id} not found.");

            // Reassign courses to "Ostalo" category if this category has courses
            var coursesInCategory = await _context.Courses.Where(c => c.CategoryId == id).ToListAsync();
            if (coursesInCategory.Any())
            {
                // Find or create "Ostalo" category
                var ostaloCategory = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Ostalo");
                if (ostaloCategory == null)
                {
                    ostaloCategory = new Category
                    {
                        Name = "Ostalo",
                        Description = "Nekategorizirani kursevi"
                    };
                    _context.Categories.Add(ostaloCategory);
                    await _context.SaveChangesAsync();
                }

                foreach (var course in coursesInCategory)
                {
                    course.CategoryId = ostaloCategory.Id;
                }
                await _context.SaveChangesAsync();

                _logger.LogInformation("{Count} courses reassigned from '{Name}' to 'Ostalo'", coursesInCategory.Count, category.Name);
            }

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Category '{Name}' (ID {Id}) deleted", category.Name, category.Id);
        }
    }
}
