using SkillPath.Services.DTOs;

namespace SkillPath.Services.Interfaces;

public interface IRabbitMQPublisherService
{
    Task PublishEmailAsync(EmailMessage message);
}
