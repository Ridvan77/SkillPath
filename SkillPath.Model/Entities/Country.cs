namespace SkillPath.Model.Entities
{
    public class Country
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;

        // Navigation properties
        public virtual ICollection<City> Cities { get; set; } = new List<City>();
    }
}
