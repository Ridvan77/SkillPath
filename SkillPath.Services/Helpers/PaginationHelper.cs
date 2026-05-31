namespace SkillPath.Services.Helpers
{
    public static class PaginationHelper
    {
        public static (int page, int pageSize) Normalize(int page, int pageSize, int maxPageSize = 100)
        {
            page = Math.Max(1, page);
            pageSize = Math.Clamp(pageSize, 1, maxPageSize);
            return (page, pageSize);
        }
    }
}
