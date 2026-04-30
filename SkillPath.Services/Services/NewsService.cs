using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SkillPath.Model;
using SkillPath.Model.Entities;
using SkillPath.Services.DTOs;
using SkillPath.Services.DTOs.News;
using SkillPath.Services.Exceptions;
using SkillPath.Services.Interfaces;

namespace SkillPath.Services.Services
{
    public class NewsService : INewsService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<NewsService> _logger;

        public NewsService(ApplicationDbContext context, ILogger<NewsService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<PagedResult<NewsDto>> GetAllAsync(int page, int pageSize)
        {
            var totalCount = await _context.News.CountAsync();

            var items = await _context.News
                .Include(n => n.CreatedBy)
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new NewsDto(
                    n.Id,
                    n.Title,
                    n.Content,
                    n.ImageUrl,
                    n.CreatedAt,
                    n.CreatedBy.FirstName + " " + n.CreatedBy.LastName
                ))
                .ToListAsync();

            return new PagedResult<NewsDto>(items, page, pageSize, totalCount);
        }

        public async Task<NewsDto> GetByIdAsync(Guid id)
        {
            var news = await _context.News
                .Include(n => n.CreatedBy)
                .Where(n => n.Id == id)
                .Select(n => new NewsDto(
                    n.Id,
                    n.Title,
                    n.Content,
                    n.ImageUrl,
                    n.CreatedAt,
                    n.CreatedBy.FirstName + " " + n.CreatedBy.LastName
                ))
                .FirstOrDefaultAsync();

            if (news == null)
                throw new NotFoundException($"News with ID {id} not found.");

            return news;
        }

        public async Task<NewsDto> CreateAsync(string userId, NewsCreateRequest request)
        {
            var news = new News
            {
                Id = Guid.NewGuid(),
                Title = request.Title,
                Content = request.Content,
                ImageUrl = request.ImageUrl,
                CreatedAt = DateTime.UtcNow,
                CreatedById = userId
            };

            _context.News.Add(news);
            await _context.SaveChangesAsync();

            var user = await _context.Users.FindAsync(userId);

            _logger.LogInformation("News '{Title}' created by user {UserId}", news.Title, userId);

            return new NewsDto(
                news.Id,
                news.Title,
                news.Content,
                news.ImageUrl,
                news.CreatedAt,
                user != null ? $"{user.FirstName} {user.LastName}" : string.Empty
            );
        }

        public async Task<NewsDto> UpdateAsync(Guid id, NewsCreateRequest request)
        {
            var news = await _context.News
                .Include(n => n.CreatedBy)
                .FirstOrDefaultAsync(n => n.Id == id);

            if (news == null)
                throw new NotFoundException($"News with ID {id} not found.");

            news.Title = request.Title;
            news.Content = request.Content;
            news.ImageUrl = request.ImageUrl;

            await _context.SaveChangesAsync();

            _logger.LogInformation("News '{Title}' (ID {Id}) updated", news.Title, news.Id);

            return new NewsDto(
                news.Id,
                news.Title,
                news.Content,
                news.ImageUrl,
                news.CreatedAt,
                $"{news.CreatedBy.FirstName} {news.CreatedBy.LastName}"
            );
        }

        public async Task DeleteAsync(Guid id)
        {
            var news = await _context.News.FindAsync(id);
            if (news == null)
                throw new NotFoundException($"News with ID {id} not found.");

            _context.News.Remove(news);
            await _context.SaveChangesAsync();

            _logger.LogInformation("News '{Title}' (ID {Id}) deleted", news.Title, news.Id);
        }
    }
}
